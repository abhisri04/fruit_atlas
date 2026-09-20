import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/fruit.dart';
import 'package:fruit_atlas/screens/fruit/variety_details_page.dart';
import 'package:fruit_atlas/screens/home/home_page.dart';
import 'package:fruit_atlas/screens/saved/saved_page.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/fruit_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDailyDiscoveryService extends DailyDiscoveryService {
  final DailyDiscovery value;
  const _FakeDailyDiscoveryService(this.value);

  @override
  Future<DailyDiscovery?> getToday() async => value;

  @override
  Future<DailyDiscovery?> another() async => value;

  @override
  Future<List<DailyDiscovery>> buildCanonicalPool() async => [value];
}

void main() {
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
  }

  testWidgets(
    'Home discovery saves canonical reference and opens existing details',
    (tester) async {
      installAssets(tester);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const variety = FruitVariety(id: 'VAR001', name: 'Dashehari');
      const fruit = Fruit(
        id: 'FR001',
        name: 'Mango',
        scientificName: 'Mangifera indica',
        states: [],
        varieties: [variety],
      );
      const discovery = DailyDiscovery(
        type: DailyDiscoveryType.variety,
        canonicalId: 'VAR001',
        title: 'Dashehari',
        subtitle: 'Variety of Mango',
        fruit: fruit,
        variety: variety,
      );

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.light,
          home: const HomePage(
            dailyDiscoveryService: _FakeDailyDiscoveryService(discovery),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Make room for discovery'), findsNothing);
      expect(find.text('Small experiences. A richer you.'), findsNothing);
      expect(find.text('Hello, explorer'), findsOneWidget);
      expect(find.text('What will you discover today?'), findsOneWidget);
      expect(find.text("TODAY'S DISCOVERY"), findsOneWidget);
      expect(find.text('Try Dashehari'), findsOneWidget);
      expect(
        find.text('Discover another variety to add to your fruit journey.'),
        findsOneWidget,
      );
      expect(find.text('Fruit variety · Mango'), findsOneWidget);
      expect(find.text('Explore this variety →'), findsOneWidget);
      expect(find.text('Save for later'), findsOneWidget);
      expect(
        tester
            .widget<FruitImage>(find.byType(FruitImage))
            .fruit
            .canonicalImageAsset,
        'assets/images/fruits/FR001.webp',
      );
      expect(tester.getBottomRight(find.text('Explore')).dy, lessThan(844));

      await tester.tap(find.widgetWithText(TextButton, 'Save for later'));
      await tester.pumpAndSettle();
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList('saved_entity_references'), [
        'variety:VAR001',
      ]);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Explore this variety →'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VarietyDetailsPage), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.light,
          home: const SavedPage(
            dailyDiscoveryService: _FakeDailyDiscoveryService(discovery),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved discoveries'), findsOneWidget);
      expect(find.text('Dashehari'), findsOneWidget);
      expect(
        tester
            .widget<FruitImage>(find.byType(FruitImage))
            .fruit
            .canonicalImageAsset,
        'assets/images/fruits/FR001.webp',
      );
      await tester.tap(find.text('Dashehari'));
      await tester.pumpAndSettle();
      expect(find.byType(VarietyDetailsPage), findsOneWidget);
    },
  );
}
