import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Circular avatar loaded from Firestore `users/{uid}.profileImageUrl`.
/// Updates live when the user changes their profile picture.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    required this.uid,
    this.radius = 20,
  });

  final String uid;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: AuthService().userProfileStream(uid),
      builder: (context, snapshot) {
        final url = snapshot.data?.profileImageUrl;
        final hasUrl = url != null && url.isNotEmpty;
        final size = radius * 2;

        if (!hasUrl) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: radius * 1.1,
            ),
          );
        }

        return ClipOval(
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: radius * 1.1,
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: SizedBox(
                    width: radius * 0.9,
                    height: radius * 0.9,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
