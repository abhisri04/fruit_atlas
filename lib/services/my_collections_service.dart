import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';

/// One thing in someone's collection: a pair of sneakers, a coin, a stamp.
class CollectedThing {
  final String id;
  final String name;
  final String? note;
  final DateTime addedAt;
  final String? photoId;

  const CollectedThing({
    required this.id,
    required this.name,
    required this.addedAt,
    this.note,
    this.photoId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (note != null && note!.isNotEmpty) 'note': note,
    'added_at': addedAt.toUtc().toIso8601String(),
    if (photoId != null) 'photo_id': photoId,
  };

  factory CollectedThing.fromJson(Map<String, dynamic> json) => CollectedThing(
    id: json['id'] as String,
    name: json['name'] as String,
    note: json['note'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String).toLocal(),
    photoId: json['photo_id'] as String?,
  );
}

/// A collection someone started from "Start a Collection".
class MyCollection {
  /// The catalogue id, e.g. collect_sneakers.
  final String typeId;

  /// What's collected, e.g. "Sneakers".
  final String name;
  final DateTime startedAt;
  final List<CollectedThing> things;

  const MyCollection({
    required this.typeId,
    required this.name,
    required this.startedAt,
    this.things = const [],
  });

  Map<String, dynamic> toJson() => {
    'type_id': typeId,
    'name': name,
    'started_at': startedAt.toUtc().toIso8601String(),
    'things': [for (final t in things) t.toJson()],
  };

  factory MyCollection.fromJson(Map<String, dynamic> json) => MyCollection(
    typeId: json['type_id'] as String,
    name: json['name'] as String,
    startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    things: [
      for (final t in json['things'] as List<dynamic>? ?? [])
        CollectedThing.fromJson(t as Map<String, dynamic>),
    ],
  );
}

/// Stores the collections people start (private, on the device).
abstract final class MyCollectionsService {
  static const _key = 'my_collections_v1';
  static const _photoPrefix = 'collection_photo_';
  static const progressKey = 'completed_collection_type_ids';

  static final ValueNotifier<int> changes = ValueNotifier(0);
  static final Map<String, Uint8List> _photoCache = {};
  static int _counter = 0;

  static Future<Map<String, MyCollection>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return {
        for (final c in jsonDecode(raw) as List<dynamic>)
          (c as Map<String, dynamic>)['type_id'] as String:
              MyCollection.fromJson(c),
      };
    } on FormatException {
      return {};
    }
  }

  static Future<void> _save(Map<String, MyCollection> all) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key,
      jsonEncode([for (final c in all.values) c.toJson()]),
    )) {
      throw StateError('Could not save your collection');
    }
    changes.value++;
  }

  /// Starts a collection (once). It counts as started in the catalogue.
  static Future<MyCollection> start(
    String typeId,
    String name, {
    DateTime? now,
  }) async {
    final all = await load();
    final existing = all[typeId];
    if (existing != null) return existing;
    final created = MyCollection(
      typeId: typeId,
      name: name,
      startedAt: (now ?? DateTime.now()).toLocal(),
    );
    await _save({...all, typeId: created});
    final ids = await ProgressService.getChallengeItemIds(progressKey);
    if (!ids.contains(typeId)) {
      await ProgressService.setChallengeItemIds(progressKey, {...ids, typeId});
    }
    return created;
  }

  static Future<void> addThing(
    String typeId, {
    required String name,
    String? note,
    Uint8List? photo,
    DateTime? now,
  }) async {
    final all = await load();
    final collection = all[typeId];
    if (collection == null) throw StateError('Not started: $typeId');
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
    final thing = CollectedThing(
      id: 't_${at.microsecondsSinceEpoch}_${_counter++}',
      name: name.trim(),
      note: note?.trim(),
      addedAt: at,
      photoId: photoId,
    );
    await _save({
      ...all,
      typeId: MyCollection(
        typeId: typeId,
        name: collection.name,
        startedAt: collection.startedAt,
        things: [...collection.things, thing],
      ),
    });
    await ProgressService.recordActivity(at, 'collect:$typeId');
    if (collection.things.isEmpty) {
      await ProgressService.recordCollectionMilestone(
        'collect_first_$typeId',
        'Your collection has begun',
        'The first of your ${collection.name.toLowerCase()}.',
      );
    }
  }

  static Future<void> removeThing(String typeId, String thingId) async {
    final all = await load();
    final collection = all[typeId];
    if (collection == null) return;
    final thing = collection.things.where((t) => t.id == thingId).firstOrNull;
    await _save({
      ...all,
      typeId: MyCollection(
        typeId: typeId,
        name: collection.name,
        startedAt: collection.startedAt,
        things: [
          for (final t in collection.things)
            if (t.id != thingId) t,
        ],
      ),
    });
    if (thing?.photoId case final photo?) {
      _photoCache.remove(photo);
      await (await SharedPreferences.getInstance()).remove(
        '$_photoPrefix$photo',
      );
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
