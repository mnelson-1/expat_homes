import 'package:flutter/material.dart';

import 'package:expat_app/models/post.dart';
import 'package:expat_app/models/post_comment.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/community_service.dart';

class ExpatPostThreadScreen extends StatefulWidget {
  const ExpatPostThreadScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ExpatPostThreadScreen> createState() => _ExpatPostThreadScreenState();
}

class _ThreadColors {
  static const primaryDark = Color(0xFF1A2E35);
  static const bodyText = Color(0xFF1A2E35);
  static const helper = Color(0xFF9CA5A8);
  static const roleBlue = Color(0xFF1976D2);
  static const commentBackground = Color(0xFFE3E7E9);
  static const accentGreen = Color(0xFF8ED966);
}

class _ExpatPostThreadScreenState extends State<ExpatPostThreadScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const double _replyIndent = 32.0;

  String? _replyToCommentId;
  String? _uid;
  String _userName = '';
  String _userRole = 'Expat';

  Post? _post;
  bool _loadingPost = true;
  late final Stream<List<PostComment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _uid = AuthService().currentUser?.uid;
    _commentsStream = CommunityService().commentsStream(widget.postId);
    _loadPost();
    _loadProfile();
  }

  Future<void> _loadPost() async {
    final post = await CommunityService().getPost(widget.postId);
    if (mounted) setState(() { _post = post; _loadingPost = false; });
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile.legalName;
        _userRole = profile.role.value.substring(0, 1).toUpperCase() +
            profile.role.value.substring(1);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: _loadingPost
                ? const Center(child: CircularProgressIndicator())
                : _post == null
                    ? Center(
                        child: Text('Post not found.',
                            style: textTheme.bodyMedium?.copyWith(
                                color: _ThreadColors.helper)))
                    : _buildBody(textTheme),
          ),
          _buildComposer(textTheme),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    return StreamBuilder<List<PostComment>>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];

        final topLevel =
            comments.where((c) => c.parentCommentId == null).toList();
        final repliesMap = <String, List<PostComment>>{};
        for (final c in comments.where((c) => c.parentCommentId != null)) {
          repliesMap.putIfAbsent(c.parentCommentId!, () => []).add(c);
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _buildMainPost(textTheme),
            const SizedBox(height: 24),
            for (int i = 0; i < topLevel.length; i++) ...[
              _buildCommentCard(textTheme, topLevel[i]),
              if (repliesMap.containsKey(topLevel[i].id)) ...[
                const SizedBox(height: 8),
                for (final reply in repliesMap[topLevel[i].id]!) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: _replyIndent),
                    child: _buildCommentCard(textTheme, reply),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              if (i < topLevel.length - 1) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      color: _ThreadColors.primaryDark,
      padding: const EdgeInsets.only(top: 40, left: 8, right: 16, bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Text(
              'Chat thread',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPost(TextTheme textTheme) {
    final post = _post!;
    final liked = _uid != null && post.isLikedBy(_uid!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                post.authorName.isNotEmpty
                    ? post.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ThreadColors.bodyText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName,
                                style: textTheme.titleMedium?.copyWith(
                                    color: _ThreadColors.bodyText,
                                    fontWeight: FontWeight.w600)),
                            Text(post.authorRole,
                                style: textTheme.bodySmall?.copyWith(
                                    color: _ThreadColors.roleBlue,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Text(_timeAgo(post.createdAt),
                          style: textTheme.bodySmall
                              ?.copyWith(color: _ThreadColors.helper)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(post.content,
            style: textTheme.bodyMedium
                ?.copyWith(color: _ThreadColors.bodyText)),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_uid != null) {
                  CommunityService().toggleLike(post.id, _uid!);
                  _loadPost();
                }
              },
              child: Row(children: [
                Icon(liked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: liked ? Colors.redAccent : _ThreadColors.bodyText),
                const SizedBox(width: 4),
                Text(post.likeCount > 0 ? '${post.likeCount}' : 'Like',
                    style: textTheme.bodySmall
                        ?.copyWith(color: _ThreadColors.bodyText)),
              ]),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                setState(() => _replyToCommentId = null);
                _scrollToComposer();
              },
              child: Row(children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 18, color: _ThreadColors.bodyText),
                const SizedBox(width: 4),
                Text('Comment',
                    style: textTheme.bodySmall
                        ?.copyWith(color: _ThreadColors.bodyText)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentCard(TextTheme textTheme, PostComment comment) {
    final liked = _uid != null && comment.isLikedBy(_uid!);
    return Container(
      decoration: BoxDecoration(
        color: _ThreadColors.commentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ThreadColors.bodyText),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(comment.authorName,
                              style: textTheme.bodyMedium?.copyWith(
                                  color: _ThreadColors.bodyText,
                                  fontWeight: FontWeight.w600))),
                      Text(_timeAgo(comment.createdAt),
                          style: textTheme.bodySmall
                              ?.copyWith(color: _ThreadColors.bodyText)),
                    ]),
                    Text(comment.authorRole,
                        style: textTheme.bodySmall?.copyWith(
                            color: _ThreadColors.roleBlue,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(comment.content,
                        style: textTheme.bodySmall
                            ?.copyWith(color: _ThreadColors.bodyText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (_uid != null) {
                    CommunityService()
                        .toggleCommentLike(comment.id, _uid!);
                  }
                },
                child: Row(children: [
                  Icon(liked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color:
                          liked ? Colors.redAccent : _ThreadColors.bodyText),
                  const SizedBox(width: 4),
                  Text(
                      comment.likeCount > 0
                          ? '${comment.likeCount}'
                          : 'Like',
                      style: textTheme.bodySmall
                          ?.copyWith(color: _ThreadColors.bodyText)),
                ]),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(
                      () => _replyToCommentId = comment.parentCommentId ?? comment.id);
                  _scrollToComposer();
                },
                child: Row(children: [
                  const Icon(Icons.reply,
                      size: 16, color: _ThreadColors.bodyText),
                  const SizedBox(width: 4),
                  Text('Reply',
                      style: textTheme.bodySmall
                          ?.copyWith(color: _ThreadColors.bodyText)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(TextTheme textTheme) {
    return Container(
      color: _ThreadColors.primaryDark,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243A42),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _ThreadColors.helper.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _commentController,
                    style:
                        textTheme.bodyMedium?.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _replyToCommentId == null
                          ? 'Leave your comment...'
                          : 'Reply to comment...',
                      hintStyle: textTheme.bodyMedium
                          ?.copyWith(color: _ThreadColors.helper),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _ThreadColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: _ThreadColors.primaryDark, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _uid == null) return;
    _commentController.clear();

    await CommunityService().addComment(
      postId: widget.postId,
      authorId: _uid!,
      authorName: _userName,
      authorRole: _userRole,
      content: text,
      parentCommentId: _replyToCommentId,
    );

    setState(() => _replyToCommentId = null);
    _scrollToComposer();
  }
}
