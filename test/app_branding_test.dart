import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/app/app.dart';
import 'package:fruit_atlas/models/app_branding.dart';
import 'package:fruit_atlas/models/book.dart';
import 'package:fruit_atlas/models/share_branding_config.dart';

void main() {
  test('canonical branding is shared by visual and book share defaults', () {
    expect(AppBranding.appName, 'UPLYFA');
    expect(AppBranding.tagline, 'Experience more.');
    const branding = ShareBrandingConfig();
    expect(branding.appName, AppBranding.appName);
    expect(branding.tagline, AppBranding.tagline);
    const payload = BookSharePayload(
      title: 'Books',
      subtitle: 'A reading journey',
      progressCurrent: 1,
      shareText: 'Read one book',
      collectionType: 'genre',
    );
    expect(payload.appBranding, AppBranding.appName);
  });

  testWidgets('Flutter application title is the canonical product name', (
    tester,
  ) async {
    late MaterialApp app;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          app = const FruitAtlasApp().build(context) as MaterialApp;
          return const SizedBox();
        },
      ),
    );
    expect(app.title, 'UPLYFA');
  });

  test('installed labels and web metadata mirror the canonical branding; package ID stays stable', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(
      File('android/app/src/main/res/values/strings.xml').readAsStringSync(),
      contains('<string name="app_name">${AppBranding.appName}</string>'),
    );
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('applicationId = "com.example.fruit_atlas"'),
    );
    final web = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(web['name'], AppBranding.appName);
    expect(web['short_name'], AppBranding.appName);
    expect(web['description'], AppBranding.tagline);
    expect(
      File('web/index.html').readAsStringSync(),
      contains('<title>${AppBranding.appName}</title>'),
    );
    for (final path in ['ios/Runner/Info.plist', 'macos/Runner/Info.plist']) {
      expect(
        File(path).readAsStringSync(),
        contains(
          '<key>CFBundleDisplayName</key>\n\t<string>${AppBranding.appName}</string>',
        ),
      );
    }
    expect(
      File('windows/runner/main.cpp').readAsStringSync(),
      contains('window.Create(L"${AppBranding.appName}"'),
    );
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      contains('gtk_window_set_title(window, "${AppBranding.appName}")'),
    );
    expect(
      File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync(),
      contains('About ${AppBranding.appName}'),
    );
  });

  test('shipped Dart copy and catalogue descriptions contain no retired product branding', () {
    final retired = RegExp(
      r'Fruit Atlas(?: India)?|APP NAME|APP_NAME|Real Experiences\. A Richer You\.|Namaste, Explorer',
      caseSensitive: false,
    );
    for (final root in ['lib', 'assets/data']) {
      for (final file
          in Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) =>
                    file.path.endsWith('.dart') || file.path.endsWith('.json'),
              )) {
        expect(
          retired.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: 'Retired branding in ${file.path}',
        );
      }
    }
    // Technical compatibility names and category labels deliberately remain.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('name: fruit_atlas'),
    );
    expect(File('assets/data/fruit_atlas_seed.json').existsSync(), isTrue);
    expect(
      File('assets/data/categories.json').readAsStringSync(),
      contains('Life Experiences'),
    );
  });
}
