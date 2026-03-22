import 'package:flutter/material.dart';

/// Renders one or more post images (full width, rounded corners) like the
/// community feed prototype.
class PostMediaGallery extends StatelessWidget {
  const PostMediaGallery({
    super.key,
    required this.imageUrls,
    this.borderRadius = 12,
    this.gap = 12,
    this.maxImageHeight = 360,
  });

  final List<String> imageUrls;
  final double borderRadius;
  final double gap;
  final double maxImageHeight;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.where((u) => u.isNotEmpty).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < urls.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxImageHeight),
              child: Image.network(
                urls[i],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
