import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/screens/scent/scent_hub_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/challenge_groups.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'scent collections collapse into one hub where the first one was',
    () async {
      final active = (await const AssetDataService().loadChallenges())
          .where((c) => c.status == 'active')
          .toList();
      final scent = active.where(isScentChallenge).toList();
      expect(scent, hasLength(4));

      final grouped = groupScentChallenges(active);
      expect(grouped.where((c) => c.categoryId == 'scent'), hasLength(1));
      expect(grouped, hasLength(active.length - 3));
      final hub = grouped.singleWhere((c) => c.id == scentHubId);
      expect(hub.compactTitle, 'Scent & Perfume');
      expect(hub.totalItems, scent.fold(0, (sum, c) => sum + c.totalItems));
      expect(grouped.indexOf(hub), active.indexOf(scent.first));
    },
  );

  test('hub progress sums the scent collections', () {
    Challenge c(String id, int total) => Challenge(
      id: id,
      categoryId: 'scent',
      name: id,
      description: '',
      itemType: 'perfume',
      totalItems: total,
      hasSubItems: false,
      status: 'active',
      presentationType: 'checklist_with_details',
    );
    final all = [c('a', 9), c('b', 58)];
    final progress = {
      'a': (completed: 2, total: 9),
      'b': (completed: 5, total: 58),
    };
    expect(groupedProgress(scentHub(all), (id) => progress[id], all), (
      completed: 7,
      total: 67,
    ));
    expect(groupedProgress(all.first, (id) => progress[id], all), (
      completed: 2,
      total: 9,
    ));
  });

  testWidgets('the hub lists every collection and My Collection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ScentHubPage()),
    );
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(find.text('Scent & Perfume'), findsWidgets);
    expect(find.text('0 of 123 smelled'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-collection-entry')), findsOneWidget);
    for (final id in [
      'explore_scent_families',
      'explore_iconic_perfumes',
      'explore_scent_notes',
      'explore_indian_attars',
    ]) {
      expect(find.byKey(ValueKey('scent-hub-$id')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
