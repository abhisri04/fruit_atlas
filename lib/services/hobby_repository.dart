import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hobby.dart';

/// Loads the hobby catalogue (assets/data/easy_hobbies.json) and the games
/// catalogue (assets/data/games.json), once per run each.
class HobbyRepository {
  static const asset = 'assets/data/easy_hobbies.json';
  static const gamesAsset = 'assets/data/games.json';
  static const challengeId = 'try_easy_hobbies';
  static const gamesChallengeId = 'play_great_games';
  static const progressKey = 'completed_hobby_ids';
  static const gamesProgressKey = 'completed_game_ids';

  final AssetBundle? bundle;
  const HobbyRepository({this.bundle});

  static final Map<String, Future<List<Hobby>>> _cache = {};

  /// The 150 hobbies.
  Future<List<Hobby>> load() => _load(asset);

  /// The games catalogue.
  Future<List<Hobby>> loadGames() => _load(gamesAsset);

  /// Hobbies followed by games: everything the finder and My Hobbies use.
  Future<List<Hobby>> loadAll() async => [
    ...await load(),
    ...await loadGames(),
  ];

  /// Progress key for the challenge an item belongs to.
  static String progressKeyFor(String challengeId) =>
      challengeId == gamesChallengeId ? gamesProgressKey : progressKey;

  Future<List<Hobby>> _load(String path) =>
      _cache[path] ??= _read(path).catchError((Object error) {
        _cache.remove(path);
        throw error;
      });

  Future<List<Hobby>> _read(String path) async {
    final raw = await (bundle ?? rootBundle).loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['items'] as List<dynamic>)
        .map((item) => Hobby.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
