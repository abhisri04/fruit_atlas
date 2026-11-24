import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/my_garden.dart';
import 'progress_service.dart';

/// Stores My Garden on the device (private by default) and rewards growing
/// without ever counting what was missed.
abstract final class MyGardenService {
  static const _key = 'my_garden_v1';
  static const _photoPrefix = 'my_garden_photo_';
  static const plantProgressKey = 'completed_garden_plant_ids';

  /// Bumped on every change so open screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static final Map<String, Uint8List> _photoCache = {};
  static int _counter = 0;

  static String _newId(String prefix, DateTime at) =>
      '${prefix}_${at.microsecondsSinceEpoch}_${_counter++}';

  static Future<MyGarden> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const MyGarden();
    try {
      return MyGarden.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const MyGarden();
    }
  }

  static Future<void> _save(MyGarden garden) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(garden.toJson()))) {
      throw StateError('Could not save your garden');
    }
    changes.value++;
  }

  /// Adds a Plants to Grow plant. It also counts as grown in the catalogue.
  static Future<GardenPlant> addCatalogue(Item item, {DateTime? now}) => _add(
    catalogueId: item.id,
    name: item.name,
    type: item.filterGroup,
    now: now,
  );

  /// Adds a plant by name, for anything not in the catalogue.
  static Future<GardenPlant> addCustom(
    String name, {
    String? type,
    DateTime? now,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    return _add(name: trimmed, type: type, now: now);
  }

  static Future<GardenPlant> _add({
    String? catalogueId,
    required String name,
    String? type,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final plant = GardenPlant(
      id: _newId('gp', at),
      catalogueId: catalogueId,
      name: name,
      type: type,
      addedAt: at,
    );
    final current = await load();
    final updated = MyGarden(
      plants: {...current.plants, plant.id: plant},
      logs: [
        ...current.logs,
        GardenLog(
          id: _newId('gl', at),
          plantId: plant.id,
          moment: GardenMoment.added,
          at: at,
        ),
      ],
    );
    await _save(updated);
    if (catalogueId != null) await _markGrown(catalogueId);
    await ProgressService.recordGardenCare(name, now: at);
    await _checkMilestones(updated);
    return plant;
  }

  /// One tap: logs [moment] for a plant. Sown and the firsts happen once per
  /// plant, tending once a day; harvests can repeat. Returns the new log, or
  /// null if it was already logged.
  static Future<GardenLog?> log(
    String plantId,
    GardenMoment moment, {
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final current = await load();
    final plant = current.plants[plantId];
    if (plant == null) throw StateError('Not in your garden: $plantId');
    final once = switch (moment) {
      GardenMoment.added ||
      GardenMoment.sown ||
      GardenMoment.sprouted ||
      GardenMoment.flowered => current.has(plantId, moment),
      GardenMoment.tended => current.tendedOn(plantId, at),
      GardenMoment.harvested => false,
    };
    if (once) return null;
    final entry = GardenLog(
      id: _newId('gl', at),
      plantId: plantId,
      moment: moment,
      at: at,
    );
    final updated = MyGarden(
      plants: current.plants,
      logs: [...current.logs, entry],
    );
    await _save(updated);
    await ProgressService.recordGardenCare(plant.name, now: at);
    await _checkMilestones(updated);
    return entry;
  }

  /// Attaches an optional photo to a log. Photos stay on this device.
  static Future<void> attachPhoto(String logId, Uint8List bytes) async {
    final current = await load();
    final index = current.logs.indexWhere((l) => l.id == logId);
    if (index < 0) throw StateError('No such log: $logId');
    final photoId = _newId('photo', DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('$_photoPrefix$photoId', base64Encode(bytes))) {
      throw StateError('Could not save the photo');
    }
    _photoCache[photoId] = bytes;
    final old = current.logs[index].photoId;
    final logs = [...current.logs]
      ..[index] = current.logs[index].withPhoto(photoId);
    await _save(MyGarden(plants: current.plants, logs: logs));
    if (old != null) await _deletePhoto(old);
  }

  static Future<Uint8List?> photo(String photoId) async {
    final cached = _photoCache[photoId];
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_photoPrefix$photoId');
    if (raw == null) return null;
    try {
      return _photoCache[photoId] = base64Decode(raw);
    } on FormatException {
      return null;
    }
  }

  static Future<void> _deletePhoto(String photoId) async {
    _photoCache.remove(photoId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_photoPrefix$photoId');
  }

  /// "Let it go": moves a plant to Lessons learned, with what they learned.
  /// Its record and photos stay.
  static Future<void> letGo(
    String plantId, {
    String? lesson,
    DateTime? now,
  }) async {
    final current = await load();
    final plant = current.plants[plantId];
    if (plant == null || !plant.growing) return;
    await _save(
      MyGarden(
        plants: {
          ...current.plants,
          plantId: plant.letGo((now ?? DateTime.now()).toLocal(), lesson),
        },
        logs: current.logs,
      ),
    );
  }

  /// Starts the same plant again, keeping the old one in Lessons learned.
  static Future<GardenPlant> growAgain(String plantId, {DateTime? now}) async {
    final plant = (await load()).plants[plantId];
    if (plant == null) throw StateError('Not in your garden: $plantId');
    return _add(
      catalogueId: plant.catalogueId,
      name: plant.name,
      type: plant.type,
      now: now,
    );
  }

  /// Removes a plant and its record entirely (for mistakes, not losses).
  static Future<void> remove(String plantId) async {
    final current = await load();
    final photos = [
      for (final l in current.logs)
        if (l.plantId == plantId && l.photoId != null) l.photoId!,
    ];
    await _save(
      MyGarden(
        plants: {...current.plants}..remove(plantId),
        logs: [
          for (final l in current.logs)
            if (l.plantId != plantId) l,
        ],
      ),
    );
    for (final id in photos) {
      await _deletePhoto(id);
    }
  }

  static Future<void> _markGrown(String catalogueId) async {
    final ids = await ProgressService.getChallengeItemIds(plantProgressKey);
    if (ids.contains(catalogueId)) return;
    await ProgressService.setChallengeItemIds(plantProgressKey, {
      ...ids,
      catalogueId,
    });
  }

  static const _levelNames = ['Tried', 'Learning', 'Practising', 'Confident'];

  static Future<void> _checkMilestones(MyGarden garden) async {
    if (garden.plants.isNotEmpty) {
      await ProgressService.recordCollectionMilestone(
        'garden_first_plant',
        'Your garden has begun',
        'The first plant in My Garden.',
      );
    }
    for (final (moment, title) in const [
      (GardenMoment.sprouted, 'First sprout!'),
      (GardenMoment.flowered, 'First flower!'),
      (GardenMoment.harvested, 'First harvest!'),
    ]) {
      final first = garden.logs.where((l) => l.moment == moment).firstOrNull;
      if (first == null) continue;
      final plant = garden.plants[first.plantId];
      await ProgressService.recordCollectionMilestone(
        'garden_first_${moment.name}',
        title,
        plant == null ? 'A first for your garden.' : 'From your ${plant.name}.',
      );
    }
    if (garden.growing.length >= 5) {
      await ProgressService.recordCollectionMilestone(
        'garden_five_growing',
        'Five plants growing',
        'Your garden is filling up.',
      );
    }
    final level = garden.gardenerLevel();
    for (var rung = 2; rung <= level; rung++) {
      await ProgressService.recordCollectionMilestone(
        'garden_level_$rung',
        '${_levelNames[rung - 1]} gardener!',
        'You climbed your gardener path.',
      );
    }
  }
}
