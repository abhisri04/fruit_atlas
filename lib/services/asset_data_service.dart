import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/challenge.dart';
import '../models/district.dart';
import '../models/fruit.dart';
import '../models/experience.dart';
import '../models/experience_collection.dart';
import '../models/jyotirlinga.dart';
import '../models/item.dart';

class AssetDataService {
  const AssetDataService();

  Future<List<Category>> loadCategories() async {
    final data = await _loadJson('assets/data/categories.json');
    final rawCategories = data['categories'] as List<dynamic>? ?? [];
    return rawCategories
        .map((category) => Category.fromJson(category as Map<String, dynamic>))
        .toList();
  }

  Future<List<Challenge>> loadChallenges() async {
    final data = await _loadJson('assets/data/challenges.json');
    final rawChallenges = data['challenges'] as List<dynamic>? ?? [];
    return rawChallenges
        .map(
          (challenge) => Challenge.fromJson(challenge as Map<String, dynamic>),
        )
        .toList();
  }

  Future<FruitAtlasData> loadFruitData() async {
    final data = await _loadJson('assets/data/fruit_atlas_seed.json');
    return FruitAtlasData.fromJson(data);
  }

  Future<List<JyotirlingaSite>> loadJyotirlingas() async {
    final data = await _loadJson('assets/data/jyotirlingas.json');
    final rawSites = data['jyotirlingas'] as List<dynamic>? ?? [];
    return rawSites
        .map((site) => JyotirlingaSite.fromJson(site as Map<String, dynamic>))
        .toList();
  }

  Future<List<Item>> loadChallengeItems(Challenge challenge) async {
    final assetPath = challenge.dataAsset;
    if (assetPath == null || assetPath.isEmpty) return [];

    final data = await _loadJson(assetPath);
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((item) => Item.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<String>>> loadSearchKeywords() async {
    final data = await _loadJson('assets/data/search_keywords.json');
    return data.map(
      (key, value) => MapEntry(key, (value as List).cast<String>()),
    );
  }

  Future<List<String>> loadExperienceSources() async {
    final data = await _loadJson('assets/data/experience_sources.json');
    return (data['assets'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
  }

  Future<List<Experience>> loadExperiencesFromAsset(String assetPath) async {
    final data = await _loadJson(assetPath);
    return (data['experiences'] as List<dynamic>? ?? [])
        .map(
          (experience) =>
              Experience.fromJson(experience as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<String>> loadDistrictSources() async {
    final data = await _loadJson('assets/data/district_sources.json');
    return (data['assets'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
  }

  Future<List<District>> loadDistrictsFromAsset(String assetPath) async {
    final data = await _loadJson(assetPath);
    return (data['districts'] as List<dynamic>? ?? [])
        .map((district) => District.fromJson(district as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExperienceCollection>> loadExperienceCollections() async {
    return loadExperienceCollectionsFromAsset(
      'assets/data/experience_collections.json',
    );
  }

  Future<List<ExperienceCollection>> loadExperienceCollectionsFromAsset(
    String assetPath,
  ) async {
    final data = await _loadJson(assetPath);
    return (data['collections'] as List<dynamic>? ?? [])
        .map(
          (collection) =>
              ExperienceCollection.fromJson(collection as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, dynamic>> loadStateExplorationIndex() {
    return _loadJson('assets/data/state_exploration/index.json');
  }

  Future<Map<String, dynamic>> loadStateExplorationConfig(String assetPath) {
    return _loadJson(assetPath);
  }

  Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final jsonString = utf8.decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
