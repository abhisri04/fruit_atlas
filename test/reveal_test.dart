import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/widgets/reveal.dart';

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(of: find.byType(Reveal), matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  testWidgets('fades in after its stagger delay and settles fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Reveal(index: 3, child: Text('Hello'))),
    );
    expect(_opacity(tester), 0);
    // Still inside the 3 × 55 ms stagger.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('shows immediately when reduce motion is on', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Reveal(index: 5, child: Text('Hello')),
        ),
      ),
    );
    await tester.pump();
    expect(_opacity(tester), 1);
  });
}
