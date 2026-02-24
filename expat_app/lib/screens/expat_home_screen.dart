import 'package:flutter/material.dart';

/// Palette for Expat home screen; mirrors auth/signup colors.
class _ExpatHomeColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color hint = Color(0xFF9CA5A8);
  // Background for inline comment bubble (Ama Boateng).
  static const Color commentBackground = Color(0xFFE3E7E9);
}

class ExpatHomeScreen extends StatefulWidget {
  const ExpatHomeScreen({super.key});

  @override
  State<ExpatHomeScreen> createState() => _ExpatHomeScreenState();
}

class _ExpatHomeScreenState extends State<ExpatHomeScreen> {
  int _selectedTabIndex = 0; // 0 = Feed, 1 = Bowls
  int _selectedBottomIndex = 0; // 0 = Community

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          _buildTabBar(textTheme),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child:
                _selectedTabIndex == 0
                    ? _buildFeedList(textTheme)
                    : _buildBowlsContent(textTheme),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: _buildShareExperienceButton(textTheme),
      bottomNavigationBar: _buildBottomNav(textTheme),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      color: _ExpatHomeColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text(
              'expat',
              style: textTheme.titleLarge?.copyWith(
                color: _ExpatHomeColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildSearchBar(textTheme)),
            const SizedBox(width: 16),
            const Icon(Icons.notifications_none, color: Colors.white),
            const SizedBox(width: 12),
            const Icon(Icons.person_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.search, color: _ExpatHomeColors.hint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search Apartments...',
              style: textTheme.bodyMedium?.copyWith(
                color: _ExpatHomeColors.hint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(TextTheme textTheme) {
    return Container(
      color: Colors.white,
      // Slight top padding; underline still sits on the divider below.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(textTheme, label: 'Feed', index: 0),
          const SizedBox(width: 24),
          _buildTabItem(textTheme, label: 'Bowls', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    TextTheme textTheme, {
    required String label,
    required int index,
  }) {
    final bool selected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color:
                    selected
                        ? _ExpatHomeColors.bodyText
                        : _ExpatHomeColors.hint,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: double.infinity,
              color: selected ? _ExpatHomeColors.bodyText : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _buildPostBlock(
          textTheme,
          avatarPath: 'assets/images/avatar_benjamin_nelson.png',
          name: 'Benjamin Nelson',
          role: 'Expat',
          timeAgo: '7m',
          content:
              'Hi everyone 👋,\nI just arrived in Kigali last week and I’m still getting used to things. Quick question: what’s the best way to handle short-term housing before committing long-term? Did you start with Airbnb, serviced apartments, or something else?\n\nWould really appreciate advice from people who’ve already been through this.',
          comments: [
            _InlineComment(
              avatarPath: 'assets/images/avatar_ama_boateng.png',
              name: 'Ama Boateng',
              role: 'Expat',
              timeAgo: '7m',
              text:
                  'Welcome, Benjamin! I started with a serviced apartment for a month before finding a longer-term place. It gave me time to understand neighborhoods.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        _buildPostBlock(
          textTheme,
          avatarPath: 'assets/images/avatar_natalie_brooks.png',
          name: 'Natalie Brooks',
          role: 'Expat',
          timeAgo: '2m',
          content:
              'Just came back from gorilla trekking and honestly… I’m still processing it 🦍 It’s one of the most surreal experiences I’ve ever had. Early start, long hike, but absolutely worth it.\n\nIf you’re in Rwanda and considering it — do it.',
          imagePath: 'assets/images/post_gorilla_experience.png',
          comments: [
            _InlineComment(
              avatarPath: 'assets/images/avatar_kwame_mensah.png',
              name: 'Kwame Mensah',
              role: 'Expat',
              timeAgo: '4m',
              text:
                  'Exploring different neighborhoods this week and loving how each area has its own vibe. Any recommendations on must-visit spots?',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlsContent(TextTheme textTheme) {
    final myBowls = <_Bowl>[
      const _Bowl(
        title: 'Nigeria',
        description:
            'A community for all Nigerian Expats in Rwanda. Bi-weekly Nigerian-themed events and many more.',
        imagePath: 'assets/images/bowl_nigeria.png',
      ),
      const _Bowl(
        title: 'Job Hunting',
        description:
            'A community to discuss the job market, as well as finding, applying for, posting, and interviewing for roles within and, if possible, outside the Rwandan job market.',
        imagePath: 'assets/images/bowl_job_hunting.png',
      ),
      const _Bowl(
        title: 'Expatriate Life in Rwanda',
        description:
            'A community recommended for all Expats, to share and review experiences in Rwanda. Connect, plan and have fun together.',
        imagePath: 'assets/images/bowl_expat_life.png',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const SizedBox(height: 16),
        Text(
          'My Bowls',
          style: textTheme.titleMedium?.copyWith(
            color: _ExpatHomeColors.bodyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...myBowls.expand(
          (bowl) => [
            _buildBowlRow(textTheme, bowl),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Other Bowls',
          style: textTheme.titleMedium?.copyWith(
            color: _ExpatHomeColors.bodyText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: Text(
            "Sorry that's all for now. Bowls are being\ncreated in real-time based on data we have\nand are still collecting.",
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: _ExpatHomeColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBowlRow(TextTheme textTheme, _Bowl bowl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(bowl.imagePath),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bowl.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: _ExpatHomeColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bowl.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatHomeColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostBlock(
    TextTheme textTheme, {
    required String avatarPath,
    required String name,
    required String role,
    required String timeAgo,
    required String content,
    String? imagePath,
    List<_InlineComment> comments = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(avatarPath),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.accentGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: textTheme.bodySmall?.copyWith(
                  color: _ExpatHomeColors.helper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: _ExpatHomeColors.bodyText,
            ),
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        Container(height: 180, color: Colors.grey.shade300),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 18,
                color: _ExpatHomeColors.bodyText,
              ),
              const SizedBox(width: 4),
              Text(
                'Like',
                style: textTheme.bodySmall?.copyWith(
                  color: _ExpatHomeColors.bodyText,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: _ExpatHomeColors.bodyText,
              ),
              const SizedBox(width: 4),
              Text(
                'Comment',
                style: textTheme.bodySmall?.copyWith(
                  color: _ExpatHomeColors.bodyText,
                ),
              ),
            ],
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInlineComment(textTheme, comments.first),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineComment(TextTheme textTheme, _InlineComment comment) {
    return Container(
      decoration: BoxDecoration(
        color: _ExpatHomeColors.commentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
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
                          color: _ExpatHomeColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      comment.timeAgo,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.helper,
                      ),
                    ),
                  ],
                ),
                Text(
                  comment.role,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatHomeColors.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatHomeColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareExperienceButton(TextTheme textTheme) {
    final width = MediaQuery.of(context).size.width;
    return Transform.translate(
      // Raise the pill further so it sits above the nav icons.
      offset: const Offset(0, -48),
      child: SizedBox(
        height: 56,
        width: width * 0.55,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _ExpatHomeColors.accentGreen,
            foregroundColor: _ExpatHomeColors.primaryDark,
            elevation: 6,
            side: const BorderSide(
              color: _ExpatHomeColors.primaryDark,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Share your experience',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: _ExpatHomeColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.add,
                size: 26,
                color: _ExpatHomeColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(TextTheme textTheme) {
    return Container(
      decoration: const BoxDecoration(color: _ExpatHomeColors.primaryDark),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomItem(
                textTheme,
                index: 0,
                icon: Icons.groups,
                label: 'Community',
              ),
              _buildBottomItem(
                textTheme,
                index: 1,
                icon: Icons.directions_car_outlined,
                label: 'Rides',
              ),
              _buildBottomItem(
                textTheme,
                index: 2,
                icon: Icons.home_outlined,
                label: 'Estates',
              ),
              _buildBottomItem(
                textTheme,
                index: 3,
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
              ),
              _buildBottomItem(
                textTheme,
                index: 4,
                icon: Icons.explore_outlined,
                label: 'Explore',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    TextTheme textTheme, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _selectedBottomIndex == index;
    final Color color = selected ? _ExpatHomeColors.accentGreen : Colors.white;
    return InkWell(
      onTap: () => setState(() => _selectedBottomIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineComment {
  const _InlineComment({
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

class _Bowl {
  const _Bowl({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;
}
