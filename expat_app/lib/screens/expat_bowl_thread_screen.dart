import 'package:flutter/material.dart';

/// Extended view for a Bowl (e.g. "Expatriate Life in Rwanda") showing
/// the community hero (image + description) plus a simple example thread.
///
/// This mirrors the extended post thread layout so that when the backend
/// is connected, both pages feel consistent.
class ExpatBowlThreadScreen extends StatelessWidget {
  const ExpatBowlThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildBowlHero(textTheme),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                _buildExampleThread(context, textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      color: const Color(0xFF1A2E35),
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
              'Expatriate Life in Rwanda',
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

  Widget _buildBowlHero(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          // Slightly shallower hero so the image doesn't dominate and
          // low-resolution assets are less noticeable.
          aspectRatio: 16 / 6,
          child: Image.asset(
            'assets/images/Bowl_extend.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade300),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'A community recommended for all Expats, to share and review experiences in Rwanda. Connect, plan and have fun together.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleThread(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main post (Benjamin) – same layout as post extended thread.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    const AssetImage('assets/images/avatar_benjamin_nelson.png'),
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
                                  color: const Color(0xFF1A2E35),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Expat',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '7m',
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9CA5A8),
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
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  size: 18, color: Color(0xFF1A2E35)),
              const SizedBox(width: 4),
              Text(
                'Like',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A2E35),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline,
                  size: 18, color: Color(0xFF1A2E35)),
              const SizedBox(width: 4),
              Text(
                'Comment',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A2E35),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.reply,
                  size: 18, color: Color(0xFF1A2E35)),
              const SizedBox(width: 4),
              Text(
                'Reply',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A2E35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // First comment (Ama) – grey card with Like / Comment / Reply.
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3E7E9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: const AssetImage(
                      'assets/images/avatar_ama_boateng.png'),
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
                              'Ama Boateng',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF1A2E35),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '7m',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Expat',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome, Benjamin! I started with a serviced apartment for a month before finding a longer-term place. It gave me time to understand neighborhoods.',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1A2E35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.only(left: 28 + 8), // avatar (28) + gap (8)
            child: Row(
              children: [
                const Icon(Icons.favorite_border,
                    size: 16, color: Color(0xFF1A2E35)),
                const SizedBox(width: 4),
                Text(
                  'Like',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: Color(0xFF1A2E35)),
                const SizedBox(width: 4),
                Text(
                  'Comment',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.reply,
                    size: 16, color: Color(0xFF1A2E35)),
                const SizedBox(width: 4),
                Text(
                  'Reply',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // "View 3 more replies" placeholder.
          Padding(
            padding:
                const EdgeInsets.only(left: 32), // align with nested replies
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View 3 more replies',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Color(0xFF1A2E35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          // Second top-level comment (Fatima), same style as in post thread.
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3E7E9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: const AssetImage(
                      'assets/images/avatar_fatima_hassan.png'),
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
                              'Fatima Hassan',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF1A2E35),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '7m',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Expat',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Airbnb works, but prices vary a lot. If you can, ask locals or verified agents before committing.',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1A2E35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border,
                              size: 16, color: Color(0xFF1A2E35)),
                          const SizedBox(width: 4),
                          Text(
                            'Like',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline,
                              size: 16, color: Color(0xFF1A2E35)),
                          const SizedBox(width: 4),
                          Text(
                            'Comment',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.reply,
                              size: 16, color: Color(0xFF1A2E35)),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                        ],
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
}

