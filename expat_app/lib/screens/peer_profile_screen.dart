import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/auth_service.dart';

import 'agent_profile_screen.dart';

/// **Contact profile** — the person you’re chatting with, opened from the
/// conversation header. Agents use the same screen as Find Agent; expat/landlord
/// peers use a simplified layout (no ratings).
class PeerProfileScreen extends StatelessWidget {
  const PeerProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: AuthService().userProfileStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: const Text('Profile'),
            ),
            body: const Center(child: Text('Profile not found.')),
          );
        }

        if (profile.role == UserRole.agent) {
          final aid = profile.agentId;
          if (aid == null || aid.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF1A2E35),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Text('Profile', style: TextStyle(color: Colors.white)),
              ),
              body: const Center(child: Text('Agent profile unavailable.')),
            );
          }
          return FutureBuilder<UserProfile?>(
            future: AuthService().getCurrentUserProfile(),
            builder: (context, meSnap) {
              if (meSnap.connectionState == ConnectionState.waiting &&
                  !meSnap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final showAssign =
                  meSnap.data?.role == UserRole.landlord;
              return ContactAgentProfileScreen(
                agentUserUid: uid,
                showAssignProperty: showAssign,
              );
            },
          );
        }

        return _ExpatLandlordContactProfilePage(uid: uid, profile: profile);
      },
    );
  }
}

class _ExpatLandlordContactProfilePage extends StatelessWidget {
  const _ExpatLandlordContactProfilePage({
    required this.uid,
    required this.profile,
  });

  final String uid;
  final UserProfile profile;

  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _heroGrey = Color(0xFFDFDFDF);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = profile.legalName;
    final email = profile.email;
    final bio = profile.bio?.trim() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 76,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 10,
        title: Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: StreamBuilder<UserProfile?>(
            stream: AuthService().userProfileStream(uid),
            builder: (context, snap) {
              final p = snap.data ?? profile;
              final url = p.profileImageUrl;
              final hasUrl = url != null && url.isNotEmpty;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    backgroundImage: hasUrl ? NetworkImage(url) : null,
                    child:
                        !hasUrl
                            ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: StreamBuilder<UserProfile?>(
                stream: AuthService().userProfileStream(uid),
                builder: (context, snap) {
                  final url = snap.data?.profileImageUrl;
                  final hasUrl = url != null && url.isNotEmpty;
                  return ColoredBox(
                    color: _heroGrey,
                    child:
                        hasUrl
                            ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                            : Center(
                              child: Icon(
                                Icons.person,
                                size: 120,
                                color: Colors.grey.shade400,
                              ),
                            ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleLarge?.copyWith(
                      color: _primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _primaryDark.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bio:',
                    style: textTheme.titleSmall?.copyWith(
                      color: _primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio.isNotEmpty ? bio : '—',
                    style: textTheme.bodyMedium?.copyWith(color: _primaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
