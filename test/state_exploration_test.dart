import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/experience/experience_details_page.dart';
import 'package:fruit_atlas/screens/experience/experience_collection_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/services/experience_repository.dart';
import 'package:fruit_atlas/services/experience_collection_repository.dart';
import 'package:fruit_atlas/services/district_repository.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  void installAssetHandler(WidgetTester tester) {
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
  }

  test('Rajasthan dataset has stable, reusable canonical experiences', () {
    final experiences =
        readJson('assets/data/rajasthan_experiences.json')['experiences']
            as List;
    expect(experiences, hasLength(78));
    expect(experiences.map((item) => item['id']).toSet(), hasLength(78));
    expect(experiences.map((item) => item['section']).toSet(), {
      'Places',
      'Things to Do',
      'Food & Drink',
      'Culture',
    });
    expect(
      experiences.every((item) => item['state_id'] == 'rajasthan'),
      isTrue,
    );
    expect(
      experiences.every((item) => (item['id'] as String).startsWith('exp_')),
      isTrue,
    );
    expect(
      experiences.any((item) => item['id'] == 'exp_rajasthan_dal_baati_churma'),
      isTrue,
    );
  });

  test('Rajasthan has the current 41 districts and verified fruit links', () {
    final districts =
        readJson('assets/data/rajasthan_districts.json')['districts'] as List;
    expect(districts, hasLength(41));
    expect(districts.map((item) => item['id']).toSet(), hasLength(41));
    expect(
      districts.map((item) => item['name']),
      containsAll(['Jaipur', 'Jodhpur', 'Udaipur', 'Bikaner']),
    );

    final fruitData = readJson('assets/data/fruit_atlas_seed.json');
    final states = fruitData['states'] as List;
    final rajasthanId = states.firstWhere(
      (state) => state['name'] == 'Rajasthan',
    )['id'];
    final fruits = fruitData['fruits'] as List;
    final associated = fruits
        .where(
          (fruit) => (fruit['states'] as List).any(
            (state) => state['state_id'] == rajasthanId,
          ),
        )
        .map((fruit) => fruit['name'])
        .toSet();
    expect(associated, {'Mango', 'Grapes', 'Pomegranate', 'Olive'});
  });

  testWidgets('visited state and completed experiences remain independent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'completed_experience_ids': ['exp_rajasthan_dal_baati_churma'],
    });
    ExperienceRepository.clearCacheForTesting();
    ExperienceCollectionRepository.clearCacheForTesting();
    DistrictRepository.clearCacheForTesting();
    installAssetHandler(tester);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      ),
    );
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
    final rajasthan = states
        .map((entry) => Item.fromJson(entry as Map<String, dynamic>))
        .firstWhere((item) => item.id == 'rajasthan');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChecklistItemDetailsPage(challenge: challenge, item: rajasthan),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mark as Visited'), findsOneWidget);
    expect(find.text('EXPLORE RAJASTHAN'), findsOneWidget);
    expect(find.text('1 of 119'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Places'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 / 41'), findsOneWidget);

    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Ajmer')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    final ajmerTile = find.ancestor(
      of: find.text('Ajmer'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: ajmerTile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('completed_district_ids'), [
      'district_rajasthan_ajmer',
    ]);
    expect(prefs.getStringList('completed_india_state_ut_ids'), isNull);
    expect(find.text('1 / 41'), findsOneWidget);
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Things to Do'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Things to Do'));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Landmarks & Heritage')),
      alignment: .35,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Landmarks & Heritage'));
    await tester.pumpAndSettle();
    expect(find.byType(ExperienceCollectionPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mehrangarh Fort'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final mehrangarhTile = find.ancestor(
      of: find.text('Mehrangarh Fort'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: mehrangarhTile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();

    expect(prefs.getStringList('completed_experience_ids')?.toSet(), {
      'exp_rajasthan_dal_baati_churma',
      'exp_rajasthan_mehrangarh_fort',
    });
    expect(prefs.getStringList('completed_india_state_ut_ids'), isNull);

    await tester.tap(find.text('Mehrangarh Fort'));
    await tester.pumpAndSettle();
    expect(find.byType(ExperienceDetailsPage), findsOneWidget);
    expect(find.text('Place · Jodhpur, Rajasthan'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Part of'), findsOneWidget);
    expect(find.text('Explore Rajasthan'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Culture'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Culture'));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Arts & Crafts')),
      alignment: .35,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Arts & Crafts'), findsOneWidget);
    expect(find.text('Festivals & Fairs'), findsOneWidget);
    expect(find.text('Music & Dance'), findsOneWidget);
    await tester.tap(find.text('Arts & Crafts'));
    await tester.pumpAndSettle();
    expect(find.byType(ExperienceCollectionPage), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        home: const MyLifePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Experiences completed'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });
}
