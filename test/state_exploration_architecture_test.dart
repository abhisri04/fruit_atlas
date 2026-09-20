import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/state_exploration_repository.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/circular_progress_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
  }

  testWidgets('all 36 canonical State and UT IDs resolve on demand', (
    tester,
  ) async {
    installAssets(tester);
    StateExplorationRepository.clearCacheForTesting();
    const repository = StateExplorationRepository();
    final states =
        readJson('assets/data/india_states_uts.json')['items'] as List;
    final canonicalIds = states.map((item) => item['id'] as String).toSet();
    final index =
        readJson('assets/data/state_exploration/index.json')['states']
            as Map<String, dynamic>;

    expect(canonicalIds, hasLength(36));
    expect(index.keys.toSet(), canonicalIds);
    for (final state in states) {
      final id = state['id'] as String;
      final resolved = await repository.load(id);
      expect(resolved, isNotNull, reason: id);
      expect(resolved!.config.stateId, id);
      expect(resolved.config.stateName, state['name']);
      expect(resolved.collections, hasLength(9), reason: id);
      expect(resolved.config.districtAsset, isNotNull, reason: id);
      expect(resolved.config.experienceAsset, isNotNull, reason: id);
      expect(resolved.config.collectionsAsset, isNotNull, reason: id);
      expect(resolved.districts, isNotEmpty, reason: id);
      expect(resolved.experiences, isNotEmpty, reason: id);
      expect(
        resolved.collections.where(
          (collection) => collection.parentSectionId == 'places',
        ),
        isEmpty,
        reason: id,
      );
      final thingsToDo =
          resolved.collections
              .where(
                (collection) => collection.parentSectionId == 'things_to_do',
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(thingsToDo.map((collection) => collection.title).toList(), [
        'Landmarks & Heritage',
        'Nature & Wildlife',
        'Experiences & Activities',
      ], reason: id);
      expect(thingsToDo.map((collection) => collection.sortOrder).toList(), [
        1,
        2,
        3,
      ], reason: id);
      final experienceById = {
        for (final experience in resolved.experiences)
          experience.id: experience,
      };
      for (final memberId
          in thingsToDo
              .where(
                (collection) =>
                    collection.title == 'Landmarks & Heritage' ||
                    collection.title == 'Nature & Wildlife',
              )
              .expand((collection) => collection.memberEntityIds)) {
        expect(
          experienceById[memberId]?.section,
          'Things to Do',
          reason: '$id: $memberId',
        );
      }
    }
  });

  testWidgets('Rajasthan resolves its unchanged canonical datasets', (
    tester,
  ) async {
    installAssets(tester);
    StateExplorationRepository.clearCacheForTesting();
    final resolved = await const StateExplorationRepository().load('rajasthan');
    final sourceExperiences =
        readJson('assets/data/rajasthan_experiences.json')['experiences']
            as List;
    final sourceDistricts =
        readJson('assets/data/rajasthan_districts.json')['districts'] as List;
    final sourceCollections =
        readJson('assets/data/experience_collections.json')['collections']
            as List;

    expect(
      resolved!.experiences.map((item) => item.id).toSet(),
      sourceExperiences.map((item) => item['id']).toSet(),
    );
    expect(
      resolved.districts.map((item) => item.id).toSet(),
      sourceDistricts.map((item) => item['id']).toSet(),
    );
    expect(
      resolved.collections.map((item) => item.id).toSet(),
      sourceCollections.map((item) => item['id']).toSet(),
    );
  });

  testWidgets('Uttar Pradesh resolves its complete canonical catalogue', (
    tester,
  ) async {
    installAssets(tester);
    StateExplorationRepository.clearCacheForTesting();
    final resolved = await const StateExplorationRepository().load(
      'uttar_pradesh',
    );

    expect(resolved, isNotNull);
    expect(resolved!.districts, hasLength(75));
    expect(resolved.experiences, hasLength(119));
    expect(resolved.collections, hasLength(9));
    expect(
      resolved.districts.every(
        (district) => district.stateId == 'uttar_pradesh',
      ),
      isTrue,
    );
    expect(
      resolved.experiences.every(
        (experience) => experience.stateId == 'uttar_pradesh',
      ),
      isTrue,
    );
    expect(
      resolved.collections.every(
        (collection) => collection.contextId == 'uttar_pradesh',
      ),
      isTrue,
    );

    final experienceIds = resolved.experiences
        .map((experience) => experience.id)
        .toSet();
    expect(experienceIds, hasLength(119));
    final experienceCollections = resolved.collections.where(
      (collection) => collection.entityType == 'experience',
    );
    final memberIds = experienceCollections
        .expand((collection) => collection.memberEntityIds)
        .toList(growable: false);
    expect(memberIds.toSet(), hasLength(119));
    expect(memberIds.toSet().difference(experienceIds), isEmpty);
    expect(
      {
        for (final collection in resolved.collections)
          collection.id: collection.memberEntityIds.length,
      },
      {
        'uttar_pradesh_landmarks_heritage': 30,
        'uttar_pradesh_nature_wildlife': 13,
        'uttar_pradesh_experiences_activities': 12,
        'uttar_pradesh_fruits': 0,
        'uttar_pradesh_dishes': 18,
        'uttar_pradesh_drinks': 4,
        'uttar_pradesh_arts_crafts': 16,
        'uttar_pradesh_festivals_fairs': 16,
        'uttar_pradesh_music_dance': 10,
      },
    );
    for (final collectionId in [
      'uttar_pradesh_landmarks_heritage',
      'uttar_pradesh_nature_wildlife',
      'uttar_pradesh_experiences_activities',
    ]) {
      expect(
        resolved.collections
            .singleWhere((collection) => collection.id == collectionId)
            .parentSectionId,
        'things_to_do',
      );
    }

    final fruits = resolved.collections.singleWhere(
      (collection) => collection.id == 'uttar_pradesh_fruits',
    );
    expect(fruits.entityType, 'fruit');
    expect(fruits.memberEntityIds, isEmpty);
    final fruitData = readJson('assets/data/fruit_atlas_seed.json');
    final states = fruitData['states'] as List;
    final fruitStateId = states.firstWhere(
      (state) => state['name'] == 'Uttar Pradesh',
    )['id'];
    final canonicalFruitIds = (fruitData['fruits'] as List)
        .where(
          (fruit) => (fruit['states'] as List).any(
            (relationship) => relationship['state_id'] == fruitStateId,
          ),
        )
        .map((fruit) => fruit['id'])
        .toSet();
    expect(canonicalFruitIds, {'FR001', 'FR079', 'FR121'});
  });

  testWidgets(
    'Delhi, Haryana, and Punjab resolve their complete canonical catalogues',
    (tester) async {
      installAssets(tester);
      final expected =
          <
            String,
            ({int districts, int experiences, Map<String, int> collections})
          >{
            'delhi': (
              districts: 13,
              experiences: 72,
              collections: {
                'delhi_landmarks_heritage': 22,
                'delhi_nature_wildlife': 7,
                'delhi_experiences_activities': 10,
                'delhi_fruits': 0,
                'delhi_dishes': 12,
                'delhi_drinks': 4,
                'delhi_arts_crafts': 6,
                'delhi_festivals_fairs': 7,
                'delhi_music_dance': 4,
              },
            ),
            'haryana': (
              districts: 22,
              experiences: 68,
              collections: {
                'haryana_landmarks_heritage': 18,
                'haryana_nature_wildlife': 8,
                'haryana_experiences_activities': 10,
                'haryana_fruits': 0,
                'haryana_dishes': 10,
                'haryana_drinks': 3,
                'haryana_arts_crafts': 6,
                'haryana_festivals_fairs': 7,
                'haryana_music_dance': 6,
              },
            ),
            'punjab': (
              districts: 23,
              experiences: 77,
              collections: {
                'punjab_landmarks_heritage': 20,
                'punjab_nature_wildlife': 7,
                'punjab_experiences_activities': 10,
                'punjab_fruits': 0,
                'punjab_dishes': 12,
                'punjab_drinks': 3,
                'punjab_arts_crafts': 8,
                'punjab_festivals_fairs': 8,
                'punjab_music_dance': 9,
              },
            ),
          };

      for (final entry in expected.entries) {
        StateExplorationRepository.clearCacheForTesting();
        final resolved = await const StateExplorationRepository().load(
          entry.key,
        );
        expect(resolved, isNotNull, reason: entry.key);
        expect(resolved!.districts, hasLength(entry.value.districts));
        expect(resolved.experiences, hasLength(entry.value.experiences));
        expect(resolved.collections, hasLength(9));
        expect(
          resolved.districts.every((district) => district.stateId == entry.key),
          isTrue,
        );
        expect(
          resolved.experiences.every(
            (experience) => experience.stateId == entry.key,
          ),
          isTrue,
        );
        expect(
          resolved.collections.every(
            (collection) => collection.contextId == entry.key,
          ),
          isTrue,
        );

        final experienceIds = resolved.experiences
            .map((experience) => experience.id)
            .toSet();
        expect(experienceIds, hasLength(entry.value.experiences));
        final memberIds = resolved.collections
            .where((collection) => collection.entityType == 'experience')
            .expand((collection) => collection.memberEntityIds)
            .toList(growable: false);
        expect(memberIds.toSet(), hasLength(entry.value.experiences));
        expect(memberIds.toSet().difference(experienceIds), isEmpty);
        expect({
          for (final collection in resolved.collections)
            collection.id: collection.memberEntityIds.length,
        }, entry.value.collections);

        final fruits = resolved.collections.singleWhere(
          (collection) => collection.entityType == 'fruit',
        );
        expect(fruits.memberEntityIds, isEmpty);
        for (final collectionId in [
          '${entry.key}_landmarks_heritage',
          '${entry.key}_nature_wildlife',
          '${entry.key}_experiences_activities',
        ]) {
          expect(
            resolved.collections
                .singleWhere((collection) => collection.id == collectionId)
                .parentSectionId,
            'things_to_do',
          );
        }
      }
    },
  );

  testWidgets(
    'five northern State and UT catalogues resolve with canonical memberships',
    (tester) async {
      installAssets(tester);
      final expected =
          <
            String,
            ({int districts, int experiences, Map<String, int> collections})
          >{
            'uttarakhand': (
              districts: 13,
              experiences: 81,
              collections: {
                'uttarakhand_landmarks_heritage': 18,
                'uttarakhand_nature_wildlife': 12,
                'uttarakhand_experiences_activities': 13,
                'uttarakhand_fruits': 0,
                'uttarakhand_dishes': 13,
                'uttarakhand_drinks': 3,
                'uttarakhand_arts_crafts': 7,
                'uttarakhand_festivals_fairs': 9,
                'uttarakhand_music_dance': 6,
              },
            ),
            'himachal_pradesh': (
              districts: 12,
              experiences: 81,
              collections: {
                'himachal_pradesh_landmarks_heritage': 19,
                'himachal_pradesh_nature_wildlife': 11,
                'himachal_pradesh_experiences_activities': 12,
                'himachal_pradesh_fruits': 0,
                'himachal_pradesh_dishes': 13,
                'himachal_pradesh_drinks': 3,
                'himachal_pradesh_arts_crafts': 8,
                'himachal_pradesh_festivals_fairs': 9,
                'himachal_pradesh_music_dance': 6,
              },
            ),
            'jammu_kashmir': (
              districts: 20,
              experiences: 92,
              collections: {
                'jammu_kashmir_landmarks_heritage': 21,
                'jammu_kashmir_nature_wildlife': 15,
                'jammu_kashmir_experiences_activities': 13,
                'jammu_kashmir_fruits': 0,
                'jammu_kashmir_dishes': 14,
                'jammu_kashmir_drinks': 3,
                'jammu_kashmir_arts_crafts': 10,
                'jammu_kashmir_festivals_fairs': 8,
                'jammu_kashmir_music_dance': 8,
              },
            ),
            'ladakh': (
              districts: 7,
              experiences: 74,
              collections: {
                'ladakh_landmarks_heritage': 16,
                'ladakh_nature_wildlife': 11,
                'ladakh_experiences_activities': 12,
                'ladakh_fruits': 0,
                'ladakh_dishes': 9,
                'ladakh_drinks': 3,
                'ladakh_arts_crafts': 8,
                'ladakh_festivals_fairs': 9,
                'ladakh_music_dance': 6,
              },
            ),
            'chandigarh': (
              districts: 1,
              experiences: 54,
              collections: {
                'chandigarh_landmarks_heritage': 10,
                'chandigarh_nature_wildlife': 7,
                'chandigarh_experiences_activities': 10,
                'chandigarh_fruits': 0,
                'chandigarh_dishes': 8,
                'chandigarh_drinks': 3,
                'chandigarh_arts_crafts': 5,
                'chandigarh_festivals_fairs': 7,
                'chandigarh_music_dance': 4,
              },
            ),
          };

      for (final entry in expected.entries) {
        StateExplorationRepository.clearCacheForTesting();
        final resolved = await const StateExplorationRepository().load(
          entry.key,
        );
        expect(resolved, isNotNull, reason: entry.key);
        expect(resolved!.districts, hasLength(entry.value.districts));
        expect(resolved.experiences, hasLength(entry.value.experiences));
        expect(resolved.collections, hasLength(9));
        expect(
          resolved.districts.every((district) => district.stateId == entry.key),
          isTrue,
        );
        expect(
          resolved.experiences.every(
            (experience) => experience.stateId == entry.key,
          ),
          isTrue,
        );
        expect(
          resolved.collections.every(
            (collection) => collection.contextId == entry.key,
          ),
          isTrue,
        );

        final experienceIds = resolved.experiences
            .map((experience) => experience.id)
            .toSet();
        expect(experienceIds, hasLength(entry.value.experiences));
        final memberIds = resolved.collections
            .where((collection) => collection.entityType == 'experience')
            .expand((collection) => collection.memberEntityIds)
            .toList(growable: false);
        expect(memberIds.toSet(), hasLength(entry.value.experiences));
        expect(memberIds.toSet().difference(experienceIds), isEmpty);
        expect({
          for (final collection in resolved.collections)
            collection.id: collection.memberEntityIds.length,
        }, entry.value.collections);

        final fruits = resolved.collections.singleWhere(
          (collection) => collection.entityType == 'fruit',
        );
        expect(fruits.memberEntityIds, isEmpty);
        for (final collectionId in [
          '${entry.key}_landmarks_heritage',
          '${entry.key}_nature_wildlife',
          '${entry.key}_experiences_activities',
        ]) {
          expect(
            resolved.collections
                .singleWhere((collection) => collection.id == collectionId)
                .parentSectionId,
            'things_to_do',
          );
        }
      }
    },
  );

  testWidgets(
    'five central and western State catalogues resolve with canonical memberships',
    (tester) async {
      installAssets(tester);
      final expected =
          <
            String,
            ({int districts, int experiences, Map<String, int> collections})
          >{
            'madhya_pradesh': (
              districts: 55,
              experiences: 84,
              collections: {
                'madhya_pradesh_landmarks_heritage': 22,
                'madhya_pradesh_nature_wildlife': 12,
                'madhya_pradesh_experiences_activities': 11,
                'madhya_pradesh_fruits': 0,
                'madhya_pradesh_dishes': 12,
                'madhya_pradesh_drinks': 3,
                'madhya_pradesh_arts_crafts': 9,
                'madhya_pradesh_festivals_fairs': 8,
                'madhya_pradesh_music_dance': 7,
              },
            ),
            'gujarat': (
              districts: 33,
              experiences: 84,
              collections: {
                'gujarat_landmarks_heritage': 20,
                'gujarat_nature_wildlife': 12,
                'gujarat_experiences_activities': 11,
                'gujarat_fruits': 0,
                'gujarat_dishes': 14,
                'gujarat_drinks': 3,
                'gujarat_arts_crafts': 10,
                'gujarat_festivals_fairs': 8,
                'gujarat_music_dance': 6,
              },
            ),
            'maharashtra': (
              districts: 36,
              experiences: 91,
              collections: {
                'maharashtra_landmarks_heritage': 22,
                'maharashtra_nature_wildlife': 14,
                'maharashtra_experiences_activities': 12,
                'maharashtra_fruits': 0,
                'maharashtra_dishes': 16,
                'maharashtra_drinks': 3,
                'maharashtra_arts_crafts': 8,
                'maharashtra_festivals_fairs': 9,
                'maharashtra_music_dance': 7,
              },
            ),
            'goa': (
              districts: 3,
              experiences: 71,
              collections: {
                'goa_landmarks_heritage': 15,
                'goa_nature_wildlife': 11,
                'goa_experiences_activities': 11,
                'goa_fruits': 0,
                'goa_dishes': 12,
                'goa_drinks': 3,
                'goa_arts_crafts': 6,
                'goa_festivals_fairs': 7,
                'goa_music_dance': 6,
              },
            ),
            'chhattisgarh': (
              districts: 33,
              experiences: 79,
              collections: {
                'chhattisgarh_landmarks_heritage': 15,
                'chhattisgarh_nature_wildlife': 13,
                'chhattisgarh_experiences_activities': 12,
                'chhattisgarh_fruits': 0,
                'chhattisgarh_dishes': 13,
                'chhattisgarh_drinks': 3,
                'chhattisgarh_arts_crafts': 8,
                'chhattisgarh_festivals_fairs': 8,
                'chhattisgarh_music_dance': 7,
              },
            ),
          };

      for (final entry in expected.entries) {
        StateExplorationRepository.clearCacheForTesting();
        final resolved = await const StateExplorationRepository().load(
          entry.key,
        );
        expect(resolved, isNotNull, reason: entry.key);
        expect(resolved!.districts, hasLength(entry.value.districts));
        expect(resolved.experiences, hasLength(entry.value.experiences));
        expect(resolved.collections, hasLength(9));
        expect(
          resolved.districts.every((district) => district.stateId == entry.key),
          isTrue,
        );
        expect(
          resolved.experiences.every(
            (experience) => experience.stateId == entry.key,
          ),
          isTrue,
        );
        expect(
          resolved.collections.every(
            (collection) => collection.contextId == entry.key,
          ),
          isTrue,
        );

        final experienceIds = resolved.experiences
            .map((experience) => experience.id)
            .toSet();
        expect(experienceIds, hasLength(entry.value.experiences));
        final memberIds = resolved.collections
            .where((collection) => collection.entityType == 'experience')
            .expand((collection) => collection.memberEntityIds)
            .toList(growable: false);
        expect(memberIds.toSet(), hasLength(entry.value.experiences));
        expect(memberIds.toSet().difference(experienceIds), isEmpty);
        expect({
          for (final collection in resolved.collections)
            collection.id: collection.memberEntityIds.length,
        }, entry.value.collections);

        final fruits = resolved.collections.singleWhere(
          (collection) => collection.entityType == 'fruit',
        );
        expect(fruits.memberEntityIds, isEmpty);
        for (final collectionId in [
          '${entry.key}_landmarks_heritage',
          '${entry.key}_nature_wildlife',
          '${entry.key}_experiences_activities',
        ]) {
          expect(
            resolved.collections
                .singleWhere((collection) => collection.id == collectionId)
                .parentSectionId,
            'things_to_do',
          );
        }
      }
    },
  );

  test(
    'central and western catalogues preserve canonical independent completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      const stateKey = 'completed_india_state_ut_ids';
      for (final state in [
        'madhya_pradesh',
        'gujarat',
        'maharashtra',
        'goa',
        'chhattisgarh',
      ]) {
        final district =
            (readJson('assets/data/${state}_districts.json')['districts']
                        as List)
                    .first['id']
                as String;
        final experience =
            (readJson('assets/data/${state}_experiences.json')['experiences']
                        as List)
                    .first['id']
                as String;
        await ProgressService.toggleExperience(experience);
        expect(await ProgressService.getCompletedDistrictIds(), isEmpty);
        expect(await ProgressService.getChallengeItemIds(stateKey), isEmpty);
        await ProgressService.toggleDistrict(district);
        await ProgressService.setCompletedFruitIds({'FR001'});
        await ProgressService.toggleChallengeItem(stateKey, state);
        expect(await ProgressService.getCompletedExperienceIds(), {experience});
        expect(await ProgressService.getCompletedDistrictIds(), {district});
        expect(await ProgressService.getCompletedFruitIds(), {'FR001'});
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('completed_experience_ids'), [experience]);
        expect(prefs.getStringList('completed_district_ids'), [district]);
        expect(prefs.getStringList('completed_fruit_ids'), ['FR001']);
        await ProgressService.toggleChallengeItem(stateKey, state);
        expect(await ProgressService.getCompletedExperienceIds(), {experience});
        await ProgressService.toggleDistrict(district);
        expect(await ProgressService.getCompletedExperienceIds(), {experience});
        await ProgressService.toggleExperience(experience);
      }
    },
  );

  test('registered catalogues have globally unique IDs and bundled assets', () {
    final ids = <String>{};
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final asset
        in readJson('assets/data/experience_sources.json')['assets'] as List) {
      expect(pubspec, contains('    - $asset'));
      for (final experience
          in readJson(asset as String)['experiences'] as List) {
        expect(
          ids.add(experience['id'] as String),
          isTrue,
          reason: experience['id'] as String,
        );
      }
    }
    for (final asset
        in (readJson('assets/data/state_exploration/index.json')['states']
                as Map)
            .values) {
      final config = readJson(asset as String);
      for (final key in [
        'district_asset',
        'experience_asset',
        'collections_asset',
      ]) {
        if (config[key] == null) continue;
        expect(File(config[key] as String).existsSync(), isTrue);
        expect(pubspec, contains('    - ${config[key]}'));
      }
    }
    expect(
      (readJson('assets/data/goa_districts.json')['districts'] as List)
          .map((d) => d['name'])
          .toSet(),
      {'North Goa', 'South Goa', 'Kushavati'},
    );
  });

  test('five northern catalogues keep district and experience completion canonical', () async {
    SharedPreferences.setMockInitialValues({});
    const stateProgressKey = 'completed_india_state_ut_ids';
    const districts = {
      'district_uttarakhand_almora',
      'district_himachal_pradesh_bilaspur',
      'district_jammu_kashmir_anantnag',
      'district_ladakh_leh',
      'district_chandigarh_chandigarh',
    };
    const experiences = {
      'exp_uttarakhand_badrinath_temple',
      'exp_himachal_pradesh_kangra_fort',
      'exp_jammu_kashmir_shalimar_bagh',
      'exp_ladakh_leh_palace',
      'exp_chandigarh_capitol_complex',
    };

    for (final districtId in districts) {
      await ProgressService.toggleDistrict(districtId);
    }
    for (final experienceId in experiences) {
      await ProgressService.toggleExperience(experienceId);
    }

    expect(await ProgressService.getCompletedDistrictIds(), districts);
    expect(await ProgressService.getCompletedExperienceIds(), experiences);
    expect(
      await ProgressService.getChallengeItemIds(stateProgressKey),
      isEmpty,
    );
    expect(await ProgressService.getCompletedFruitIds(), isEmpty);
  });

  test('new State catalogues share canonical completion stores independently of visited status', () async {
    SharedPreferences.setMockInitialValues({});
    const stateProgressKey = 'completed_india_state_ut_ids';
    const districts = {
      'district_delhi_central',
      'district_haryana_ambala',
      'district_punjab_amritsar',
    };
    const experiences = {
      'exp_delhi_red_fort',
      'exp_haryana_brahma_sarovar',
      'exp_punjab_golden_temple',
    };

    for (final districtId in districts) {
      await ProgressService.toggleDistrict(districtId);
    }
    for (final experienceId in experiences) {
      await ProgressService.toggleExperience(experienceId);
    }

    expect(await ProgressService.getCompletedDistrictIds(), districts);
    expect(await ProgressService.getCompletedExperienceIds(), experiences);
    expect(
      await ProgressService.getChallengeItemIds(stateProgressKey),
      isEmpty,
    );
  });

  test(
    'Uttar Pradesh completion stores remain canonical and independent',
    () async {
      SharedPreferences.setMockInitialValues({});
      const stateProgressKey = 'completed_india_state_ut_ids';
      const districtId = 'district_uttar_pradesh_agra';
      const experienceId = 'exp_uttar_pradesh_taj_mahal';

      await ProgressService.toggleDistrict(districtId);
      expect(await ProgressService.getCompletedDistrictIds(), {districtId});
      expect(
        await ProgressService.getChallengeItemIds(stateProgressKey),
        isEmpty,
      );

      await ProgressService.toggleExperience(experienceId);
      expect(await ProgressService.getCompletedExperienceIds(), {experienceId});
      expect(
        await ProgressService.getChallengeItemIds(stateProgressKey),
        isEmpty,
      );

      await ProgressService.setCompletedFruitIds({'FR001'});
      expect(await ProgressService.getCompletedFruitIds(), {'FR001'});
      expect(await ProgressService.getCompletedExperienceIds(), {experienceId});

      await ProgressService.toggleChallengeItem(
        stateProgressKey,
        'uttar_pradesh',
      );
      expect(await ProgressService.getChallengeItemIds(stateProgressKey), {
        'uttar_pradesh',
      });
      expect(await ProgressService.getCompletedDistrictIds(), {districtId});
      expect(await ProgressService.getCompletedExperienceIds(), {experienceId});
      expect(await ProgressService.getCompletedFruitIds(), {'FR001'});
    },
  );

  testWidgets('an empty fixture still uses the generic collection page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // All real contexts are populated; retain empty-state coverage with a fixture.
    final emptyCollections =
        readJson('assets/data/lakshadweep_collections.json')['collections']
            as List;
    for (final collection in emptyCollections) {
      collection['member_entity_ids'] = <String>[];
    }
    installAssets(
      tester,
      overrides: {
        'assets/data/state_exploration/lakshadweep.json': {
          'state_id': 'lakshadweep',
          'state_name': 'Lakshadweep',
          'collections': emptyCollections,
        },
      },
    );
    StateExplorationRepository.clearCacheForTesting();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final challenges =
        readJson('assets/data/challenges.json')['challenges'] as List;
    final challenge = challenges
        .map((entry) => Challenge.fromJson(entry as Map<String, dynamic>))
        .firstWhere((item) => item.id == 'explore_indian_states');
    final states =
        readJson('assets/data/india_states_uts.json')['items'] as List;
    final lakshadweep = states
        .map((entry) => Item.fromJson(entry as Map<String, dynamic>))
        .firstWhere((item) => item.id == 'lakshadweep');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChecklistItemDetailsPage(challenge: challenge, item: lakshadweep),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -620));
    await tester.pumpAndSettle();

    expect(find.text('EXPLORE LAKSHADWEEP'), findsOneWidget);
    expect(find.textContaining('0 of 0'), findsNothing);
    expect(find.text('0 / 0'), findsNothing);
    expect(find.byType(CircularProgressWidget), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Things to Do').hitTestable(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Things to Do'));
    await tester.pumpAndSettle();
    expect(find.text('Landmarks & Heritage'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nature & Wildlife'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nature & Wildlife'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Things to Do').hitTestable(),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Things to Do'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Food & Drink').hitTestable(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Fruits'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fruits'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dishes'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dishes'), findsOneWidget);
    for (
      var attempt = 0;
      attempt < 4 && find.text('Drinks').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    expect(find.text('Drinks'), findsOneWidget);
  });
}
