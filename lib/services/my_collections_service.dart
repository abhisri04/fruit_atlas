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

  /// On the wishlist, not owned yet.
  final bool wanted;
  final bool favourite;

  /// How it came: one of [CollectedThing.sources], optional.
  final String? source;

  static const sources = ['Bought', 'Gift', 'Swap', 'Found', 'Made'];

  const CollectedThing({
    required this.id,
    required this.name,
    required this.addedAt,
    this.note,
    this.photoId,
    this.wanted = false,
    this.favourite = false,
    this.source,
  });

  CollectedThing copyWith({bool? wanted, bool? favourite, DateTime? addedAt}) =>
      CollectedThing(
        id: id,
        name: name,
        addedAt: addedAt ?? this.addedAt,
        note: note,
        photoId: photoId,
        wanted: wanted ?? this.wanted,
        favourite: favourite ?? this.favourite,
        source: source,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (note != null && note!.isNotEmpty) 'note': note,
    'added_at': addedAt.toUtc().toIso8601String(),
    if (photoId != null) 'photo_id': photoId,
    if (wanted) 'wanted': true,
    if (favourite) 'favourite': true,
    if (source != null) 'source': source,
  };

  factory CollectedThing.fromJson(Map<String, dynamic> json) => CollectedThing(
    id: json['id'] as String,
    name: json['name'] as String,
    note: json['note'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String).toLocal(),
    photoId: json['photo_id'] as String?,
    wanted: json['wanted'] == true,
    favourite: json['favourite'] == true,
    source: json['source'] as String?,
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

  /// A set to complete, e.g. 50 coins. Optional.
  final int? goal;

  const MyCollection({
    required this.typeId,
    required this.name,
    required this.startedAt,
    this.things = const [],
    this.goal,
  });

  List<CollectedThing> get owned => [
    for (final t in things)
      if (!t.wanted) t,
  ];

  List<CollectedThing> get wishlist => [
    for (final t in things)
      if (t.wanted) t,
  ];

  MyCollection copyWith({
    List<CollectedThing>? things,
    int? goal,
    bool clearGoal = false,
  }) => MyCollection(
    typeId: typeId,
    name: name,
    startedAt: startedAt,
    things: things ?? this.things,
    goal: clearGoal ? null : (goal ?? this.goal),
  );

  Map<String, dynamic> toJson() => {
    'type_id': typeId,
    'name': name,
    'started_at': startedAt.toUtc().toIso8601String(),
    'things': [for (final t in things) t.toJson()],
    if (goal != null) 'goal': goal,
  };

  factory MyCollection.fromJson(Map<String, dynamic> json) => MyCollection(
    typeId: json['type_id'] as String,
    name: json['name'] as String,
    startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    things: [
      for (final t in json['things'] as List<dynamic>? ?? [])
        CollectedThing.fromJson(t as Map<String, dynamic>),
    ],
    goal: (json['goal'] as num?)?.toInt(),
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
    bool wanted = false,
    String? source,
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
      wanted: wanted,
      source: source,
    );
    await _save({
      ...all,
      typeId: collection.copyWith(things: [...collection.things, thing]),
    });
    if (wanted) return;
    await ProgressService.recordActivity(at, 'collect:$typeId');
    if (collection.owned.isEmpty) {
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
      typeId: collection.copyWith(
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

  static Future<void> _change(
    String typeId,
    String thingId,
    CollectedThing Function(CollectedThing) change,
  ) async {
    final all = await load();
    final collection = all[typeId];
    if (collection == null) return;
    await _save({
      ...all,
      typeId: collection.copyWith(
        things: [
          for (final t in collection.things) t.id == thingId ? change(t) : t,
        ],
      ),
    });
  }

  static Future<void> toggleFavourite(String typeId, String thingId) =>
      _change(typeId, thingId, (t) => t.copyWith(favourite: !t.favourite));

  /// A wishlist piece arrived: it joins the collection today.
  static Future<void> gotIt(
    String typeId,
    String thingId, {
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    await _change(
      typeId,
      thingId,
      (t) => t.copyWith(wanted: false, addedAt: at),
    );
    await ProgressService.recordActivity(at, 'collect:$typeId');
    await ProgressService.recordCollectionMilestone(
      'collect_wish_$thingId',
      'Off the wishlist!',
      'A piece you wanted is now in your collection.',
    );
  }

  /// A set to complete; null clears it.
  static Future<void> setGoal(String typeId, int? goal) async {
    final all = await load();
    final collection = all[typeId];
    if (collection == null) return;
    await _save({
      ...all,
      typeId: goal == null || goal <= 0
          ? collection.copyWith(clearGoal: true)
          : collection.copyWith(goal: goal),
    });
    final c = (await load())[typeId]!;
    if (c.goal != null && c.owned.length >= c.goal!) {
      await ProgressService.recordCollectionMilestone(
        'collect_goal_${typeId}_${c.goal}',
        'Set complete!',
        'You reached your goal of ${c.goal} ${c.name.toLowerCase()}.',
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
