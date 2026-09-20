import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fruit.dart';
import '../theme/app_colors.dart';

/// Displays the fruit's local canonical WebP or the shared fruit placeholder.
class FruitImage extends StatefulWidget {
  final Fruit fruit;
  final double? width;
  final double height;
  final double iconSize;
  final BoxFit fit;

  const FruitImage({
    super.key,
    required this.fruit,
    this.width,
    required this.height,
    this.iconSize = 28,
    this.fit = BoxFit.cover,
  });

  @override
  State<FruitImage> createState() => _FruitImageState();
}

class _FruitImageState extends State<FruitImage> {
  late Future<ByteData?> imageBytes = _load();

  Future<ByteData?> _load() async {
    final path = widget.fruit.canonicalImageAsset;
    if (!path.startsWith('assets/images/fruits/')) return null;
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant FruitImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruit.canonicalImageAsset !=
        widget.fruit.canonicalImageAsset) {
      imageBytes = _load();
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: AppColors.accentSurface,
        child: FutureBuilder<ByteData?>(
          future: imageBytes,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) return _placeholder();
            return Image.memory(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              fit: widget.fit,
              semanticLabel: widget.fruit.name,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _placeholder(),
            );
          },
        ),
      ),
    ),
  );

  Widget _placeholder() =>
      Icon(Icons.eco_outlined, color: AppColors.primary, size: widget.iconSize);
}
