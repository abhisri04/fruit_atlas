import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/fruit.dart';
import 'package:fruit_atlas/models/fruit_identity.dart';
import 'package:fruit_atlas/models/search_result.dart';
import 'package:fruit_atlas/services/fruit_search.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/widgets/fruit_image.dart';
import 'package:fruit_atlas/widgets/search_result_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final raw = jsonDecode(
    File('assets/data/fruit_atlas_seed.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final atlas = FruitAtlasData.fromJson(raw);
  final fruits = atlas.fruits;
  String normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  test(
    'catalogue preserves canonical IDs and resolves every legacy duplicate',
    () {
      expect(fruits, hasLength(115));
      expect(raw['fruit_count'], 115);
      expect(raw['variety_count'], 54);
      expect(raw['state_count'], 36);
      expect(fruits.map((fruit) => fruit.id).toSet(), hasLength(115));
      expect(raw['legacy_id_redirects'], FruitIdentity.legacyIdRedirects);
      for (var i = 1; i <= 100; i++) {
        final legacyId = 'FR${i.toString().padLeft(3, '0')}';
        if (FruitIdentity.legacyIdRedirects.containsKey(legacyId)) {
          expect(
            fruits.any((fruit) => fruit.id == legacyId),
            isFalse,
            reason: legacyId,
          );
          expect(
            fruits.any(
              (fruit) => fruit.id == FruitIdentity.canonicalId(legacyId),
            ),
            isTrue,
            reason: legacyId,
          );
        } else {
          expect(fruits.any((fruit) => fruit.id == legacyId), isTrue);
        }
      }
      expect(fruits.skip(110).map((fruit) => fruit.id).toList(), [
        'FR121',
        'FR122',
        'FR123',
        'FR124',
        'FR125',
      ]);
    },
  );

  test('names, aliases, varieties, states and image paths stay canonical', () {
    final nameOwners = <String, String>{};
    final varietyIds = <String>{};
    final varietyNames = <String>{};
    final stateIds = atlas.states.map((state) => state.id).toSet();
    final imagePaths = <String>{};
    var labelCount = 0;
    for (final fruit in fruits) {
      expect(fruit.shortDescription, isNotEmpty, reason: fruit.id);
      expect(fruit.tags, isNotEmpty, reason: fruit.id);
      expect(fruit.imageAsset, 'assets/images/fruits/${fruit.id}.webp');
      expect(imagePaths.add(fruit.imageAsset), isTrue, reason: fruit.id);
      expect(
        ['source_verified', 'legacy_review_needed'],
        contains(fruit.researchStatus),
        reason: fruit.id,
      );
      for (final label in [fruit.name, ...fruit.aliases]) {
        labelCount++;
        final key = normalized(label);
        expect(key, isNotEmpty, reason: fruit.id);
        expect(nameOwners.containsKey(key), isFalse, reason: label);
        nameOwners[key] = fruit.id;
      }
      final withinFruit = <String>{};
      for (final variety in fruit.varieties) {
        expect(variety.id, isNotNull);
        expect(varietyIds.add(variety.id!), isTrue, reason: variety.name);
        expect(
          varietyNames.add(normalized(variety.name)),
          isTrue,
          reason: variety.name,
        );
        expect(
          withinFruit.add(normalized(variety.name)),
          isTrue,
          reason: '${fruit.id}: ${variety.name}',
        );
      }
      for (final state in fruit.states) {
        expect(stateIds, contains(state.stateId), reason: fruit.id);
        expect(state.status, isNotEmpty, reason: fruit.id);
        expect(state.evidence, isNotEmpty, reason: fruit.id);
        expect(state.dataYear, isNotEmpty, reason: fruit.id);
      }
    }
    expect(varietyIds, hasLength(54));
    expect(nameOwners, hasLength(labelCount));
    expect(
      fruits.map((fruit) => normalized(fruit.scientificName)).toSet(),
      hasLength(115),
    );
    expect(
      (raw['verified_fruit_state_link_count'] as int),
      fruits.fold<int>(0, (sum, fruit) => sum + fruit.states.length),
    );
    final directory = Directory('assets/images/fruits');
    expect(directory.existsSync(), isTrue);
    final actualImages = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    expect(
      actualImages.difference(
        fruits.map((fruit) => '${fruit.id}.webp').toSet(),
      ),
      isEmpty,
    );
  });

  test('photo manifest has exactly one unsourced row per active fruit', () {
    final lines = File('docs/image_sources/fruit_photo_manifest.csv')
        .readAsLinesSync()
        .where((line) => line.isNotEmpty)
        .toList();
    expect(lines, hasLength(fruits.length + 1));
    expect(
      lines.first,
      'fruit_id,fruit_name,scientific_name,image_asset,source_platform,'
      'source_page_url,original_image_url,photographer_or_creator,license,'
      'license_url,attribution_required,attribution_text,date_accessed,'
      'commercial_use_verified,modification_allowed,verification_notes,'
      'source_file_sha256,asset_file_sha256,approval_status',
    );
    final rows = lines.skip(1).map((line) => line.split(',')).toList();
    expect(rows.every((row) => row.length == 19), isTrue);
    expect(
      rows.map((row) => row[0]).toSet(),
      fruits.map((fruit) => fruit.id).toSet(),
    );
    for (final row in rows) {
      final fruit = fruits.singleWhere((item) => item.id == row[0]);
      expect(row.take(4).toList(), [
        fruit.id,
        fruit.name,
        fruit.scientificName,
        fruit.imageAsset,
      ]);
      expect(row.skip(4).every((cell) => cell.isEmpty), isTrue);
    }
  });

  test('approved additions keep species identities and source evidence', () {
    const approved = {
      'FR121': ('Ramphal', 'Annona reticulata'),
      'FR122': ('Jungle Jalebi', 'Pithecellobium dulce'),
      'FR123': ('Malabar Tamarind', 'Garcinia gummi-gutta'),
      'FR124': ('Bor Thekera', 'Garcinia pedunculata'),
      'FR125': ('Monkey Jack', 'Artocarpus lakoocha'),
    };
    for (final entry in approved.entries) {
      final fruit = fruits.singleWhere((item) => item.id == entry.key);
      expect(fruit.name, entry.value.$1);
      expect(fruit.scientificName, entry.value.$2);
      expect(fruit.sourceRefs, isNotEmpty);
      expect(fruit.states, isNotEmpty);
      expect(fruit.varieties, isEmpty);
      expect(fruit.researchStatus, 'source_verified');
    }
    expect(
      fruits.singleWhere((fruit) => fruit.id == 'FR099').scientificName,
      'Diospyros nigra',
    );
  });

  test('search finds canonical fruits through legacy aliases', () {
    final chikoo = fruits.singleWhere((fruit) => fruit.id == 'FR006');
    final aonla = fruits.singleWhere((fruit) => fruit.id == 'FR009');
    final mandarin = fruits.singleWhere((fruit) => fruit.id == 'FR049');
    expect(filterFruits(fruits, query: 'Chikoo'), contains(chikoo));
    expect(filterFruits(fruits, query: 'Amla'), contains(aonla));
    expect(filterFruits(fruits, query: 'Kinnow'), contains(mandarin));
    expect(filterFruits(fruits, query: 'Indian Gooseberry'), [aonla]);
    expect(filterFruits(fruits, query: 'sohiong', stateId: 'ML'), [
      fruits.singleWhere((fruit) => fruit.id == 'FR102'),
    ]);
  });

  test('retired IDs migrate completion and Saved references', () async {
    SharedPreferences.setMockInitialValues({
      'completed_fruit_ids': ['FR089', 'FR009', 'FR075', 'FR081'],
      'saved_entity_references': ['fruit:FR090', 'fruit:FR006', 'fruit:FR062'],
    });
    expect(await ProgressService.getCompletedFruitIds(), {
      'FR009',
      'FR074',
      'FR049',
    });
    expect(await ProgressService.getSavedEntityReferences(), {
      'fruit:FR006',
      'fruit:FR009',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('completed_fruit_ids')?.toSet(), {
      'FR009',
      'FR074',
      'FR049',
    });
    expect(prefs.getStringList('saved_entity_references')?.toSet(), {
      'fruit:FR006',
      'fruit:FR009',
    });
    await ProgressService.setCompletedFruitIds({'FR046', 'FR016'});
    expect(await ProgressService.getCompletedFruitIds(), {'FR016'});
    expect(await ProgressService.isEntitySaved('fruit:FR090'), isTrue);
  });

  testWidgets('missing canonical image uses the shared fruit placeholder', (
    tester,
  ) async {
    final mango = fruits.singleWhere((fruit) => fruit.id == 'FR001');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FruitImage(fruit: mango, width: 100, height: 100)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a corrupt local image also falls back cleanly', (tester) async {
    final mango = fruits.singleWhere((fruit) => fruit.id == 'FR001');
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final path = utf8.decode(message!.buffer.asUint8List());
        return path == mango.imageAsset ? ByteData(3) : null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FruitImage(fruit: mango, width: 100, height: 100)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fruit and variety search rows share the parent image asset', (
    tester,
  ) async {
    final mango = fruits.singleWhere((fruit) => fruit.id == 'FR001');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchResultTile(
                result: SearchResult(
                  id: 'fruit:FR001',
                  entityType: SearchEntityType.item,
                  title: mango.name,
                  subtitle: 'Fruit',
                  categoryId: 'food_drink',
                  destination: mango,
                ),
                onTap: () {},
              ),
              SearchResultTile(
                result: SearchResult(
                  id: 'variety:VAR001',
                  entityType: SearchEntityType.subItem,
                  title: mango.varieties.first.name,
                  subtitle: 'Variety',
                  categoryId: 'food_drink',
                  destination: mango.varieties.first,
                  parent: mango,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<FruitImage>(find.byType(FruitImage))
          .map((image) => image.fruit.canonicalImageAsset)
          .toList(),
      [mango.imageAsset, mango.imageAsset],
    );
    expect(find.byType(FruitImage), findsNWidgets(2));
  });
}
