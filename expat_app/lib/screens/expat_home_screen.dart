import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'listing_detail_screen.dart';
import 'messages_screen.dart' show MessagesScreen, kRoleExpat;
import 'expat_post_thread_screen.dart';
import 'expat_bowl_thread_screen.dart';

/// Palette for Expat home screen; mirrors auth/signup colors.
class _ExpatHomeColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color hint = Color(0xFF9CA5A8);
  // Background for inline comment bubble (Ama Boateng).
  static const Color commentBackground = Color(0xFFE3E7E9);
  // Explore Area button on estate cards.
  static const Color exploreYellow = Color(0xFFFFD54F);
  // Role label (e.g. small "Expat" under each name) – blue.
  static const Color roleBlue = Color(0xFF1976D2);
}

class ExpatHomeScreen extends StatefulWidget {
  const ExpatHomeScreen({super.key});

  @override
  State<ExpatHomeScreen> createState() => _ExpatHomeScreenState();
}

class _ExpatHomeScreenState extends State<ExpatHomeScreen> {
  int _selectedTabIndex = 0; // 0 = Feed, 1 = Bowls
  int _selectedBottomIndex = 0; // 0 = Community, 2 = Estates, etc.
  int _selectedEstateFilter = 0; // 0 = All, 1 = Apartments, 2 = Houses, 3 = Short-Stay
  String _estateSearchQuery = '';
  final TextEditingController _estateSearchController = TextEditingController();

  final ScrollController _feedScrollController = ScrollController();
  final ScrollController _bowlsScrollController = ScrollController();
  final ScrollController _estatesScrollController = ScrollController();
  double _feedScrollOffset = 0;
  double _bowlsScrollOffset = 0;
  double _estatesScrollOffset = 0;

  static const List<BoxShadow> _tabBarShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 6),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _feedScrollController.addListener(_onFeedScroll);
    _bowlsScrollController.addListener(_onBowlsScroll);
    _estatesScrollController.addListener(_onEstatesScroll);
  }

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _bowlsScrollController.removeListener(_onBowlsScroll);
    _estatesScrollController.removeListener(_onEstatesScroll);
    _feedScrollController.dispose();
    _bowlsScrollController.dispose();
    _estatesScrollController.dispose();
    _estateSearchController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    final o = _feedScrollController.offset;
    if (_feedScrollOffset != o) setState(() => _feedScrollOffset = o);
  }

  void _onBowlsScroll() {
    final o = _bowlsScrollController.offset;
    if (_bowlsScrollOffset != o) setState(() => _bowlsScrollOffset = o);
  }

  void _onEstatesScroll() {
    final o = _estatesScrollController.offset;
    if (_estatesScrollOffset != o) setState(() => _estatesScrollOffset = o);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          Expanded(
            child: _selectedBottomIndex == 0
                ? Column(
                    children: [
                      _buildTabBar(textTheme),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      Expanded(
                        child: _selectedTabIndex == 0
                            ? _buildFeedList(textTheme)
                            : _buildBowlsContent(textTheme),
                      ),
                    ],
                  )
                : _selectedBottomIndex == 2
                    ? _buildEstatesContentWithStream(textTheme)
                    : _selectedBottomIndex == 3
                        ? MessagesScreen(currentUserRole: kRoleExpat)
                        : Center(
                            child: Text(
                              'Content for other tabs will live here.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: _ExpatHomeColors.helper,
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: _selectedBottomIndex == 0 && _selectedTabIndex == 0
          ? _buildShareExperienceButton(textTheme)
          : null,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'expat',
              style: textTheme.titleLarge?.copyWith(
                color: _ExpatHomeColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
              child: _buildSearchBar(textTheme),
            ),
            const Icon(Icons.notifications_none, color: Colors.white),
            _buildProfileMenu(textTheme),
          ],
        ),
      ),
    );
  }

  /// Temporary testing: profile menu with Log out. Auth state stream in main will show Get Started.
  Widget _buildProfileMenu(TextTheme textTheme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person_outline, color: Colors.white),
      color: Colors.white,
      onSelected: (value) {
        if (value == 'logout') {
          AuthService().signOut();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log out'),
          ),
        ),
      ],
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
    final showShadow = (_selectedTabIndex == 0 && _feedScrollOffset > 0) ||
        (_selectedTabIndex == 1 && _bowlsScrollOffset > 0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Always show a light shadow for separation; stronger when scrolled
        boxShadow: [
          const BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
          if (showShadow) ..._tabBarShadow,
        ],
      ),
      // Extra top padding so tab text doesn't look tight; underline still sits on the divider below.
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
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
      controller: _feedScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExpatPostThreadScreen(),
              ),
            );
          },
          child: _buildPostBlock(
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
      controller: _bowlsScrollController,
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ExpatBowlThreadScreen(),
          ),
        );
      },
      child: Padding(
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
      ),
    );
  }

  static const List<_EstateFilterOption> _estateFilterOptions = [
    _EstateFilterOption(label: 'All', index: 0),
    _EstateFilterOption(label: 'Apartments', index: 1),
    _EstateFilterOption(label: 'Houses', index: 2),
    _EstateFilterOption(label: 'Short-Stay', index: 3),
  ];

  /// Estates tab: stream published listings from Firestore, filter by type + search.
  Widget _buildEstatesContentWithStream(TextTheme textTheme) {
    return StreamBuilder<List<Listing>>(
      stream: ListingsService().publishedListingsStream(),
      builder: (context, snapshot) {
        var list = snapshot.data ?? [];
        if (_selectedEstateFilter == 1) {
          list = list.where((e) => e.type == ListingType.apartment).toList();
        } else if (_selectedEstateFilter == 2) {
          list = list.where((e) => e.type == ListingType.house).toList();
        } else if (_selectedEstateFilter == 3) {
          list = list.where((e) => e.type == ListingType.shortStay).toList();
        }
        if (_estateSearchQuery.trim().isNotEmpty) {
          final q = _estateSearchQuery.trim().toLowerCase();
          list = list.where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.location.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q)).toList();
        }
        if (_selectedEstateFilter == 0) {
          list = List.from(list)..sort((a, b) => a.title.compareTo(b.title));
        }
        return _buildEstatesContentFromList(textTheme, list, snapshot.connectionState);
      },
    );
  }

  Widget _buildEstatesContentFromList(
    TextTheme textTheme,
    List<Listing> estates,
    ConnectionState connectionState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              const BoxShadow(
                color: Color(0x26000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
              if (_estatesScrollOffset > 0) ..._tabBarShadow,
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _estateSearchController,
                onChanged: (v) => setState(() => _estateSearchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by title, location...',
                  hintStyle: TextStyle(color: _ExpatHomeColors.hint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _estateFilterOptions
                    .map((opt) => _buildEstateFilterItem(textTheme, opt))
                    .toList(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child: connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : estates.isEmpty
                  ? Center(
                      child: Text(
                        'No published listings yet.\n(Set status to "published" in Firestore to see them here.)',
                        style: textTheme.bodyMedium?.copyWith(color: _ExpatHomeColors.helper),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _estatesScrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: estates.length,
                      itemBuilder: (context, index) {
                        if (index > 0) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1, color: Color(0xFFE0E0E0)),
                              _buildEstateCardFromListing(context, textTheme, estates[index]),
                            ],
                          );
                        }
                        return _buildEstateCardFromListing(context, textTheme, estates[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEstateCardFromListing(
    BuildContext context,
    TextTheme textTheme,
    Listing estate,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ListingDetailScreenById(listingId: estate.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildListingImage(estate, height: 180),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estate.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estate.location,
                        style: textTheme.bodySmall?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ExpatHomeColors.helper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estate.typeLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPriceText(textTheme, estate.price),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _ExpatHomeColors.accentGreen,
                      foregroundColor: _ExpatHomeColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Get a Ride',
                      style: textTheme.titleMedium?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _ExpatHomeColors.exploreYellow,
                      foregroundColor: _ExpatHomeColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Explore Area',
                      style: textTheme.titleMedium?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingImage(Listing estate, {required double height}) {
    final url = estate.firstImageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.home, size: 48, color: Colors.grey)),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }
    return Image.asset(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.home, size: 48)),
      ),
    );
  }

  /// Renders price with currency/amount in bold and suffix (e.g. "/mo") in regular weight.
  Widget _buildPriceText(TextTheme textTheme, String price) {
    final parts = price.split('/');
    final amount = parts.isNotEmpty ? parts[0] : price;
    final suffix = parts.length > 1 ? '/${parts[1]}' : '';
    return RichText(
      text: TextSpan(
        style: textTheme.titleSmall?.copyWith(color: _ExpatHomeColors.bodyText),
        children: [
          TextSpan(
            text: amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _ExpatHomeColors.bodyText,
            ),
          ),
          TextSpan(
            text: suffix,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: textTheme.bodySmall?.fontSize,
              color: _ExpatHomeColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatesContent(TextTheme textTheme) {
    var estates = _estateList
        .where((e) {
          if (_selectedEstateFilter == 0) return true;
          if (_selectedEstateFilter == 1) return e.type == 'apartment';
          if (_selectedEstateFilter == 2) return e.type == 'house';
          if (_selectedEstateFilter == 3) return e.type == 'short_stay';
          return true;
        })
        .toList();
    if (_selectedEstateFilter == 0) {
      estates.sort((a, b) => a.title.compareTo(b.title));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              const BoxShadow(
                color: Color(0x26000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
              if (_estatesScrollOffset > 0) ..._tabBarShadow,
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _estateFilterOptions
                .map((opt) => _buildEstateFilterItem(textTheme, opt))
                .toList(),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child: ListView.builder(
            controller: _estatesScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: estates.length,
            itemBuilder: (context, index) {
              if (index > 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    _buildEstateCard(context, textTheme, estates[index]),
                  ],
                );
              }
              return _buildEstateCard(context, textTheme, estates[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstateFilterItem(TextTheme textTheme, _EstateFilterOption option) {
    final bool selected = _selectedEstateFilter == option.index;
    return GestureDetector(
      onTap: () => setState(() => _selectedEstateFilter = option.index),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: textTheme.titleMedium?.copyWith(
                color: selected
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

  static List<_Estate> get _estateList => [
        // Apartments
        const _Estate(
          title: 'Elizabeth Golf Apartments',
          location: 'KG 439 Street, Kigali',
          price: '\$2,430/mo',
          type: 'apartment',
          imagePath: 'assets/images/Apartments/Elizabeth G Apartments/1.jpg',
          description: """Elizabeth Golf Apartment by Link in Kigali offers a garden, open-air bath, indoor swimming pool, and free Wi-Fi. Guests enjoy a lounge, lift, 24-hour front desk, and free on-site private parking.

The apartment features a kitchenette, balcony, washing machine, private bathroom, and city views. Additional amenities include a dining area, a work desk, and free Wi-Fi.

Located 7 km from Kigali International Airport, the property is a 12-minute walk from Kigali Golf Club. Nearby attractions include Niyo Arts Gallery (3.2 km) and Kigali Convention Centre (5 km).""",
        ),
        const _Estate(
          title: 'Greenland Apartments',
          location: '249 KN 3 Street, Kigali',
          price: '\$2,025/mo',
          type: 'apartment',
          imagePath: 'assets/images/Apartments/Greenland Apartments/1.jpg',
          description: """Greenland Apartment by Link in Kigali offers a terrace and free Wi-Fi. The apartment features a balcony with city views, a fully equipped kitchen, and a private bathroom.

Guests benefit from a fitness room, lift, 24-hour front desk, daily housekeeping, family rooms, full-day security, and luggage storage. Free on-site private parking is available.

Located 9 km from Kigali International Airport, the apartment is near Belgian Peacekeepers Memorial (2 km), Kigali City Tower (less than 1 km), and Kandt House Natural History Museum (1.9 km).""",
        ),
        const _Estate(
          title: 'IZA Serene Apartments',
          location: 'ECD Plaza, Kigali',
          price: '\$1,842/mo',
          type: 'apartment',
          imagePath: 'assets/images/Apartments/IZA Serene Apartments/1.jpg',
          description: """IZA Serene city centre apartments in Kigali offer spacious apartments with terraces, balconies, and city views. Each apartment includes air-conditioning, a fully equipped kitchen, and a private bathroom.

Guests can enjoy African and international cuisines at the on-site restaurant, which serves vegetarian meals for lunch and dinner. The terrace provides a relaxing outdoor space, complemented by free Wi-Fi throughout the property.

Located 11 km from Kigali International Airport, the apartments are close to attractions such as the Belgian Peacekeepers Memorial (7-minute walk), Kandt House Natural History Museum (1.5 km), and Kigali City Tower (15-minute walk). Free on-site private parking is available.""",
        ),
        const _Estate(
          title: 'Rose Garden Apartments',
          location: 'KG 9 Avenue, Nyarutarama, Gasabo, Kigali',
          price: '\$1,485/mo',
          type: 'apartment',
          imagePath: 'assets/images/Apartments/Rose Garden Apartments/1.jpg',
          description: """Rose Garden Private Apartment by LINK in Kigali offers aparthotel-style accommodation with a garden and terrace. Guests enjoy free Wi-Fi, ensuring connectivity throughout their stay.

Each apartment features a kitchenette, a balcony with city views, a washing machine, and a private bathroom. Additional amenities include a fitness room, a lift, a 24-hour front desk, concierge service, and free on-site parking.

Located 5 km from Kigali International Airport, the property is an 8-minute walk from Kigali Golf Club. Nearby attractions include Niyo Arts Gallery (3.5 km) and Kigali Convention Centre (4.1 km). Guests appreciate the attentive staff and room cleanliness.""",
        ),
        const _Estate(
          title: 'AGASARO Apartments',
          location: 'KG 768, Kigali',
          price: '\$1,480/mo',
          type: 'apartment',
          imagePath: 'assets/images/Apartments/AGASARO Apartments/1.jpg',
          description: """AGASARO LUXURY Apartment in Kigali offers a spacious two-bedroom apartment with two bathrooms. The living room features a sofa bed and a work desk, ensuring comfort and convenience.

Guests can relax in the year-round outdoor swimming pool with a view or enjoy the terrace and garden. The property includes a restaurant, bar, and free Wi-Fi, providing ample leisure options.

The family-friendly restaurant serves African, Dutch, British, Ethiopian, French, American, Argentinian, Belgian, and Brazilian cuisines. Breakfast is continental with fruits, and lunch and dinner are available.

Located 10 km from Kigali International Airport, the apartment is near attractions such as Kigali Genocide Memorial (3.5 km) and Kigali Golf Club (4.5 km). Free on-site private parking is provided.""",
        ),

        // Houses
        const _Estate(
          title: '3-Bedroom Villa',
          location: '25CR+V6P, Kigali',
          price: '\$1,575/mo',
          type: 'house',
          imagePath: 'assets/images/Houses/3-Bedroom Villa/1.jpg',
          description: """Rose Garden Luxury, Unique 3 Bedrooms House in Kigali offers a villa with three bedrooms and three bathrooms. Guests enjoy a spacious garden and terrace, complemented by free Wi-Fi throughout the property.

The villa features a fully equipped kitchen, a balcony with mountain views, a washing machine, and a dining area. Additional amenities include a 24-hour front desk, a minimarket, a hairdresser/beautician, and family rooms.

Located 5 km from Kigali International Airport, the property is close to attractions such as the Presidential Palace Museum (3.2 km) and Kigali Golf Club (15 km). Free on-site private parking is available.""",
        ),
        const _Estate(
          title: 'Green Valley Villa',
          location: '49 KG 706 Street 1, Kigali',
          price: '\$2,754/mo',
          type: 'house',
          imagePath: 'assets/images/Houses/Green Valley Villa/1.jpg',
          description: """Green Valley Residence By Serenova Retreats in Kigali offers a spacious villa with four bedrooms and three bathrooms. The property includes a living room, dining area, and a fully equipped kitchen.

Guests enjoy free WiFi, a terrace, balcony, and a kitchenette. Additional amenities include a washing machine, dishwasher, microwave, and a work desk. Free on-site private parking is available.

Located 9 km from Kigali International Airport, the villa is 1.9 km from the Kigali Genocide Memorial. Nearby attractions include Kigali Centenary Park (3.7 km) and Nyamata Genocide Museum (33 km).""",
        ),
        const _Estate(
          title: 'JAMOS Guest House',
          location: 'Kigali-Gatuna Road, Kigali',
          price: '\$4,200/mo',
          type: 'house',
          imagePath: 'assets/images/Houses/JAMOS Guest House/1.jpg',
          description: """JAMOS Gest House in Kigali offers a spacious, adults-only villa with eight bedrooms and eight bathrooms. The property features a living room, private check-in and check-out services, and a 24-hour front desk.

Guests can enjoy a sun terrace, bar, and free Wi-Fi. Additional amenities include an outdoor fireplace, lounge, coffee shop, and outdoor seating area. Free on-site private parking is available.

Located 15 km from Kigali International Airport, the villa is near attractions such as Niyo Arts Gallery (8 km) and Kigali Genocide Memorial (7 km). The surrounding area offers mountain and city views.""",
        ),
        const _Estate(
          title: '5-Bedroom Villa',
          location: '6 KG 323 Street, Kigali',
          price: '\$7,650/mo',
          type: 'house',
          imagePath: 'assets/images/Houses/5-Bedroom Villa/1.jpg',
          description: """5 - Bedroom Villa in Kigali offers a spacious layout with five bedrooms and five bathrooms. The property includes a living room and family rooms, ensuring comfort for all guests.

The villa provides free Wi-Fi, a fully equipped kitchen, a washing machine, and a dishwasher. Additional amenities include a dining area, TV, and outdoor furniture.

Located 5 km from Kigali International Airport and Kigali Convention Centre, the property is also close to attractions such as Kigali Golf Club (3.3 km) and Kigali Genocide Memorial (8 km).""",
        ),
        const _Estate(
          title: "Villa d'exception Rebero",
          location: 'Rebero KK 857 St 13, Kigali',
          price: '\$2,693/mo',
          type: 'house',
          imagePath: 'assets/images/Houses/Villa Rebero/1.jpg',
          description: """Villa d'exception Rebero in Kigali offers a spacious layout with five bedrooms and four bathrooms. The property includes a living room and family rooms, ensuring comfort for all guests.

The villa features free Wi-Fi, a fully equipped kitchen, a washing machine, and a seating area. Additional amenities include a balcony, TV, and private entrance.

Located 9 km from Kigali International Airport, the villa is close to attractions such as Kigali Centenary Park and Kigali Genocide Memorial, each 8 km away. Free on-site private parking is available.""",
        ),

        // Short-Stay
        const _Estate(
          title: 'Cascadia Hotel',
          location: '7 KG 203 St, Kigali',
          price: '\$110/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/Cascadia Hotel/1.jpg',
          description: """Cascadia Hotel Apartments by GF Greenland in Kigali offers family rooms with private bathrooms, air-conditioning, and modern amenities. Each room includes a balcony or terrace with pool or city views.

Guests can enjoy a rooftop swimming pool, indoor pool, fitness centre, and a lush garden. Additional facilities include a restaurant, bar, outdoor fireplace, and a business area.

Located 1.8 km from Kigali Convention Centre and 3 km from Kigali International Airport, the hotel is near attractions such as Kigali Centenary Park and Nyamata Genocide Museum.""",
        ),
        const _Estate(
          title: 'Mythos Boutique Hotel',
          location: 'KN 50 Street Kiyovu, Kigali',
          price: '\$112/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/Mythos Boutique Hotel/1.jpg',
          description: """Mythos Boutique Hotel in Kigali offers family rooms with garden, pool, or mountain views. Each room includes air-conditioning, a private bathroom, and modern amenities.

Guests enjoy a swimming pool with a view, fitness centre, sun terrace, and lush garden. The hotel features a restaurant, bar, and free Wi-Fi, ensuring a pleasant stay.

Located 9 km from Kigali International Airport, the hotel is near attractions such as Kigali Centenary Park (3.2 km) and Kigali Genocide Memorial (6 km). Free on-site private parking is available.""",
        ),
        const _Estate(
          title: 'Peponi Living Hotel',
          location: 'KG 729 Street Kagugu, Kigali',
          price: '\$50/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/Peponi Living Hotel/1.jpg',
          description: """Peponi offers accommodation in Kigali. Guests can enjoy the on-site restaurant. Certain rooms feature a seating area to relax in after a busy day. The property offers a flat screen TV in all living rooms.

Kigali International Community School is 1.9 km from Peponi, while Big Local food Market is 2.4 km away. The nearest airport is Kigali International Airport, 8 km from Peponi.""",
        ),
        const _Estate(
          title: 'REBERO Resort',
          location: 'KK 30 Avenue, Kigali',
          price: '\$80/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/REBERO Resort/1.jpg',
          description: """REBERO RESORT Ltd in Kigali offers an adults-only hotel with a rooftop swimming pool, sun terrace, and lush garden. Guests enjoy free Wi-Fi, a fitness centre, and complimentary bicycles.

The property features a restaurant, bar, and coffee shop. Additional facilities include a hot tub, outdoor play area, and themed dinner nights. Free airport shuttle service is available 9 km from Kigali International Airport.

Located on a quiet street, the hotel offers mountain and city views. Nearby attractions include the Belgian Peacekeepers Memorial (8 km) and Kigali Convention Centre (9 km). Guests appreciate the attentive staff and scenic surroundings.""",
        ),
        const _Estate(
          title: 'Centric Hotel',
          location: 'KG 213 Street, Kigali',
          price: '\$100/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/Centric Hotel/1.jpg',
          description: """Centric Hotel in Kigali offers family rooms with private bathrooms, air-conditioning, and free Wi-Fi. Each room includes a work desk, TV, and modern amenities.

Guests can enjoy a terrace, restaurant, and bar. The family-friendly restaurant serves African, American, Italian, and Thai cuisines. Additional facilities include a lounge, outdoor seating area, and live music.

Located 3 km from Kigali International Airport, the hotel is near attractions such as Kigali Convention Centre (3.6 km) and Kigali Genocide Memorial (10 km). Free on-site parking is available.""",
        ),
        const _Estate(
          title: 'M Hotel',
          location: 'KN 1 Avenue Kiyovu, Kigali',
          price: '\$200/night',
          type: 'short_stay',
          imagePath: 'assets/images/Short-Stay/M Hotel/1.jpg',
          description: """M Hotel Kigali in Kigali offers comfortable rooms with air-conditioning, private bathrooms, and modern amenities. Each room features a balcony with garden or mountain views, ensuring a pleasant stay.

The family-friendly restaurant serves African, Chinese, Indian, and local cuisines in a traditional and modern setting. Breakfast includes continental and buffet options with local specialities, fresh pastries, and more.

Located 9 km from Kigali International Airport, the hotel is a 15-minute walk from Kigali City Tower. Nearby attractions include the Belgian Peacekeepers Memorial and Kigali Genocide Memorial, each within 3 km.""",
        ),
      ];

  // Listings kept aside for future testing (currently not shown in UI):
  // const _Estate(
  //   title: 'Phoenix Apartments',
  //   location: 'KG 768, Kigali',
  //   price: '\$2,309/mo',
  //   type: 'apartment',
  //   imagePath: 'assets/images/Apartments/Phoenix Apartment/1.jpg',
  // ),
  // const _Estate(
  //   title: 'Comfort Deluxe Apartments',
  //   location: 'KG 10 Avenue, Kigali',
  //   price: '\$2,040/mo',
  //   type: 'apartment',
  //   imagePath: 'assets/images/Apartments/Comfort Deluxe Apartments/1.jpg',
  // ),
  // const _Estate(
  //   title: 'Kigali Luxury Home',
  //   location: 'KK 15 Road, Kigali',
  //   price: '\$5,355/mo',
  //   type: 'house',
  //   imagePath: 'assets/images/Houses/Kigali Home/1.jpg',
  // ),
  // const _Estate(
  //   title: 'Gloria Hotel',
  //   location: 'KN 59 ST, Kigali',
  //   price: '\$120/night',
  //   type: 'short_stay',
  //   imagePath: 'assets/images/Short-Stay/Gloria Hotel/1.jpg',
  // ),
  // const _Estate(
  //   title: 'Olympic Hotel',
  //   location: 'KG 11 Ave, Kigali',
  //   price: '\$80/night',
  //   type: 'short_stay',
  //   imagePath: 'assets/images/Short-Stay/Olympic Hotel/1.jpg',
  // );

  Widget _buildEstateCard(
    BuildContext context,
    TextTheme textTheme,
    _Estate estate,
  ) {
    final typeLabel = estate.type == 'short_stay'
        ? 'Short-Stay'
        : estate.type == 'apartment'
            ? 'Apartment'
            : 'House';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              title: estate.title,
              location: estate.location,
              price: estate.price,
              typeLabel: typeLabel,
              imagePaths: [estate.imagePath],
              description: estate.description,
              // Placeholder UPI for Expat workflow; real UPI
              // will only be shown to landlords/agents later.
              upi: 'RHA Land UPI (placeholder)',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                estate.imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.home, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estate.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estate.location,
                        style: textTheme.bodySmall?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _ExpatHomeColors.helper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: _ExpatHomeColors.bodyText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPriceText(textTheme, estate.price),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _ExpatHomeColors.accentGreen,
                      foregroundColor: _ExpatHomeColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Get a Ride',
                      style: textTheme.titleMedium?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _ExpatHomeColors.exploreYellow,
                      foregroundColor: _ExpatHomeColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Explore Area',
                      style: textTheme.titleMedium?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                        color: _ExpatHomeColors.roleBlue,
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
                        color: const Color(0xFF1A2E35),
                      ),
                    ),
                  ],
                ),
                Text(
                  comment.role,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatHomeColors.roleBlue,
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
      decoration: BoxDecoration(
        color: _ExpatHomeColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 64,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomItem(
                textTheme,
                index: 0,
                imagePath: 'assets/images/Community Icon.png',
                label: 'Community',
              ),
              _buildBottomItem(
                textTheme,
                index: 1,
                imagePath: 'assets/images/Rides Icon.png',
                label: 'Rides',
              ),
              _buildBottomItem(
                textTheme,
                index: 2,
                imagePath: 'assets/images/Estates Icon.png',
                label: 'Estates',
              ),
              _buildBottomItem(
                textTheme,
                index: 3,
                imagePath: 'assets/images/Messages icon.png',
                label: 'Messages',
              ),
              _buildBottomItem(
                textTheme,
                index: 4,
                imagePath: 'assets/images/Explore Icon.png',
                label: 'Explore',
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    TextTheme textTheme, {
    required int index,
    required String imagePath,
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
          Image.asset(
            imagePath,
            width: 22,
            height: 22,
            color: color,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 22, color: color),
          ),
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

class _EstateFilterOption {
  const _EstateFilterOption({required this.label, required this.index});
  final String label;
  final int index;
}

class _Estate {
  const _Estate({
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.imagePath,
    required this.description,
  });

  final String title;
  final String location;
  final String price;
  final String type; // 'apartment' | 'house' | 'short_stay'
  final String imagePath;
   // Long-form listing description shown on the detail page.
  final String description;
}
