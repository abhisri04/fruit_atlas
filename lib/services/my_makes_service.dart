import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';

/// A step of progress on a project: an optional photo, note and time spent.
class MakeUpdate {
  final String id;
  final DateTime at;
  final String? note;
  final int? minutes;
  final String? photoId;

  const MakeUpdate({
    required this.id,
    required this.at,
    this.note,
    this.minutes,
    this.photoId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
    if (minutes != null) 'minutes': minutes,
    if (photoId != null) 'photo_id': photoId,
  };

  factory MakeUpdate.fromJson(Map<String, dynamic> json) => MakeUpdate(
    id: json['id'] as String,
    at: DateTime.parse(json['at'] as String).toLocal(),
    note: json['note'] as String?,
    minutes: (json['minutes'] as num?)?.toInt(),
    photoId: json['photo_id'] as String?,
  );
}

/// A project someone is making: started, worked on, finished.
class MyMake {
  /// Catalogue id (make_…) or custom_….
  final String id;
  final String name;
  final String? craft;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<MakeUpdate> updates;

  const MyMake({
    required this.id,
    required this.name,
    required this.startedAt,
    this.craft,
    this.finishedAt,
    this.updates = const [],
  });

  bool get finished => finishedAt != null;

  int get minutes => updates.fold(0, (sum, u) => sum + (u.minutes ?? 0));

  /// The newest photo, for the project's cover.
  String? get coverPhoto => updates.reversed
      .where((u) => u.photoId != null)
      .map((u) => u.photoId)
      .firstOrNull;

  MyMake copyWith({DateTime? finishedAt, List<MakeUpdate>? updates}) => MyMake(
    id: id,
    name: name,
    craft: craft,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    updates: updates ?? this.updates,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (craft != null) 'craft': craft,
    'started_at': startedAt.toUtc().toIso8601String(),
    if (finishedAt != null)
      'finished_at': finishedAt!.toUtc().toIso8601String(),
    'updates': [for (final u in updates) u.toJson()],
  };

  factory MyMake.fromJson(Map<String, dynamic> json) => MyMake(
    id: json['id'] as String,
    name: json['name'] as String,
    craft: json['craft'] as String?,
    startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    finishedAt: json['finished_at'] == null
        ? null
        : DateTime.parse(json['finished_at'] as String).toLocal(),
    updates: [
      for (final u in json['updates'] as List<dynamic>? ?? [])
        MakeUpdate.fromJson(u as Map<String, dynamic>),
    ],
  );
}

/// Stores projects (private, on the device) and rewards finishing them.
abstract final class MyMakesService {
  static const _key = 'my_makes_v1';
  static const _photoPrefix = 'make_photo_';
  static const progressKey = 'completed_make_ids';

  static final ValueNotifier<int> changes = ValueNotifier(0);
  static final Map<String, Uint8List> _photoCache = {};
  static int _counter = 0;

  static Future<Map<String, MyMake>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return {
        for (final m in jsonDecode(raw) as List<dynamic>)
          (m as Map<String, dynamic>)['id'] as String: MyMake.fromJson(m),
      };
    } on FormatException {
      return {};
    }
  }

  static Future<void> _save(Map<String, MyMake> all) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key,
      jsonEncode([for (final m in all.values) m.toJson()]),
    )) {
      throw StateError('Could not save your project');
    }
    changes.value++;
  }

  /// Starts a project once; returns it.
  static Future<MyMake> start(
    String id,
    String name, {
    String? craft,
    DateTime? now,
  }) async {
    final all = await load();
    final existing = all[id];
    if (existing != null) return existing;
    final make = MyMake(
      id: id,
      name: name,
      craft: craft,
      startedAt: (now ?? DateTime.now()).toLocal(),
    );
    await _save({...all, id: make});
    await ProgressService.recordActivity(make.startedAt, 'make:$id');
    return make;
  }

  /// Your own project, not from the catalogue.
  static Future<MyMake> startCustom(String name, {DateTime? now}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    final at = now ?? DateTime.now();
    return start(
      'custom_${at.microsecondsSinceEpoch}_${_counter++}',
      trimmed,
      now: at,
    );
  }

  static Future<void> addUpdate(
    String id, {
    String? note,
    int? minutes,
    Uint8List? photo,
    DateTime? now,
  }) async {
    final all = await load();
    final make = all[id];
    if (make == null) throw StateError('Not started: $id');
    final at = (now ?? DateTime.now()).toLocal();
    String? photoId;
    if (photo != null) {
      photoId = 'p_${at.microsecondsSinceEpoch}_${_counter++}';
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        '$_photoPrefix$photoId',
        base64Encode(photo),
      )) {
        throw StateError('Could not save the photo');
      }
      _photoCache[photoId] = photo;
    }
    final update = MakeUpdate(
      id: 'u_${at.microsecondsSinceEpoch}_${_counter++}',
      at: at,
      note: note?.trim(),
      minutes: minutes,
      photoId: photoId,
    );
    await _save({
      ...all,
      id: make.copyWith(updates: [...make.updates, update]),
    });
    await ProgressService.recordActivity(at, 'make:$id');
  }

  /// Finished: it joins your gallery, counts as made, and is celebrated.
  static Future<void> finish(String id, {DateTime? now}) async {
    final all = await load();
    final make = all[id];
    if (make == null || make.finished) return;
    final at = (now ?? DateTime.now()).toLocal();
    await _save({...all, id: make.copyWith(finishedAt: at)});
    if (!id.startsWith('custom_')) {
      final ids = await ProgressService.getChallengeItemIds(progressKey);
      if (!ids.contains(id)) {
        await ProgressService.setChallengeItemIds(progressKey, {...ids, id});
      }
    }
    await ProgressService.recordCollectionMilestone(
      'made_$id',
      'You made it!',
      '${make.name} is finished.',
    );
  }

  static Future<void> remove(String id) async {
    final all = await load();
    final make = all[id];
    if (make == null) return;
    await _save({...all}..remove(id));
    for (final u in make.updates) {
      if (u.photoId case final photo?) {
        _photoCache.remove(photo);
        await (await SharedPreferences.getInstance()).remove(
          '$_photoPrefix$photo',
        );
      }
    }
  }

  static Future<Uint8List?> photo(String photoId) async {
    final cached = _photoCache[photoId];
    if (cached != null) return cached;
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_photoPrefix$photoId',
    );
    if (raw == null) return null;
    try {
      return _photoCache[photoId] = base64Decode(raw);
    } on FormatException {
      return null;
    }
  }
}
