import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Daily Discovery selection and persistence rules', (
    tester,
  ) async {
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

    SharedPreferences.setMockInitialValues({
      'completed_fruit_ids': ['FR001'],
      'completed_variety_ids': ['VAR001'],
      'completed_yoga_pose_ids': ['mountain_pose'],
    });
    var date = DateTime(2026, 9, 16, 8);
    final service = DailyDiscoveryService(now: () => date);
    final pool = (await tester.runAsync(service.buildEligiblePool))!;

    expect(pool.map((item) => item.type).toSet(), {
      DailyDiscoveryType.fruit,
      DailyDiscoveryType.variety,
      DailyDiscoveryType.yogaPose,
      DailyDiscoveryType.indianDish,
      DailyDiscoveryType.indianDrink,
      DailyDiscoveryType.indiaLocation,
      DailyDiscoveryType.jyotirlinga,
    });
    expect(pool.every((item) => !item.locationRequired), isTrue);
    expect(pool.map((item) => item.reference), isNot(contains('fruit:FR001')));
    expect(
      pool.map((item) => item.reference),
      isNot(contains('variety:VAR001')),
    );
    expect(
      pool.map((item) => item.reference),
      isNot(contains('yogaPose:mountain_pose')),
    );
    final yogaRecommendations = pool.where(
      (item) => item.type == DailyDiscoveryType.yogaPose,
    );
    expect(yogaRecommendations, isNotEmpty);
    expect(
      yogaRecommendations.every(
        (item) => const {
          'Beginner',
          'Intermediate',
        }.contains(item.yogaPose?.difficulty),
      ),
      isTrue,
    );

    SharedPreferences.setMockInitialValues({});
    final first = await tester.runAsync(service.getToday);
    expect(
      (await tester.runAsync(service.getToday))?.reference,
      first?.reference,
    );
    final second = await tester.runAsync(service.another);
    final third = await tester.runAsync(service.another);
    expect({
      first?.reference,
      second?.reference,
      third?.reference,
    }, hasLength(3));
    expect(
      (await tester.runAsync(service.getToday))?.reference,
      third?.reference,
    );

    date = DateTime(2026, 9, 17, 0, 1);
    final nextDay = await tester.runAsync(service.getToday);
    expect(nextDay, isNotNull);
    expect(nextDay!.reference, isNot(third!.reference));

    final preferences = await SharedPreferences.getInstance();
    switch (nextDay.type) {
      case DailyDiscoveryType.fruit:
        await preferences.setStringList('completed_fruit_ids', [
          nextDay.canonicalId,
        ]);
      case DailyDiscoveryType.variety:
        await preferences.setStringList('completed_variety_ids', [
          nextDay.canonicalId,
        ]);
      case DailyDiscoveryType.yogaPose:
        await preferences.setStringList('completed_yoga_pose_ids', [
          nextDay.canonicalId,
        ]);
      case DailyDiscoveryType.indianDish:
        await ProgressService.toggleCategoryItemAction(
          categoryId: 'CAT_INDIAN_DISHES',
          itemId: nextDay.canonicalId,
          action: 'tried',
        );
      case DailyDiscoveryType.indianDrink:
        await ProgressService.toggleCategoryItemAction(
          categoryId: 'CAT_INDIAN_DRINKS',
          itemId: nextDay.canonicalId,
          action: 'tried',
        );
      case DailyDiscoveryType.indiaLocation:
        await preferences.setStringList('completed_india_state_ut_ids', [
          nextDay.canonicalId,
        ]);
      case DailyDiscoveryType.jyotirlinga:
        await preferences.setStringList('completed_jyotirlinga_ids', [
          nextDay.canonicalId,
        ]);
    }
    final replacement = await tester.runAsync(service.getToday);
    expect(replacement, isNotNull);
    expect(replacement!.reference, isNot(nextDay.reference));

    final fruitData = jsonDecode(
      File('assets/data/fruit_atlas_seed.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final fruits = fruitData['fruits'] as List;
    final yoga =
        (jsonDecode(File('assets/data/yoga_poses.json').readAsStringSync())
                as Map<String, dynamic>)['items']
            as List;
    SharedPreferences.setMockInitialValues({
      'completed_fruit_ids': fruits
          .map((item) => item['id'] as String)
          .toList(),
      'completed_variety_ids': fruits
          .expand((item) => item['varieties'] as List)
          .map((item) => item['id'] as String)
          .toList(),
      'completed_yoga_pose_ids': yoga
          .map((item) => item['id'] as String)
          .toList(),
    });
    final remaining = (await tester.runAsync(service.buildEligiblePool))!;
    expect(
      remaining.any((item) => item.type == DailyDiscoveryType.fruit),
      isFalse,
    );
    expect(
      remaining.any((item) => item.type == DailyDiscoveryType.yogaPose),
      isFalse,
    );
  });
}
