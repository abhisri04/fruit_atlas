import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item.dart';
import '../theme/app_colors.dart';

class YogaPoseTile extends StatelessWidget {
  final Item pose;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  const YogaPoseTile({
    super.key,
    required this.pose,
    required this.saved,
    required this.onTap,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            children: [
              YogaPoseImage(
                imagePath: pose.imageUrl,
                width: 72,
                height: 52,
                iconSize: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pose.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pose.sanskritName case final sanskritName?) ...[
                      const SizedBox(height: 2),
                      Text(
                        sanskritName,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: saved ? 'Remove pose from Saved' : 'Save pose',
                onPressed: onToggleSaved,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                color: saved ? AppColors.primary : AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YogaPoseImage extends StatefulWidget {
  final String? imagePath;
  final double? width;
  final double height;
  final double iconSize;
  final BoxFit fit;
  final Color backgroundColor;

  const YogaPoseImage({
    super.key,
    this.imagePath,
    this.width,
    required this.height,
    required this.iconSize,
    this.fit = BoxFit.cover,
    this.backgroundColor = AppColors.accentSurface,
  });

  @override
  State<YogaPoseImage> createState() => _YogaPoseImageState();
}

class _YogaPoseImageState extends State<YogaPoseImage> {
  late Future<ByteData?> imageBytes = _load();

  Future<ByteData?> _load() async {
    final path = widget.imagePath;
    if (path == null || !path.startsWith('assets/')) return null;
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant YogaPoseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) imageBytes = _load();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ColoredBox(
          color: widget.backgroundColor,
          child: FutureBuilder<ByteData?>(
            future: imageBytes,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return _YogaPosePlaceholder(iconSize: widget.iconSize);
              }
              return Image.memory(
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
                fit: widget.fit,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    _YogaPosePlaceholder(iconSize: widget.iconSize),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _YogaPosePlaceholder extends StatelessWidget {
  final double iconSize;
  const _YogaPosePlaceholder({required this.iconSize});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.accentSurface,
    child: Icon(
      Icons.self_improvement,
      color: AppColors.primary,
      size: iconSize,
    ),
  );
}
