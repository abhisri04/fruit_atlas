import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/experience/experience_collection_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/district_repository.dart';
import 'package:fruit_atlas/services/experience_repository.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/state_exploration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const expected = {
  'bihar': (
    districts: 38,
    experiences: 42,
    counts: [10, 6, 4, 0, 8, 2, 5, 4, 3],
  ),
  'jharkhand': (
    districts: 24,
    experiences: 43,
    counts: [8, 8, 4, 0, 8, 2, 5, 4, 4],
  ),
  'west_bengal': (
    districts: 23,
    experiences: 48,
    counts: [10, 6, 5, 0, 10, 2, 6, 5, 4],
  ),
  'odisha': (
    districts: 30,
    experiences: 48,
    counts: [10, 7, 5, 0, 10, 2, 5, 5, 4],
  ),
  'sikkim': (
    districts: 6,
    experiences: 41,
    counts: [8, 6, 4, 0, 8, 2, 4, 5, 4],
  ),
};
const collectionNames = [
  'landmarks_heritage',
  'nature_wildlife',
  'experiences_activities',
  'fruits',
  'dishes',
  'drinks',
  'arts_crafts',
  'festivals_fairs',
  'music_dance',
];

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void installAssets(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(<String, Object>{});
      }
      final file = File(name);
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    ),
  );
  StateExplorationRepository.clearCacheForTesting();
  ExperienceRepository.clearCacheForTesting();
  DistrictRepository.clearCacheForTesting();
}

void main() {
  for (final entry in expected.entries) {
    final state = entry.key;
    testWidgets(
      '$state resolves exact counts, ordered sections and canonical memberships',
      (tester) async {
        installAssets(tester);
        final result = await const StateExplorationRepository().load(state);
        expect(result, isNotNull);
        final data = result!;
        expect(data.config.stateId, state);
        expect(data.districts, hasLength(entry.value.districts));
        expect(data.experiences, hasLength(entry.value.experiences));
        expect(data.collections, hasLength(9));
        expect(data.districts.every((d) => d.stateId == state), isTrue);
        expect(
          data.experiences.every(
            (e) => e.stateId == state && e.status == 'active',
          ),
          isTrue,
        );
        expect(data.collections.every((c) => c.contextId == state), isTrue);
        final ids = data.experiences.map((e) => e.id).toSet();
        expect(ids, hasLength(entry.value.experiences));
        expect(
          data.districts.map((d) => d.id).toSet(),
          hasLength(entry.value.districts),
        );
        final members = data.collections
            .expand((c) => c.memberEntityIds)
            .toList();
        expect(members.toSet(), ids);
        expect(members, hasLength(entry.value.experiences));
        for (var i = 0; i < collectionNames.length; i++) {
          final collection = data.collections.singleWhere(
            (c) => c.id == '${state}_${collectionNames[i]}',
          );
          expect(collection.memberEntityIds, hasLength(entry.value.counts[i]));
          expect(
            collection.parentSectionId,
            i < 3
                ? 'things_to_do'
                : i < 6
                ? 'food_drink'
                : 'culture',
          );
          expect(collection.sortOrder, i % 3 + 1);
        }
        final fruits = data.collections.singleWhere(
          (c) => c.entityType == 'fruit',
        );
        expect(fruits.memberEntityIds, isEmpty);

        final canonicalExperiences = await const ExperienceRepository()
            .getForLocation(state);
        final canonicalDistricts = await const DistrictRepository().getForState(
          state,
        );
        expect(canonicalExperiences.map((e) => e.id).toSet(), ids);
        expect(
          canonicalDistricts.map((d) => d.id).toSet(),
          data.districts.map((d) => d.id).toSet(),
        );

        final search = GlobalSearchService();
        await search.load();
        final first = data.experiences.first;
        expect(
          search
              .search(first.title)
              .where((r) => r.id == 'experience:${first.id}'),
          hasLength(1),
        );
      },
    );

    testWidgets(
      '$state Fruits page derives membership and completion from Fruit Atlas',
      (tester) async {
        installAssets(tester);
        final atlas = await const AssetDataService().loadFruitData();
        final stateItem =
            (readJson('assets/data/india_states_uts.json')['items'] as List)
                .map((j) => Item.fromJson(j as Map<String, dynamic>))
                .singleWhere((i) => i.id == state);
        final atlasId = atlas.states
            .singleWhere((s) => s.name == stateItem.name)
            .id;
        final fruitIds = atlas.fruits
            .where((f) => f.states.any((r) => r.stateId == atlasId))
            .map((f) => f.id)
            .toSet();
        SharedPreferences.setMockInitialValues({
          'completed_fruit_ids': fruitIds.toList(),
        });
        final challenge =
            (readJson('assets/data/challenges.json')['challenges'] as List)
                .map((j) => Challenge.fromJson(j as Map<String, dynamic>))
                .singleWhere((c) => c.id == 'explore_indian_states');
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: ChecklistItemDetailsPage(
              challenge: challenge,
              item: stateItem,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Food & Drink'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Food & Drink'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Fruits'));
        await tester.tap(find.text('Fruits'));
        await tester.pumpAndSettle();
        final page = tester.widget<ExperienceCollectionPage>(
          find.byType(ExperienceCollectionPage),
        );
        expect(page.fruits.map((f) => f.id).toSet(), fruitIds);
        expect(page.experiences, isEmpty);
        expect(page.collection.memberEntityIds, isEmpty);
        if (fruitIds.isEmpty) {
          expect(find.text('0 experiences'), findsOneWidget);
        } else {
          expect(
            find.text('${fruitIds.length} of ${fruitIds.length} explored'),
            findsOneWidget,
          );
        }
        expect(await ProgressService.getCompletedExperienceIds(), isEmpty);
        expect(await ProgressService.getCompletedDistrictIds(), isEmpty);
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );

    test(
      '$state completion keys remain independent and retain existing progress',
      () async {
        SharedPreferences.setMockInitialValues({
          'completed_experience_ids': ['exp_rajasthan_mehrangarh_fort'],
          'completed_fruit_ids': ['FR001'],
          'completed_district_ids': ['district_rajasthan_ajmer'],
          'completed_india_state_ut_ids': ['rajasthan'],
        });
        final experience =
            (readJson('assets/data/${state}_experiences.json')['experiences']
                        as List)
                    .first['id']
                as String;
        final district =
            (readJson('assets/data/${state}_districts.json')['districts']
                        as List)
                    .first['id']
                as String;
        await ProgressService.toggleExperience(experience);
        expect(await ProgressService.getCompletedDistrictIds(), {
          'district_rajasthan_ajmer',
        });
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          {'rajasthan'},
        );
        await ProgressService.toggleDistrict(district);
        await ProgressService.toggleChallengeItem(
          'completed_india_state_ut_ids',
          state,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('completed_experience_ids')!.toSet(), {
          'exp_rajasthan_mehrangarh_fort',
          experience,
        });
        expect(prefs.getStringList('completed_district_ids')!.toSet(), {
          'district_rajasthan_ajmer',
          district,
        });
        expect(prefs.getStringList('completed_fruit_ids'), ['FR001']);
        await ProgressService.toggleChallengeItem(
          'completed_india_state_ut_ids',
          state,
        );
        await ProgressService.toggleDistrict(district);
        expect(await ProgressService.getCompletedExperienceIds(), {
          'exp_rajasthan_mehrangarh_fort',
          experience,
        });
      },
    );
  }

  test('eastern administrative baselines retain current district names', () {
    final sikkim =
        readJson('assets/data/sikkim_districts.json')['districts'] as List;
    expect(sikkim.map((d) => d['name']).toSet(), {
      'Gangtok',
      'Gyalshing',
      'Mangan',
      'Namchi',
      'Pakyong',
      'Soreng',
    });
    final bihar =
        readJson('assets/data/bihar_districts.json')['districts'] as List;
    expect(bihar.where((d) => d['name'] == 'Gaya Ji'), hasLength(1));
  });
}
