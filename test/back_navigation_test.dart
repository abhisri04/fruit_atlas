import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'System back returns sections home and requires a second exit back',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var systemExitRequested = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') {
            systemExitRequested = true;
          }
          return null;
        },
      );
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
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(const FruitAtlasApp());
      await tester.pumpAndSettle();

      final navigation = find.byType(NavigationBar);
      for (final section in ['Discover', 'Saved', 'My Life']) {
        await tester.tap(
          find.descendant(of: navigation, matching: find.text(section)),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<NavigationBar>(navigation).selectedIndex,
          isNot(0),
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<NavigationBar>(navigation).selectedIndex, 0);
        expect(find.text('Press back again to exit Fruit Atlas'), findsNothing);
      }

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit Fruit Atlas'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemExitRequested, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
