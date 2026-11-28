import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Item> _load(String file) =>
    ((jsonDecode(File('assets/data/$file').readAsStringSync())
                as Map<String, dynamic>)['items']
            as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Item.fromJson)
        .toList(growable: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final families = _load('scent_families.json');
  final perfumes = _load('famous_perfumes.json');
  final notes = _load('scent_notes.json');
  final attars = _load('indian_attars.json');
  const familyNames = {
    'Fresh',
    'Floral',
    'Amber (Oriental)',
    'Woody',
    'Chypre',
    'Fougère',
    'Gourmand',
    'Leather & Smoke',
    'Oud & Attar',
  };

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('catalogues have the expected sizes and unique ids', () {
    expect(families, hasLength(9));
    expect(perfumes, hasLength(58));
    expect(notes, hasLength(42));
    expect(attars, hasLength(14));
    for (final list in [families, perfumes, notes, attars]) {
      expect(list.map((i) => i.id).toSet(), hasLength(list.length));
      expect(list.map((i) => i.name).toSet(), hasLength(list.length));
      for (final item in list) {
        expect(item.description, isNotEmpty, reason: item.id);
        expect(item.howToSteps, hasLength(3), reason: item.id);
      }
    }
  });

  test('scent comes first: perfumes are grouped by family, not brand', () {
    expect(families.map((f) => f.category).toSet(), familyNames);
    expect(perfumes.map((p) => p.filterGroup).toSet(), familyNames);
    for (final perfume in perfumes) {
      expect(perfume.metadata['Family'], perfume.filterGroup);
      expect(perfume.metadata['Made by'], isNotEmpty, reason: perfume.id);
      // The maker is a detail, never the grouping.
      expect(perfume.filterGroup, isNot(perfume.metadata['Made by']));
    }
  });

  test('every family is explained with famous examples from the catalogue', () {
    final perfumeNames = perfumes.map((p) => p.name).toSet();
    for (final family in families) {
      final examples = family.metadata['Famous examples']!.split(' · ');
      expect(examples, isNotEmpty, reason: family.id);
      expect(perfumeNames, containsAll(examples), reason: family.id);
    }
    expect(
      perfumes.map((p) => p.name),
      containsAll(['Chanel No. 5', 'Shalimar', 'Mitsouko', 'CK One']),
    );
    expect(
      attars.map((a) => a.category),
      containsAll(['Mitti', 'Ruh Gulab', 'Ruh Khus', 'Shamama']),
    );
  });

  test('no prices or costs anywhere in the scent data', () {
    for (final file in [
      'scent_families.json',
      'famous_perfumes.json',
      'scent_notes.json',
      'indian_attars.json',
    ]) {
      final text = File('assets/data/$file').readAsStringSync();
      expect(text, isNot(contains('₹')), reason: file);
      expect(text.toLowerCase(), isNot(contains('price')), reason: file);
      expect(text, isNot(contains('"cost"')), reason: file);
    }
  });

  test('scent category and challenges are registered and bundled', () async {
    final data = const AssetDataService();
    expect((await data.loadCategories()).map((c) => c.id), contains('scent'));
    final challenges = (await data.loadChallenges())
        .where((c) => c.categoryId == 'scent')
        .toList();
    expect(challenges.map((c) => c.id).toSet(), {
      'explore_scent_families',
      'explore_iconic_perfumes',
      'explore_scent_notes',
      'explore_indian_attars',
    });
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final challenge in challenges) {
      expect(challenge.status, 'active');
      expect(pubspec, contains('- ${challenge.dataAsset}'));
      expect(
        await data.loadChallengeItems(challenge),
        hasLength(challenge.totalItems),
      );
    }
  });

  test('smelling earns XP, badges and quest credit', () async {
    final now = DateTime(2026, 11, 24, 12);
    await ProgressService.toggleChallengeItem(
      'completed_perfume_ids',
      perfumes.first.id,
    );
    await ProgressService.toggleChallengeItem(
      'completed_attar_ids',
      attars.first.id,
    );
    final rewards = await ProgressService.getRewardedEventIds();
    expect(rewards, contains('completion:perfume:${perfumes.first.id}'));
    expect(rewards, contains('completion:attar:${attars.first.id}'));
    final summary = await const ProgressSummaryService().load();
    expect(
      summary.achievementIds,
      containsAll(['perfume_first', 'attar_first']),
    );

    SharedPreferences.setMockInitialValues({});
    await ProgressService.recordMeaningfulCompletion(
      'note:${notes.first.id}',
      now: now,
    );
    final quest = (await const GamificationService().load(
      await const ProgressSummaryService().load(),
      now: now,
    )).quest;
    expect(quest.tasks.singleWhere((t) => t.id == 'world').completed, isTrue);
  });

  test('scents appear in Discovery until smelled', () async {
    SharedPreferences.setMockInitialValues({
      'completed_perfume_ids': [perfumes.first.id],
    });
    final scents = (await DailyDiscoveryService().buildEligiblePool())
        .where((d) => d.type == DailyDiscoveryType.scent)
        .toList();
    expect(scents, hasLength(9 + 58 + 42 + 14 - 1));
    expect(scents.every((d) => d.categoryId == 'scent'), isTrue);
    expect(
      scents.map((d) => d.canonicalId),
      isNot(contains(perfumes.first.id)),
    );
  });
}
