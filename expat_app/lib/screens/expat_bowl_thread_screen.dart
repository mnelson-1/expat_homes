import 'package:flutter/material.dart';

import 'package:expat_app/models/bowl.dart';
import 'package:expat_app/models/post.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/constants/bowl_cover_defaults.dart';
import 'package:expat_app/services/bowls_service.dart';
import 'package:expat_app/services/community_service.dart';
import 'package:expat_app/widgets/community_post_composer_sheet.dart';
import 'package:expat_app/widgets/post_media_gallery.dart';
import 'expat_post_thread_screen.dart';

class _BowlColors {
  static const primaryDark = Color(0xFF1A2E35);
  static const bodyText = Color(0xFF1A2E35);
  static const helper = Color(0xFF9CA5A8);
  static const roleBlue = Color(0xFF1976D2);
  static const accentGreen = Color(0xFF8ED966);
}

class ExpatBowlThreadScreen extends StatefulWidget {
  const ExpatBowlThreadScreen({super.key, required this.bowlId});

  final String bowlId;

  @override
  State<ExpatBowlThreadScreen> createState() => _ExpatBowlThreadScreenState();
}

class _ExpatBowlThreadScreenState extends State<ExpatBowlThreadScreen> {
  Bowl? _bowl;
  bool _loading = true;
  late final Stream<List<Post>> _postsStream;

  String? _uid;
  String _userName = '';
  String _userRole = 'Expat';
  String? _userProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _uid = AuthService().currentUser?.uid;
    _postsStream = CommunityService().bowlPostsStream(widget.bowlId);
    _loadBowl();
    _loadProfile();
  }

  Future<void> _loadBowl() async {
    final doc = await BowlsService().getBowl(widget.bowlId);
    if (mounted) {
      setState(() {
        _bowl = doc;
        _loading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile.legalName;
        _userRole =
            profile.role.value.substring(0, 1).toUpperCase() +
            profile.role.value.substring(1);
        _userProfileImageUrl = profile.profileImageUrl;
      });
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bowlName = _bowl?.name ?? 'Bowl';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme, bowlName),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _bowl == null
                    ? Center(
                      child: Text(
                        'Bowl not found.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _BowlColors.helper,
                        ),
                      ),
                    )
                    : _buildBody(textTheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _BowlColors.accentGreen,
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add, color: _BowlColors.primaryDark),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    String bowlName,
  ) {
    return Container(
      color: _BowlColors.primaryDark,
      padding: const EdgeInsets.only(top: 40, left: 8, right: 16, bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                bowlName,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    return StreamBuilder<List<Post>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildBowlHero(textTheme),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            if (snapshot.data == null || snapshot.data!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No posts in this bowl yet.\nStart the conversation!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _BowlColors.helper,
                    ),
                  ),
                ),
              )
            else
              for (final post in snapshot.data!) ...[
                _buildPostCard(textTheme, post),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
              ],
          ],
        );
      },
    );
  }

  Widget _buildBowlHero(TextTheme textTheme) {
    final bowl = _bowl!;
    final coverUrl = resolvedBowlCoverUrl(bowl);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (coverUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            bowl.description,
            style: textTheme.bodyMedium?.copyWith(color: _BowlColors.bodyText),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(TextTheme textTheme, Post post) {
    final liked = _uid != null && post.isLikedBy(_uid!);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExpatPostThreadScreen(postId: post.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      post.authorImageUrl != null &&
                              post.authorImageUrl!.isNotEmpty
                          ? NetworkImage(post.authorImageUrl!)
                          : null,
                  child:
                      post.authorImageUrl == null ||
                              post.authorImageUrl!.isEmpty
                          ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _BowlColors.bodyText,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: textTheme.titleMedium?.copyWith(
                          color: _BowlColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        post.authorRole,
                        style: textTheme.bodySmall?.copyWith(
                          color: _BowlColors.roleBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(post.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: _BowlColors.helper,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: textTheme.bodyMedium?.copyWith(
                color: _BowlColors.bodyText,
              ),
            ),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              PostMediaGallery(imageUrls: post.imageUrls),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_uid != null) {
                      CommunityService().toggleLike(post.id, _uid!);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: liked ? Colors.redAccent : _BowlColors.bodyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likeCount > 0 ? '${post.likeCount}' : 'Like',
                        style: textTheme.bodySmall?.copyWith(
                          color: _BowlColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: _BowlColors.bodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.commentCount > 0
                          ? '${post.commentCount}'
                          : 'Comment',
                      style: textTheme.bodySmall?.copyWith(
                        color: _BowlColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return CommunityPostComposerSheet(
          title: 'Post in ${_bowl?.name ?? "this bowl"}',
          accentGreen: _BowlColors.accentGreen,
          primaryDark: _BowlColors.primaryDark,
          helper: _BowlColors.helper,
          bodyText: _BowlColors.bodyText,
          onSubmit: (content, images) async {
            if (_uid == null) return;
            await CommunityService().createPost(
              authorId: _uid!,
              authorName: _userName,
              authorRole: _userRole,
              content: content,
              imageFiles: images.isNotEmpty ? images : null,
              authorImageUrl: _userProfileImageUrl,
              scope: 'bowl',
              bowlId: widget.bowlId,
            );
          },
        );
      },
    );
  }
}
