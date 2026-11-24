import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/scent_collection.dart';
import 'progress_service.dart';

/// The scent catalogue My Collection adds from: famous perfumes and attars,
/// plus the family names.
class ScentCatalogue {
  final List<Item> perfumes;
  final List<Item> attars;
  final List<String> families;

  const ScentCatalogue(this.perfumes, this.attars, this.families);

  static Future<ScentCatalogue>? _cache;

  static Future<ScentCatalogue> load({AssetBundle? bundle}) =>
      _cache ??= _load(bundle ?? rootBundle).catchError((Object error) {
        _cache = null;
        throw error;
      });

  static Future<ScentCatalogue> _load(AssetBundle bundle) async {
    Future<List<Item>> items(String file) async {
      final json = jsonDecode(
        await bundle.loadString('assets/data/$file'),
      ) as Map<String, dynamic>;
      return (json['items'] as List<dynamic>)
          .map((raw) => Item.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false);
    }

    final families = await items('scent_families.json');
    return ScentCatalogue(
      await items('famous_perfumes.json'),
      await items('indian_attars.json'),
      [for (final f in families) f.category ?? f.name],
    );
  }

  /// Every catalogue perfume and attar.
  List<Item> get all => [...perfumes, ...attars];

  /// The family a catalogue item belongs to (attars sit in Oud & Attar).
  static String? familyOf(Item item) => item.id.startsWith('attar_')
      ? 'Oud & Attar'
      : item.metadata['Family'] ?? item.filterGroup;
}

/// Stores My Collection (shelves and wear diary) on the device and rewards
/// collecting milestones.
abstract final class ScentCollectionService {
  static const _key = 'scent_collection_v1';
  static const perfumeProgressKey = 'completed_perfume_ids';
  static const attarProgressKey = 'completed_attar_ids';

  /// Bumped on every change so open screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static Future<ScentCollection> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const ScentCollection();
    return ScentCollection.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> _save(ScentCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(collection.toJson()));
    changes.value++;
  }

  /// Puts a catalogue perfume or attar on a shelf (or moves it there).
  static Future<ScentCollection> addItem(
    Item item,
    ScentShelf shelf, {
    ScentFormat? format,
    DateTime? now,
  }) => add(
    ScentEntry(
      id: item.id,
      name: item.id.startsWith('attar_')
          ? '${item.category ?? item.name} attar'
          : item.name,
      maker: item.id.startsWith('attar_') ? null : item.category,
      family: ScentCatalogue.familyOf(item),
      shelf: shelf,
      format:
          format ??
          (item.id.startsWith('attar_')
              ? ScentFormat.attar
              : ScentFormat.bottle),
      addedAt: (now ?? DateTime.now()).toLocal(),
    ),
  );

  /// Adds or replaces [entry]. Owning or trying a catalogue perfume also
  /// marks it smelled.
  static Future<ScentCollection> add(ScentEntry entry) async {
    final current = await load();
    final previous = current.entries[entry.id];
    final updated = ScentCollection(
      entries: {
        ...current.entries,
        entry.id: previous == null
            ? entry
            : previous.copyWith(shelf: entry.shelf, format: entry.format),
      },
      wears: current.wears,
    );
    await _save(updated);
    if (entry.shelf != ScentShelf.wantToSmell) await _markSmelled(entry.id);
    await _checkMilestones(updated, DateTime.now());
    return updated;
  }

  static Future<ScentCollection> move(String id, ScentShelf shelf) async {
    final current = await load();
    final entry = current.entries[id];
    if (entry == null) return current;
    return add(entry.copyWith(shelf: shelf));
  }

  static Future<ScentCollection> remove(String id) async {
    final current = await load();
    final updated = ScentCollection(
      entries: {...current.entries}..remove(id),
      wears: [
        for (final w in current.wears)
          if (w.entryId != id) w,
      ],
    );
    await _save(updated);
    return updated;
  }

  /// Logs "wore it today".
  static Future<ScentCollection> logWear(
    String id, {
    String? occasion,
    String? note,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final current = await load();
    final entry = current.entries[id];
    if (entry == null) throw StateError('Not in collection: $id');
    final updated = ScentCollection(
      entries: entry.shelf == ScentShelf.own
          ? current.entries
          : {...current.entries, id: entry.copyWith(shelf: ScentShelf.own)},
      wears: [
        ...current.wears,
        ScentWear(entryId: id, at: at, occasion: occasion, note: note?.trim()),
      ],
    );
    await _save(updated);
    await ProgressService.recordScentWear(entry.name, now: at);
    await _checkMilestones(updated, at);
    return updated;
  }

  static Future<void> _markSmelled(String id) async {
    final key = id.startsWith('attar_')
        ? attarProgressKey
        : id.startsWith('perfume_')
        ? perfumeProgressKey
        : null;
    if (key == null) return;
    final ids = await ProgressService.getChallengeItemIds(key);
    if (ids.contains(id)) return;
    await ProgressService.setChallengeItemIds(key, {...ids, id});
  }

  static const _levelNames = ['Tried', 'Learning', 'Practising', 'Confident'];

  static Future<void> _checkMilestones(
    ScentCollection collection,
    DateTime now,
  ) async {
    if (collection.shelf(ScentShelf.own).isNotEmpty) {
      await ProgressService.recordCollectionMilestone(
        'first_own',
        'First on the shelf',
        'Your perfume collection has begun.',
      );
    }
    if (collection.distinctWornThisMonth(now) >= 10) {
      await ProgressService.recordCollectionMilestone(
        'ten_in_a_month_${now.year}_${now.month}',
        'Ten scents this month',
        'You wore 10 different perfumes this month.',
      );
    }
    if (collection.signatures().length == ScentSeason.values.length) {
      await ProgressService.recordCollectionMilestone(
        'all_seasons',
        'A scent for every season',
        'You have a signature for summer, monsoon and winter.',
      );
    }
    final level = collection.collectorLevel();
    for (var rung = 2; rung <= level; rung++) {
      await ProgressService.recordCollectionMilestone(
        'level_$rung',
        '${_levelNames[rung - 1]} collector!',
        'You climbed your collector path.',
      );
    }
  }
}
