import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DishImage extends StatelessWidget {
  static Future<Set<String>>? _assetPaths;
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const DishImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static Future<Set<String>> _loadAssetPaths() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().toSet();
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
      ),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant, size: 42, color: Color(0xFFBF6516)),
  );

  @override
  Widget build(BuildContext context) {
    final child = FutureBuilder<Set<String>>(
      future: _assetPaths ??= _loadAssetPaths(),
      builder: (context, snapshot) {
        if (!(snapshot.data?.contains(assetPath) ?? false)) {
          return _placeholder();
        }
        return Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    );
    return borderRadius == null
        ? child
        : ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
