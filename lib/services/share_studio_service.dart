import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/share_highlight.dart';
import 'asset_data_service.dart';
import 'books_repository.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'progress_summary_service.dart';

class ShareStudioPreferences {
  static const _modeKey = 'share_studio_highlights_mode_v1';
  static const _formatKey = 'share_studio_highlights_format_v1';
  static const _selectionKey = 'share_studio_highlights_selection_v1';

  const ShareStudioPreferences();

  Future<
    ({
      HighlightSelectionMode mode,
      ShareCardFormat format,
      List<String> selectedReferences,
    })
  >
  load() async {
    final preferences = await SharedPreferences.getInstance();
    return (
      mode: HighlightSelectionMode.values.firstWhere(
        (value) => value.name == preferences.getString(_modeKey),
        orElse: () => HighlightSelectionMode.auto,
      ),
      format: ShareCardFormat.values.firstWhere(
        (value) => value.name == preferences.getString(_formatKey),
        orElse: () => ShareCardFormat.story,
      ),
      selectedReferences: preferences.getStringList(_selectionKey) ?? const [],
    );
  }

  Future<void> save(ShareHighlightController controller) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_modeKey, controller.mode.name),
      preferences.setString(_formatKey, controller.format.name),
      preferences.setStringList(
        _selectionKey,
        controller.selectedReferences.toList(growable: false),
      ),
    ]);
  }
}

class ShareStudioService {
  Future<Uint8List> renderCard(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Card is unavailable');
    final image = await boundary.toImage(
      pixelRatio: 1080 / boundary.size.width,
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG rendering failed');
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required String text,
    Rect? origin,
    String fileName = 'india-passport.png',
  }) async {
    Uint8List? png;
    try {
      png = await renderCard(boundaryKey);
    } catch (_) {
      // Rendering failures retain the same progress in a text-only share.
    }
    await invokeShare(png: png, text: text, origin: origin, fileName: fileName);
  }

  Future<void> invokeShare({
    Uint8List? png,
    required String text,
    Rect? origin,
    String fileName = 'india-passport.png',
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: png == null
            ? null
            : [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: png == null ? null : [fileName],
        sharePositionOrigin: origin,
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      throw StateError('Sharing is unavailable');
    }
  }

  final AssetDataService data;
  final IndianDishesRepository dishes;
  final IndianDrinksRepository drinks;
  final BooksRepository books;
  final ProgressSummaryService progress;

  const ShareStudioService({
    this.data = const AssetDataService(),
    this.dishes = const IndianDishesRepository(),
    this.drinks = const IndianDrinksRepository(),
    this.books = const BooksRepository(),
    this.progress = const ProgressSummaryService(),
  });

  Future<List<ShareHighlightItem>> loadCompletedHighlights() async {
    final challenges = await data.loadChallenges();
    final summary = await progress.load(challenges: challenges);
    final completed = summary.completedReferences;
    final items = <ShareHighlightItem>[];

    final fruitData = await data.loadFruitData();
    for (final fruit in fruitData.fruits) {
      final reference = 'fruit:${fruit.id}';
      if (completed.contains(reference)) {
        items.add(
          ShareHighlightItem(
            reference: reference,
            title: fruit.name,
            subtitle: fruit.scientificName,
            imageAsset: fruit.canonicalImageAsset,
            category: ShareHighlightCategory.fruit,
          ),
        );
      }
    }

    final dishData = await dishes.load();
    for (final dish in dishData.dishes) {
      final reference = 'dish:${dish.id}';
      if (completed.contains(reference)) {
        items.add(
          ShareHighlightItem(
            reference: reference,
            title: dish.name,
            subtitle: dish.primaryState,
            imageAsset: dish.imageAsset,
            dish: dish,
            category: ShareHighlightCategory.dish,
          ),
        );
      }
    }

    final drinkData = await drinks.load();
    for (final drink in drinkData.drinks) {
      final reference = 'drink:${drink.id}';
      if (completed.contains(reference)) {
        items.add(
          ShareHighlightItem(
            reference: reference,
            title: drink.name,
            subtitle: drink.primaryState,
            imageAsset: drink.imageAsset,
            category: ShareHighlightCategory.drink,
          ),
        );
      }
    }

    final bookData = await books.load();
    for (final book in bookData.books) {
      final reference = 'book:${book.id}';
      if (completed.contains(reference)) {
        items.add(
          ShareHighlightItem(
            reference: reference,
            title: book.canonicalTitle,
            subtitle: book.primaryAuthorDisplay,
            imageAsset: book.coverAsset,
            category: ShareHighlightCategory.book,
          ),
        );
      }
    }

    for (final challenge in challenges.where(
      (item) =>
          item.itemType == 'yoga_pose' ||
          item.itemType == 'state_or_union_territory',
    )) {
      for (final item in await data.loadChallengeItems(challenge)) {
        final prefix = challenge.itemType == 'yoga_pose' ? 'yoga' : 'state';
        final reference = '$prefix:${item.id}';
        if (completed.contains(reference)) {
          items.add(
            ShareHighlightItem(
              reference: reference,
              title: item.name,
              subtitle: challenge.itemType == 'yoga_pose'
                  ? 'Yoga pose'
                  : 'India',
              imageAsset: item.imageUrl,
              category: challenge.itemType == 'yoga_pose'
                  ? ShareHighlightCategory.yoga
                  : ShareHighlightCategory.travel,
            ),
          );
        }
      }
    }

    for (final site in await data.loadJyotirlingas()) {
      final reference = 'jyotirlinga:${site.id}';
      if (completed.contains(reference)) {
        items.add(
          ShareHighlightItem(
            reference: reference,
            title: site.name,
            subtitle: site.location,
            category: ShareHighlightCategory.pilgrimage,
          ),
        );
      }
    }

    return List.unmodifiable(items);
  }
}
