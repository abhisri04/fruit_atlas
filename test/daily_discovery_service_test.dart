import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
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
    final pool = await service.buildEligiblePool();

    expect(pool.map((item) => item.type).toSet(), {
      DailyDiscoveryType.fruit,
      DailyDiscoveryType.variety,
      DailyDiscoveryType.yogaPose,
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

    SharedPreferences.setMockInitialValues({});
    final first = await service.getToday();
    expect((await service.getToday())?.reference, first?.reference);
    final second = await service.another();
    final third = await service.another();
    expect({
      first?.reference,
      second?.reference,
      third?.reference,
    }, hasLength(3));
    expect((await service.getToday())?.reference, third?.reference);

    date = DateTime(2026, 9, 17, 0, 1);
    final nextDay = await service.getToday();
    expect(nextDay, isNotNull);
    expect(nextDay!.reference, isNot(third!.reference));

    final preferences = await SharedPreferences.getInstance();
    final completionKey = switch (nextDay.type) {
      DailyDiscoveryType.fruit => 'completed_fruit_ids',
      DailyDiscoveryType.variety => 'completed_variety_ids',
      DailyDiscoveryType.yogaPose => 'completed_yoga_pose_ids',
    };
    await preferences.setStringList(completionKey, [nextDay.canonicalId]);
    final replacement = await service.getToday();
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
    expect(await service.getToday(), isNull);
    expect(await service.another(), isNull);
  });
}
