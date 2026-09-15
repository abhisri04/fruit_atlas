import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/search_result.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/screens/search/discovery_search_page.dart';
import 'package:fruit_atlas/screens/discover/category_details_page.dart';
import 'package:fruit_atlas/screens/district/district_details_page.dart';
import 'package:fruit_atlas/screens/experience/experience_details_page.dart';
import 'package:fruit_atlas/screens/challenge/generic_checklist_challenge_page.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/fruit/fruit_details_page.dart';
import 'package:fruit_atlas/screens/fruit/variety_details_page.dart';
import 'package:fruit_atlas/screens/jyotirlinga/jyotirlinga_details_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';

void main() {
  testWidgets(
    'Global search ranks real entities, aliases and navigates every result type',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          final name = utf8.decode(message!.buffer.asUint8List());
          if (name == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage(
              <String, Object>{},
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
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = GlobalSearchService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DiscoverySearchPage(service: service),
        ),
      );
      await tester.pumpAndSettle();
      const expected = {
        'Mango': ['Mango', 'Alphonso', 'Taste All Fruits of India'],
        'Alphonso': ['Alphonso', 'Mango', 'Taste All Fruits of India'],
        'Fruit': ['Taste All Fruits of India', 'Breadfruit'],
        'Food': ['Food & Drink', 'Taste All Fruits of India'],
        'Temple': [
          'Faith & Pilgrimage',
          'Visit All 12 Jyotirlingas',
          'Somnath',
        ],
        'Shiva': ['Visit All 12 Jyotirlingas', 'Somnath'],
        'Jyotirlinga': ['Visit All 12 Jyotirlingas', 'Somnath'],
        'Fitness': ['Fitness & Wellness', 'Learn 30 Yoga Poses'],
        'Yoga': ['Learn 30 Yoga Poses', 'Tree Pose'],
        'Wellness': ['Fitness & Wellness', 'Learn 30 Yoga Poses'],
        'Dashehari': ['Dashehari', 'Mango'],
        'Mangifera indica': ['Mango'],
        'Pushkar Fair': ['Pushkar Fair'],
        'Blue Pottery': ['Blue Pottery'],
        'Dal Baati': ['Dal Baati Churma'],
      };
      for (final entry in expected.entries) {
        final matches = service.search(entry.key);
        expect(
          matches.map((r) => r.title),
          containsAll(entry.value),
          reason: entry.key,
        );
        expect(matches.map((r) => r.id).toSet().length, matches.length);
        expect(
          service.search('  ${entry.key.toUpperCase()}  ').map((r) => r.id),
          matches.map((r) => r.id),
        );
        expect(matches.every((r) => r.subtitle.isNotEmpty), isTrue);
      }
      expect(service.search('Mango').first.title, 'Mango');
      final mangoTitles = service.search('Mango').map((r) => r.title).toList();
      expect(mangoTitles[1], 'Taste All Fruits of India');
      expect(
        mangoTitles.indexOf('Alphonso'),
        lessThan(mangoTitles.indexOf('Mangosteen')),
      );
      expect(
        mangoTitles.indexOf('Taste All Fruits of India'),
        lessThan(mangoTitles.indexOf('Mango Plum')),
      );
      expect(
        mangoTitles.indexOf('Taste All Fruits of India'),
        lessThan(mangoTitles.indexOf('Mangosteen')),
      );
      expect(mangoTitles.take(10), contains('Taste All Fruits of India'));
      expect(service.search('m'), isEmpty);
      expect(service.search('ma').length, lessThanOrEqualTo(8));
      expect(
        service
            .search('ma')
            .every((r) => r.title.toLowerCase().startsWith('ma')),
        isTrue,
      );
      expect(service.search('').length, lessThanOrEqualTo(12));
      expect(service.search('fruit').length, lessThanOrEqualTo(60));
      expect(
        service.search('Alphonso').first.entityType,
        SearchEntityType.subItem,
      );
      expect(service.search('nothing-matches-123'), isEmpty);
      for (final entry in <String, Type>{
        'Mango': FruitDetailsPage,
        'Alphonso': VarietyDetailsPage,
        'Somnath': JyotirlingaDetailsPage,
        'Tree Pose': ChecklistItemDetailsPage,
        'Learn 30 Yoga Poses': GenericChecklistChallengePage,
        'Food & Drink': CategoryDetailsPage,
        'Bikaner': DistrictDetailsPage,
        'Mehrangarh Fort': ExperienceDetailsPage,
        'Pushkar Fair': ExperienceDetailsPage,
        'Blue Pottery': ExperienceDetailsPage,
      }.entries) {
        await tester.enterText(find.byType(TextField), entry.key);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, entry.key));
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Explore categories and challenges'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
