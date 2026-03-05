import 'package:flutter/material.dart';

/// Detailed chat thread for a Community post (Expat workflow).
///
/// This is currently backed by mock data so we can finalize the UI.
/// When the backend is ready, wire this screen to load the post and
/// its comments dynamically from the API.
class ExpatPostThreadScreen extends StatefulWidget {
  const ExpatPostThreadScreen({super.key});

  @override
  State<ExpatPostThreadScreen> createState() => _ExpatPostThreadScreenState();
}

class _ThreadColors {
  static const primaryDark = Color(0xFF1A2E35);
  static const bodyText = Color(0xFF1A2E35);
  static const helper = Color(0xFF9CA5A8);
  static const roleBlue = Color(0xFF1976D2); // "Expat" label
  static const commentBackground = Color(0xFFE3E7E9);
}

class _ThreadComment {
  const _ThreadComment({
    required this.avatarPath,
    required this.name,
    required this.role,
    required this.timeAgo,
    required this.text,
  });

  final String avatarPath;
  final String name;
  final String role;
  final String timeAgo;
  final String text;
}

enum _ReplyTarget { post, thread }

class _ExpatPostThreadScreenState extends State<ExpatPostThreadScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const double _replyIndent = 32.0;
  bool _showAllReplies = false;
  _ReplyTarget _replyTarget = _ReplyTarget.post;

  // Seed data mirroring the Community feed.
  // First list: a parent comment that has nested replies.
  static const List<_ThreadComment> _seedThreadComments = [
    _ThreadComment(
      avatarPath: 'assets/images/avatar_ama_boateng.png',
      name: 'Ama Boateng',
      role: 'Expat',
      timeAgo: '7m',
      text:
          'Welcome, Benjamin! I started with a serviced apartment for a month before finding a longer-term place. It gave me time to understand neighborhoods.',
    ),
    _ThreadComment(
      avatarPath: 'assets/images/avatar_sofia_alvarez.png',
      name: 'Sofia Álvarez',
      role: 'Expat',
      timeAgo: '7m',
      text: 'Me too.',
    ),
    _ThreadComment(
      avatarPath: 'assets/images/avatar_michael_oconnor.png',
      name: 'Michael O’Connor',
      role: 'Expat',
      timeAgo: '7m',
      text:
          'One tip: always see the place in person before paying anything long-term.',
    ),
    _ThreadComment(
      avatarPath: 'assets/images/avatar_grace_wanjiku.png',
      name: 'Grace Wanjiku',
      role: 'Expat',
      timeAgo: '7m',
      text:
          'He’s on the right platform already — chatting directly with agents helped me avoid issues.',
    ),
  ];

  // Second list: other top-level comments replying directly to the post.
  static const List<_ThreadComment> _seedTopLevelReplies = [
    _ThreadComment(
      avatarPath: 'assets/images/avatar_fatima_hassan.png',
      name: 'Fatima Hassan',
      role: 'Expat',
      timeAgo: '7m',
      text:
          'Airbnb works, but prices vary a lot. If you can, ask locals or verified agents before committing.',
    ),
  ];

  final List<_ThreadComment> _threadComments = List<_ThreadComment>.from(
    _seedThreadComments,
  );
  final List<_ThreadComment> _topLevelReplies = List<_ThreadComment>.from(
    _seedTopLevelReplies,
  );

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildMainPost(textTheme),
                const SizedBox(height: 24),
                _buildInlineComment(textTheme, _threadComments.first),
                const SizedBox(height: 8),
                // "View N more replies" toggle, aligned with the replies indent.
                Padding(
                  padding: const EdgeInsets.only(left: _replyIndent),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showAllReplies = !_showAllReplies;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View ${_threadComments.length - 1} more replies',
                          style: textTheme.bodySmall?.copyWith(
                            color: _ThreadColors.bodyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllReplies
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: _ThreadColors.bodyText,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAllReplies) ...[
                  const SizedBox(height: 8),
                  for (int i = 1; i < _threadComments.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: _replyIndent),
                      child: _buildInlineComment(textTheme, _threadComments[i]),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (_topLevelReplies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < _topLevelReplies.length; i++) ...[
                    _buildInlineComment(textTheme, _topLevelReplies[i]),
                    if (i != _topLevelReplies.length - 1) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ],
            ),
          ),
          _buildComposer(textTheme),
        ],
      ),
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: const AssetImage(
                'assets/images/avatar_benjamin_nelson.png',
              ),
              backgroundColor: Colors.grey.shade200,
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
                            Text(
                              'Benjamin Nelson',
                              style: textTheme.titleMedium?.copyWith(
                                color: _ThreadColors.bodyText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Expat',
                              style: textTheme.bodySmall?.copyWith(
                                color: _ThreadColors.roleBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '7m',
                        style: textTheme.bodySmall?.copyWith(
                          color: _ThreadColors.helper,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hi everyone 👋,\nI just arrived in Kigali last week and I’m still getting used to things. Quick question: what’s the best way to handle short-term housing before committing long-term? Did you start with Airbnb, serviced apartments, or something else?\n\nWould really appreciate advice from people who’ve already been through this.',
          style: textTheme.bodyMedium?.copyWith(color: _ThreadColors.bodyText),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.favorite_border,
              size: 18,
              color: _ThreadColors.bodyText,
            ),
            const SizedBox(width: 4),
            Text(
              'Like',
              style: textTheme.bodySmall?.copyWith(
                color: _ThreadColors.bodyText,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: _ThreadColors.bodyText,
            ),
            const SizedBox(width: 4),
            Text(
              'Comment',
              style: textTheme.bodySmall?.copyWith(
                color: _ThreadColors.bodyText,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _replyTarget = _ReplyTarget.post;
                });
                _scrollToComposer();
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.reply,
                    size: 18,
                    color: _ThreadColors.bodyText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: textTheme.bodySmall?.copyWith(
                      color: _ThreadColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineComment(TextTheme textTheme, _ThreadComment comment) {
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
                backgroundImage: AssetImage(comment.avatarPath),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.name,
                            style: textTheme.bodyMedium?.copyWith(
                              color: _ThreadColors.bodyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          comment.timeAgo,
                          style: textTheme.bodySmall?.copyWith(
                            color: _ThreadColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      comment.role,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ThreadColors.roleBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ThreadColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Align Like / Comment / Reply under the start of the text column
          // (same x-position as the comment text, not the avatar).
          Padding(
            padding: const EdgeInsets.only(
              left: 28 + 8,
            ), // avatar (28) + gap (8)
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: _ThreadColors.bodyText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Like',
                  style: textTheme.bodySmall?.copyWith(
                    color: _ThreadColors.bodyText,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: _ThreadColors.bodyText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comment',
                  style: textTheme.bodySmall?.copyWith(
                    color: _ThreadColors.bodyText,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _replyTarget = _ReplyTarget.thread;
                      _showAllReplies = true;
                    });
                    _scrollToComposer();
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply,
                        size: 16,
                        color: _ThreadColors.bodyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: textTheme.bodySmall?.copyWith(
                          color: _ThreadColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          _replyTarget == _ReplyTarget.post
                              ? 'Leave your comment...'
                              : 'Reply to comment...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: _ThreadColors.helper,
                      ),
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
                    color: Color(0xFF8ED966),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: _ThreadColors.primaryDark,
                    size: 22,
                  ),
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

  void _handleSend() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();

    final created = _ThreadComment(
      avatarPath: 'assets/images/avatar_benjamin_nelson.png',
      name: 'You',
      role: 'Expat',
      timeAgo: 'now',
      text: text,
    );

    setState(() {
      if (_replyTarget == _ReplyTarget.post) {
        _topLevelReplies.add(created);
      } else {
        _threadComments.add(created);
        _showAllReplies = true;
      }
      _replyTarget = _ReplyTarget.post;
    });

    _scrollToComposer();
  }
}
