// Run with flutter test test/ui_preview_test.dart to refresh local review images.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/app/app.dart';
import 'package:fruit_atlas/screens/challenge/fruit_challenge_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';

void main() {
  testWidgets('Render local phone previews', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    // Optional system fonts improve local review; production fonts are unchanged.
    for (final font in {
      'Ahem':
          'C:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      'Roboto':
          'C:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      'MaterialIcons': 'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      'Georgia': 'C:/Windows/Fonts/georgia.ttf',
    }.entries) {
      final file = File(font.value);
      if (file.existsSync()) {
        final loader = FontLoader(font.key)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
      }
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    Future<void> capture(String name, Widget page) async {
      await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: page));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('build/ui_review')
          ..createSync(recursive: true);
        File('${folder.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('home', const FruitAtlasApp());
    final challenges = await const AssetDataService().loadChallenges();
    await capture(
      'fruit_challenge',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FruitChallengePage(
          challenge: challenges.firstWhere((c) => c.itemType == 'fruit'),
        ),
      ),
    );
    await capture(
      'my_life',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MyLifePage(),
      ),
    );
  });
}
