import 'package:flutter/material.dart';

import 'package:expat_app/constants/bowl_cover_defaults.dart';
import 'package:expat_app/models/bowl.dart';

/// Circular bowl thumbnail: network cover when available, else first letter.
class BowlCoverAvatar extends StatelessWidget {
  const BowlCoverAvatar({
    super.key,
    required this.bowl,
    this.radius = 20,
    this.nameColor = const Color(0xFF1A2E35),
  });

  final Bowl bowl;
  final double radius;
  final Color nameColor;

  @override
  Widget build(BuildContext context) {
    final url = resolvedBowlCoverUrl(bowl);
    final initial = bowl.name.isNotEmpty ? bowl.name[0].toUpperCase() : '?';

    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: nameColor,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: radius * 2,
            height: radius * 2,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: SizedBox(
              width: radius * 0.9,
              height: radius * 0.9,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: nameColor.withValues(alpha: 0.5),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: nameColor,
            ),
          ),
        ),
      ),
    );
  }
}
