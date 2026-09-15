import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/challenge_card.dart';
import 'package:fruit_atlas/widgets/empty_state.dart';
import 'package:fruit_atlas/widgets/progress_card.dart';
import 'package:fruit_atlas/widgets/data_notice.dart';

void main() {
  testWidgets('Shared cards fit a narrow phone with enlarged text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const challenge = Challenge(
      id: 'test',
      categoryId: 'travel_exploration',
      name: 'A long challenge title for a lifetime of exploration',
      description:
          'Discover places and experiences across India at your own pace.',
      itemType: 'state',
      totalItems: 36,
      hasSubItems: false,
      status: 'active',
      presentationType: 'checklist',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ChallengeCard(
                    challenge: challenge,
                    isActive: true,
                    completedCount: 12,
                  ),
                  const ProgressCard(
                    title: 'Varieties explored',
                    summary: '17 / 100 varieties explored',
                    progress: .17,
                  ),
                  const DataNotice(
                    kind: NoticeKind.caution,
                    message: 'Variety-specific growing regions have not been verified.',
                  ),
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No fruits found',
                    message: 'Try another fruit or variety.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Save challenge'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from Saved'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('saved_challenge_ids'), ['test']);
    expect(tester.takeException(), isNull);
  });
}
