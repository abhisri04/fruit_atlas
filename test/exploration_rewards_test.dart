import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/widgets/category_progress_ring.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const variety = 'VAR010';
  const experience = 'exp_tamil_nadu_shore_temple_at_mamallapuram';
  const district = 'district_tamil_nadu_ariyalur';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('variety, experience and district completions earn XP once', () async {
    await ProgressService.toggleVariety(variety);
    await ProgressService.toggleExperience(experience);
    await ProgressService.toggleDistrict(district);

    expect(await ProgressService.getRewardedEventIds(), {
      'completion:variety:$variety',
      'completion:experience:$experience',
      'completion:district:$district',
    });
    expect(await ProgressService.getRewardedXp(), 30);

    // Undo and redo must not award the same completion twice.
    await ProgressService.toggleExperience(experience);
    await ProgressService.toggleExperience(experience);
    expect(await ProgressService.getRewardedXp(), 30);
  });

  test('collection checklist saves record experience rewards', () async {
    await ProgressService.setCompletedExperienceIds({experience});
    expect(
      await ProgressService.getRewardedEventIds(),
      contains('completion:experience:$experience'),
    );
  });

  test(
    'summary counts exploration completions and ignores unknown ids',
    () async {
      SharedPreferences.setMockInitialValues({
        'completed_variety_ids': [variety, 'VAR_UNKNOWN'],
        'completed_experience_ids': [experience, 'exp_unknown'],
        'completed_district_ids': [district, 'district_unknown'],
      });
      final summary = await const ProgressSummaryService().load();
      expect(summary.explorationReferences, {
        'variety:$variety',
        'experience:$experience',
        'district:$district',
      });
      expect(summary.experiencesExplored, 3);
    },
  );

  test('daily quest recognises varieties and state experiences', () async {
    final now = DateTime(2026, 11, 20, 12);
    await ProgressService.recordMeaningfulCompletion(
      'variety:$variety',
      now: now,
    );
    await ProgressService.recordMeaningfulCompletion(
      'experience:$experience',
      now: now,
    );
    final summary = await const ProgressSummaryService().load();
    final gamification = await const GamificationService().load(
      summary,
      now: now,
    );
    expect(gamification.quest.tasks.every((task) => task.completed), isTrue);
  });

  testWidgets('category ring shows its icon without a percentage overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryProgressRing(
            icon: Icons.restaurant,
            label: 'Food & Drink',
            completed: 0,
            total: 823,
            accent: Colors.orange,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('0 / 823'), findsOneWidget);
  });
}
