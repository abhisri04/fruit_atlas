import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/experience/experience_collection_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/district_repository.dart';
import 'package:fruit_atlas/services/experience_repository.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/state_exploration_repository.dart';
import 'package:fruit_atlas/widgets/exploration_section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const expected = {
  'kerala': (
    districts: 14,
    experiences: 32,
    counts: [6, 5, 2, 0, 7, 1, 4, 3, 4],
  ),
  'tamil_nadu': (
    districts: 38,
    experiences: 25,
    counts: [6, 4, 1, 0, 5, 1, 4, 3, 2],
  ),
  'puducherry': (
    districts: 2,
    experiences: 16,
    counts: [5, 3, 2, 0, 1, 0, 2, 2, 1],
  ),
  'andaman_nicobar': (
    districts: 3,
    experiences: 17,
    counts: [4, 4, 2, 0, 1, 0, 3, 2, 1],
  ),
  'lakshadweep': (
    districts: 1,
    experiences: 13,
    counts: [2, 2, 2, 0, 1, 0, 2, 1, 3],
  ),
  'dadra_nagar_haveli_daman_diu': (
    districts: 3,
    experiences: 15,
    counts: [6, 2, 1, 0, 1, 0, 1, 1, 3],
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

void installAssets(
  WidgetTester tester, {
  Map<String, dynamic> overrides = const {},
}) {
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      final name = utf8.decode(message!.buffer.asUint8List());
      if (name == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(<String, Object>{});
      }
      if (overrides.containsKey(name)) {
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(jsonEncode(overrides[name]))),
        );
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

String normalizeTitle(String title) =>
    title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

void main() {
  for (final entry in expected.entries) {
    final state = entry.key;
    testWidgets('$state section and overall progress count shared IDs once', (
      tester,
    ) async {
      final path = 'assets/data/${state}_collections.json';
      final fixture = readJson(path);
      final collections = fixture['collections'] as List;
      final heritage = collections.singleWhere(
        (c) => c['id'] == '${state}_landmarks_heritage',
      );
      final nature = collections.singleWhere(
        (c) => c['id'] == '${state}_nature_wildlife',
      );
      final sharedId = (heritage['member_entity_ids'] as List).first as String;
      // Simulate another context referencing the same canonical entity.
      (nature['member_entity_ids'] as List).add(sharedId);
      installAssets(tester, overrides: {path: fixture});
      final districtId =
          (readJson('assets/data/${state}_districts.json')['districts'] as List)
                  .first['id']
              as String;
      SharedPreferences.setMockInitialValues({
        'completed_experience_ids': [sharedId, sharedId],
        'completed_district_ids': [districtId],
      });
      final stateItem =
          (readJson('assets/data/india_states_uts.json')['items'] as List)
              .map((j) => Item.fromJson(j as Map<String, dynamic>))
              .singleWhere((i) => i.id == state);
      final challenge =
          (readJson('assets/data/challenges.json')['challenges'] as List)
              .map((j) => Challenge.fromJson(j as Map<String, dynamic>))
              .singleWhere((c) => c.id == 'explore_indian_states');
      final atlas = await const AssetDataService().loadFruitData();
      final atlasId = atlas.states
          .singleWhere((s) => s.name == stateItem.name)
          .id;
      final fruitIds = atlas.fruits
          .where((f) => f.states.any((r) => r.stateId == atlasId))
          .map((f) => f.id)
          .toSet();
      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistItemDetailsPage(challenge: challenge, item: stateItem),
        ),
      );
      await tester.pumpAndSettle();
      final resolved = await const StateExplorationRepository().load(state);
      expect(resolved!.experiences, hasLength(entry.value.experiences));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -620));
      await tester.pumpAndSettle();
      final overall = find.text(
        '2 of ${entry.value.districts + entry.value.experiences + fruitIds.length}',
      );
      expect(overall, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Places').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final places = tester
          .widgetList<ExplorationSectionCard>(
            find.byType(ExplorationSectionCard),
          )
          .singleWhere((c) => c.title == 'Places');
      expect(places.completedCount, 1);
      expect(places.totalCount, entry.value.districts);
      await tester.scrollUntilVisible(
        find.text('Things to Do').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final thingsToDo = tester
          .widgetList<ExplorationSectionCard>(
            find.byType(ExplorationSectionCard),
          )
          .singleWhere((c) => c.title == 'Things to Do');
      expect(thingsToDo.completedCount, 1);
      expect(
        thingsToDo.totalCount,
        entry.value.counts[0] + entry.value.counts[1] + entry.value.counts[2],
      );
      expect(await ProgressService.getCompletedExperienceIds(), {sharedId});
      expect(await ProgressService.getCompletedFruitIds(), isEmpty);
      expect(
        await ProgressService.getChallengeItemIds(
          'completed_india_state_ut_ids',
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
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
        expect(members, hasLength(entry.value.counts.reduce((a, b) => a + b)));
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
          find.text('Food & Drink').hitTestable(),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
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

  test('final administrative baselines distinguish districts from regions', () {
    Set<String> names(String state) =>
        (readJson('assets/data/${state}_districts.json')['districts'] as List)
            .map((d) => d['name'] as String)
            .toSet();
    expect(names('kerala'), hasLength(14));
    expect(
      names('tamil_nadu'),
      containsAll([
        'Mayiladuthurai',
        'Chengalpattu',
        'Kallakurichi',
        'Ranipet',
        'Tenkasi',
        'Tirupathur',
      ]),
    );
    expect(names('puducherry'), {'Puducherry', 'Karaikal'});
    final puducherry =
        (readJson('assets/data/puducherry_districts.json')['districts'] as List)
            .singleWhere((d) => d['name'] == 'Puducherry');
    expect(puducherry['keywords'], containsAll(['Mahe', 'Yanam']));
    expect(names('andaman_nicobar'), {
      'Nicobar',
      'North and Middle Andaman',
      'South Andaman',
    });
    expect(names('lakshadweep'), {'Lakshadweep'});
    expect(names('dadra_nagar_haveli_daman_diu'), {
      'Dadra & Nagar Haveli',
      'Daman',
      'Diu',
    });
  });

  testWidgets(
    'My Life counts canonical new experiences and ignores stale IDs',
    (tester) async {
      installAssets(tester);
      final experienceIds = [
        for (final state in expected.keys)
          (readJson('assets/data/${state}_experiences.json')['experiences']
                      as List)
                  .first['id']
              as String,
      ];
      final districtIds = [
        for (final state in expected.keys)
          (readJson('assets/data/${state}_districts.json')['districts'] as List)
                  .first['id']
              as String,
      ];
      SharedPreferences.setMockInitialValues({
        'completed_experience_ids': [
          ...experienceIds,
          experienceIds.first,
          'exp_nonexistent',
        ],
        'completed_district_ids': [
          ...districtIds,
          districtIds.first,
          'district_nonexistent',
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: MyLifePage()));
      await tester.pumpAndSettle();
      for (final label in ['Experiences completed', 'Districts explored']) {
        final metric = find
            .ancestor(of: find.text(label), matching: find.byType(Column))
            .first;
        expect(
          find.descendant(of: metric, matching: find.text('6')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  test('new IDs are globally unique and all new assets are bundled', () {
    final assets =
        readJson('assets/data/experience_sources.json')['assets'] as List;
    final experiences = Directory('assets/data')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'experiences.*\.json$').hasMatch(f.path))
        .expand((f) => (readJson(f.path)['experiences'] as List?) ?? const [])
        .toList();
    final ids = experiences.map((e) => e['id']).toList();
    expect(ids.toSet(), hasLength(ids.length));
    final oldTitles = experiences
        .where((e) => !expected.containsKey(e['state_id']))
        .map((e) => normalizeTitle(e['title'] as String))
        .toSet();
    final batchTitles = <String>{};
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final state in expected.keys) {
      final config = readJson('assets/data/state_exploration/$state.json');
      for (final key in [
        'district_asset',
        'experience_asset',
        'collections_asset',
      ]) {
        final path = config[key] as String;
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(pubspec, contains('    - $path'));
      }
      expect(
        readJson('assets/data/district_sources.json')['assets'],
        contains(config['district_asset']),
      );
      expect(assets, contains(config['experience_asset']));
      final rows = readJson(config['experience_asset'])['experiences'] as List;
      for (final e in rows) {
        final title = normalizeTitle(e['title'] as String);
        expect(oldTitles, isNot(contains(title)), reason: title);
        expect(batchTitles.add(title), isTrue, reason: title);
        expect(e['type'], isNot('fruit'));
      }
      final collections =
          readJson(config['collections_asset'])['collections'] as List;
      final drinks =
          collections.singleWhere(
                (c) => c['id'] == '${state}_drinks',
              )['member_entity_ids']
              as List;
      expect(drinks, hasLength(expected[state]!.counts[5]));
      for (final id in drinks) {
        final drink = rows.singleWhere((e) => e['id'] == id);
        expect(drink['description'], contains('non-alcoholic'));
      }
    }
  });
  testWidgets(
    'Margazhi season shares completion across both Culture collections',
    (tester) async {
      installAssets(tester);
      const sharedId = 'exp_tamil_nadu_chennai_margazhi_music_season';
      SharedPreferences.setMockInitialValues({
        'completed_experience_ids': [sharedId],
      });
      final data = (await const StateExplorationRepository().load(
        'tamil_nadu',
      ))!;
      final references = data.collections
          .where((c) => c.memberEntityIds.contains(sharedId))
          .toList();
      expect(references.map((c) => c.id).toSet(), {
        'tamil_nadu_festivals_fairs',
        'tamil_nadu_music_dance',
      });
      expect(data.experiences.where((e) => e.id == sharedId), hasLength(1));
      final item =
          (readJson('assets/data/india_states_uts.json')['items'] as List)
              .map((j) => Item.fromJson(j as Map<String, dynamic>))
              .singleWhere((i) => i.id == 'tamil_nadu');
      final challenge =
          (readJson('assets/data/challenges.json')['challenges'] as List)
              .map((j) => Challenge.fromJson(j as Map<String, dynamic>))
              .singleWhere((c) => c.id == 'explore_indian_states');
      final atlas = await const AssetDataService().loadFruitData();
      final atlasId = atlas.states.singleWhere((s) => s.name == item.name).id;
      final fruitCount = atlas.fruits
          .where((f) => f.states.any((s) => s.stateId == atlasId))
          .map((f) => f.id)
          .toSet()
          .length;
      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistItemDetailsPage(challenge: challenge, item: item),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -620));
      await tester.pumpAndSettle();
      expect(find.text('1 of ${38 + 25 + fruitCount}'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Culture').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final culture = tester
          .widgetList<ExplorationSectionCard>(
            find.byType(ExplorationSectionCard),
          )
          .singleWhere((c) => c.title == 'Culture');
      expect(
        culture.totalCount,
        8,
      ); // 4 craft + 3 festival + 2 performance - 1 shared.
      expect(culture.completedCount, 1);
      for (final collection in references) {
        await tester.pumpWidget(
          MaterialApp(
            home: ExperienceCollectionPage(
              collection: collection,
              experiences: data.experiences
                  .where((e) => collection.memberEntityIds.contains(e.id))
                  .toList(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            '1 of ${collection.memberEntityIds.length} ${collection.completionVerb}',
          ),
          findsOneWidget,
        );
      }
      expect(await ProgressService.getCompletedExperienceIds(), {sharedId});
      expect(tester.takeException(), isNull);
    },
  );
}
