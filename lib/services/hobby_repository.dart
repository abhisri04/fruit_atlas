import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hobby.dart';

/// Loads the hobby catalogue (assets/data/easy_hobbies.json) once per run.
class HobbyRepository {
  static const asset = 'assets/data/easy_hobbies.json';
  static const challengeId = 'try_easy_hobbies';
  static const progressKey = 'completed_hobby_ids';

  final AssetBundle? bundle;
  const HobbyRepository({this.bundle});

  static Future<List<Hobby>>? _cache;

  Future<List<Hobby>> load() => _cache ??= _load().catchError((Object error) {
    _cache = null;
    throw error;
  });

  Future<List<Hobby>> _load() async {
    final raw = await (bundle ?? rootBundle).loadString(asset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['items'] as List<dynamic>)
        .map((item) => Hobby.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
