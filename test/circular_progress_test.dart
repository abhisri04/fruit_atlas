import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/widgets/circular_progress_widget.dart';
import 'package:fruit_atlas/widgets/compact_progress.dart';

void main() {
  testWidgets('Ring handles empty, complete, invalid and changing progress', (
    tester,
  ) async {
    for (final entry in <double, String>{
      0: '0%',
      1: '100%',
      .24: '24%',
      double.nan: '0%',
      2: '100%',
      -1: '0%',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CircularProgressWidget(progress: entry.key)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, inInclusiveRange(0, 1));
      expect(ring.backgroundColor, isNotNull);
      expect(ring.backgroundColor, isNot(Colors.transparent));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CompactProgress(completed: 0, total: 0)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
