import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/india_location_registry.dart';
import 'package:fruit_atlas/models/india_passport_share_data.dart';
import 'package:fruit_atlas/models/share_branding_config.dart';
import 'package:fruit_atlas/models/share_highlight.dart';
import 'package:fruit_atlas/models/state_travel_status.dart';
import 'package:fruit_atlas/services/india_map_repository.dart';
import 'package:fruit_atlas/services/share_studio_service.dart';
import 'package:fruit_atlas/services/state_travel_service.dart';
import 'package:fruit_atlas/screens/share/india_passport_share_page.dart';
import 'package:fruit_atlas/theme/app_colors.dart';
import 'package:fruit_atlas/widgets/india_passport_ring.dart';
import 'package:fruit_atlas/widgets/india_passport_share_card.dart';

class RecordingShareService extends ShareStudioService {
  Uint8List? png;
  String? text;
  bool failInvocation = false;
  @override
  Future<Uint8List> renderCard(GlobalKey key) async =>
      throw StateError('render failed');
  @override
  Future<void> invokeShare({
    Uint8List? png,
    required String text,
    Rect? origin,
    String fileName = 'india-passport.png',
  }) async {
    if (failInvocation) throw StateError('share failed');
    this.png = png;
    this.text = text;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
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
        });
  });

  test(
    'precise visited-only ratio, immutable snapshots, actual colors and counts',
    () async {
      final travel = StateTravelService();
      await travel.load();
      for (final id in IndiaLocationRegistry.allLocationIds.take(13)) {
        await travel.setStatus(id, TravelStatus.visited);
      }
      await travel.setStatus('rajasthan', TravelStatus.wantToVisit);
      final before = IndiaPassportShareData(travel);
      expect(before.ratio, 13 / 36);
      expect(before.percent, 36);
      expect(before.wanted, 1);
      expect(before.notMarked, 22);
      final painter = PassportShareMapPainter([], before);
      expect(
        painter.colorFor(IndiaLocationRegistry.allLocationIds.first),
        AppColors.passportVisited,
      );
      expect(painter.colorFor('rajasthan'), AppColors.passportWanted);
      expect(painter.colorFor('sikkim'), AppColors.passportUnmarked);
      await travel.setStatus('rajasthan', TravelStatus.visited);
      final after = IndiaPassportShareData(travel);
      expect(after.visited, 14);
      expect(after.wanted, 0);
      expect(
        PassportShareMapPainter([], after).colorFor('rajasthan'),
        AppColors.passportVisited,
      );
      expect(before.wanted, 1);
      travel.dispose();
    },
  );

  testWidgets('ring opens at current ratio and animates previous to new', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: IndiaPassportRing(ratio: 13 / 36)),
    );
    expect(find.text('36%'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: IndiaPassportRing(ratio: 18 / 36)),
    );
    expect(find.text('36%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    final intermediate = tester
        .widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        )
        .value!;
    expect(intermediate, greaterThan(13 / 36));
    expect(intermediate, lessThan(.5));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
  });

  for (final format in ShareCardFormat.values) {
    testWidgets(
      '${format.name} renders full-size PNG, branding, no required name',
      (tester) async {
        late StateTravelService travel;
        late List<IndiaMapRegion> regions;
        await tester.runAsync(() async {
          for (final entry in {
            'Roboto': 'roboto-regular.ttf',
            'MaterialIcons': 'materialicons-regular.otf',
          }.entries) {
            final file = File(
              'C:/flutter/bin/cache/artifacts/material_fonts/${entry.value}',
            );
            if (file.existsSync()) {
              final loader = FontLoader(entry.key)
                ..addFont(
                  Future.value(ByteData.sublistView(file.readAsBytesSync())),
                );
              await loader.load();
            }
          }
          travel = StateTravelService();
          await travel.load();
          await travel.setStatus('rajasthan', TravelStatus.visited);
          regions = await IndiaMapRepository.load();
        });
        final key = GlobalKey();
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 360,
                child: RepaintBoundary(
                  key: key,
                  child: IndiaPassportShareCard(
                    data: IndiaPassportShareData(travel),
                    regions: regions,
                    format: format,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('UPLYFA'), findsNWidgets(2));
        expect(find.text('Experience more.'), findsOneWidget);
        await tester.runAsync(() async {
          final png = await const ShareStudioService().renderCard(key);
          final codec = await ui.instantiateImageCodec(png);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1080);
          expect(
            frame.image.height,
            format == ShareCardFormat.story ? 1920 : 1080,
          );
          final folder = Directory('build/ui_review')
            ..createSync(recursive: true);
          File('${folder.path}/passport_share_${format.name}.png')
              .writeAsBytesSync(png);
          frame.image.dispose();
          codec.dispose();
        });
        travel.dispose();
      },
    );
  }

  testWidgets(
    'preview is live, defaults Story, supports Square, calls shared service and shows failures',
    (tester) async {
      late StateTravelService travel;
      await tester.runAsync(() async {
        travel = StateTravelService();
        await travel.load();
      });
      final service = RecordingShareService();
      await tester.pumpWidget(
        MaterialApp(
          home: IndiaPassportSharePage(
            travel: travel,
            regions: const [],
            service: service,
            branding: const ShareBrandingConfig(appName: 'Journeys'),
            displayName: 'Abhishek',
          ),
        ),
      );
      expect(service.text, isNull);
      expect(find.text('Abhishek'), findsOneWidget);
      expect(
        tester
            .widget<IndiaPassportShareCard>(find.byType(IndiaPassportShareCard))
            .format,
        ShareCardFormat.story,
      );
      await tester.runAsync(
        () => travel.setStatus('rajasthan', TravelStatus.visited),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IndiaPassportShareCard>(find.byType(IndiaPassportShareCard))
            .data
            .visited,
        1,
      );
      await tester.tap(find.text('Square 1:1'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IndiaPassportShareCard>(find.byType(IndiaPassportShareCard))
            .format,
        ShareCardFormat.square,
      );
      await tester.tap(find.byKey(const ValueKey('passport-share-action')));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(service.png, isNull);
      expect(
        service.text,
        "I've visited 1 of India's 36 States & UTs — 3% of India.",
      );
      service.failInvocation = true;
      await tester.tap(find.byKey(const ValueKey('passport-share-action')));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to share your passport. Please try again.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      travel.dispose();
    },
  );
}
