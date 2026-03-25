import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/models/post.dart';
import 'package:expat_app/models/bowl.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/services/community_service.dart';
import 'package:expat_app/services/bowls_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';
import 'listing_detail_screen.dart';
import 'messages_screen.dart' show MessagesScreen, kRoleExpat;
import 'package:expat_app/widgets/bowl_cover_avatar.dart';
import 'package:expat_app/widgets/community_post_composer_sheet.dart';
import 'package:expat_app/widgets/post_media_gallery.dart';
import 'expat_map_explore_screen.dart';
import 'expat_post_thread_screen.dart';
import 'expat_bowl_thread_screen.dart';
import 'account_profile_screen.dart';

/// Palette for Expat home screen; mirrors auth/signup colors.
class _ExpatHomeColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color hint = Color(0xFF9CA5A8);
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
  int _selectedEstateFilter =
      0; // 0 = All, 1 = Apartments, 2 = Houses, 3 = Short-Stay
  String _estateSearchQuery = '';
  final TextEditingController _estateSearchController = TextEditingController();

  final ScrollController _feedScrollController = ScrollController();
  final ScrollController _bowlsScrollController = ScrollController();
  final ScrollController _estatesScrollController = ScrollController();
  double _feedScrollOffset = 0;
  double _bowlsScrollOffset = 0;
  double _estatesScrollOffset = 0;
  late final Stream<List<Listing>> _publishedListingsStream;
  late final Stream<List<Post>> _feedPostsStream;
  String? _uid;
  String _userName = '';
  String _userRole = 'Expat';
  String? _userProfileImageUrl;

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
    _publishedListingsStream = ListingsService().publishedListingsStream();
    _feedPostsStream = CommunityService().feedPostsStream();
    _uid = AuthService().currentUser?.uid;
    _loadUserProfile();
    BowlsService().seedDefaultBowls();
    _feedScrollController.addListener(_onFeedScroll);
    _bowlsScrollController.addListener(_onBowlsScroll);
    _estatesScrollController.addListener(_onEstatesScroll);
  }

  Future<void> _loadUserProfile() async {
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
    final hadShadow = _feedScrollOffset > 0;
    final hasShadow = o > 0;
    if (hadShadow != hasShadow) {
      setState(() => _feedScrollOffset = o);
    } else if (_feedScrollOffset != o) {
      _feedScrollOffset = o;
    }
  }

  void _onBowlsScroll() {
    final o = _bowlsScrollController.offset;
    final hadShadow = _bowlsScrollOffset > 0;
    final hasShadow = o > 0;
    if (hadShadow != hasShadow) {
      setState(() => _bowlsScrollOffset = o);
    } else if (_bowlsScrollOffset != o) {
      _bowlsScrollOffset = o;
    }
  }

  void _onEstatesScroll() {
    final o = _estatesScrollController.offset;
    // Only rebuild when crossing zero so the header shadow show/hide updates; avoids refresh-like rebuilds on every scroll.
    final hadShadow = _estatesScrollOffset > 0;
    final hasShadow = o > 0;
    if (hadShadow != hasShadow) {
      setState(() => _estatesScrollOffset = o);
    } else if (_estatesScrollOffset != o) {
      _estatesScrollOffset = o;
    }
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
            child:
                _selectedBottomIndex == 0
                    ? Column(
                      children: [
                        _buildTabBar(textTheme),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        Expanded(
                          child: Stack(
                            children: [
                              _selectedTabIndex == 0
                                  ? _buildFeedList(textTheme)
                                  : _buildBowlsContent(textTheme),
                              if (_selectedTabIndex == 0)
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: _buildShareExperienceButton(textTheme),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : _selectedBottomIndex == 1
                    ? const ExpatMapExploreScreen(
                        key: ValueKey<String>('expat_map_rides'),
                        mode: ExpatMapTabMode.rides,
                      )
                    : _selectedBottomIndex == 2
                    ? _buildEstatesContentWithStream(textTheme)
                    : _selectedBottomIndex == 3
                    ? MessagesScreen(currentUserRole: kRoleExpat)
                    : _selectedBottomIndex == 4
                    ? const ExpatMapExploreScreen(
                        key: ValueKey<String>('expat_map_explore'),
                        mode: ExpatMapTabMode.explore,
                      )
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
      bottomNavigationBar: _buildBottomNav(textTheme),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    final mapMode =
        _selectedBottomIndex == 1 || _selectedBottomIndex == 4;
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
            SizedBox(width: mapMode ? 12 : 8),
            if (mapMode)
              Expanded(child: _buildSearchBar(textTheme))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 140,
                  maxWidth: 220,
                ),
                child: _buildSearchBar(textTheme),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.notifications_none, color: Colors.white),
            const SizedBox(width: 4),
            _buildProfileMenu(textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({double radius = 16}) {
    if (_userProfileImageUrl != null && _userProfileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_userProfileImageUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _ExpatHomeColors.accentGreen,
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _ExpatHomeColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildProfileMenu(TextTheme textTheme) {
    return GestureDetector(
      onTap: () => _openAccountProfile(),
      child: _buildProfileAvatar(),
    );
  }

  void _openAccountProfile() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AccountProfileScreen(role: UserRole.expat),
          ),
        )
        .then((_) {
          if (mounted) _loadUserProfile();
        });
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
    final showShadow =
        (_selectedTabIndex == 0 && _feedScrollOffset > 0) ||
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
    return StreamBuilder<List<Post>>(
      stream: _feedPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return ListView(
            controller: _feedScrollController,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  'No posts yet.\nBe the first to share your experience!',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _ExpatHomeColors.helper,
                  ),
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          controller: _feedScrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: posts.length,
          separatorBuilder:
              (_, __) => const Column(
                children: [
                  SizedBox(height: 24),
                  Divider(height: 1, color: Color(0xFFE0E0E0)),
                ],
              ),
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExpatPostThreadScreen(postId: post.id),
                  ),
                );
              },
              child: _buildPostCard(textTheme, post),
            );
          },
        );
      },
    );
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

  Widget _buildPostCard(TextTheme textTheme, Post post) {
    final liked = _uid != null && post.isLikedBy(_uid!);
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
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    post.authorImageUrl != null &&
                            post.authorImageUrl!.isNotEmpty
                        ? NetworkImage(post.authorImageUrl!)
                        : null,
                child:
                    post.authorImageUrl == null || post.authorImageUrl!.isEmpty
                        ? Text(
                          post.authorName.isNotEmpty
                              ? post.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _ExpatHomeColors.bodyText,
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
                        color: _ExpatHomeColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      post.authorRole,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.roleBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: _ExpatHomeColors.helper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: textTheme.bodyMedium?.copyWith(
              color: _ExpatHomeColors.bodyText,
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
                      color:
                          liked ? Colors.redAccent : _ExpatHomeColors.bodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.likeCount > 0 ? '${post.likeCount}' : 'Like',
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExpatPostThreadScreen(postId: post.id),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: _ExpatHomeColors.bodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.commentCount > 0
                          ? '${post.commentCount}'
                          : 'Comment',
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBowlsContent(TextTheme textTheme) {
    if (_uid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<Bowl>>(
      stream: BowlsService().allBowlsStream(),
      builder: (context, allSnap) {
        if (allSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allBowls = allSnap.data ?? [];
        return StreamBuilder<Set<String>>(
          stream: BowlsService().userBowlIdsStream(_uid!),
          builder: (context, memberSnap) {
            final joinedIds = memberSnap.data ?? {};
            final myBowls =
                allBowls.where((b) => joinedIds.contains(b.id)).toList();
            final otherBowls =
                allBowls.where((b) => !joinedIds.contains(b.id)).toList();

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
                if (myBowls.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'You haven\'t joined any bowls yet.',
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.helper,
                      ),
                    ),
                  ),
                ...myBowls.expand(
                  (bowl) => [
                    _buildBowlRow(textTheme, bowl, joined: true),
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
                const SizedBox(height: 12),
                if (otherBowls.isEmpty)
                  Center(
                    child: Text(
                      "No more bowls to discover right now.\nNew bowls are created as the community grows.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: _ExpatHomeColors.bodyText,
                      ),
                    ),
                  ),
                ...otherBowls.expand(
                  (bowl) => [
                    _buildBowlRow(textTheme, bowl, joined: false),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBowlRow(TextTheme textTheme, Bowl bowl, {required bool joined}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExpatBowlThreadScreen(bowlId: bowl.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BowlCoverAvatar(
              bowl: bowl,
              radius: 20,
              nameColor: _ExpatHomeColors.bodyText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bowl.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: _ExpatHomeColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bowl.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: _ExpatHomeColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            if (!joined)
              TextButton(
                onPressed: () {
                  if (_uid != null) {
                    BowlsService().joinBowl(bowl.id, _uid!);
                  }
                },
                child: const Text('Join'),
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
      stream: _publishedListingsStream,
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
          list =
              list
                  .where(
                    (l) =>
                        l.title.toLowerCase().contains(q) ||
                        l.location.toLowerCase().contains(q) ||
                        l.description.toLowerCase().contains(q),
                  )
                  .toList();
        }
        if (_selectedEstateFilter == 0) {
          list = List.from(list)..sort((a, b) => a.title.compareTo(b.title));
        }
        return _buildEstatesContentFromList(
          textTheme,
          list,
          snapshot.connectionState,
        );
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
                  hintStyle: TextStyle(
                    color: _ExpatHomeColors.hint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    _estateFilterOptions
                        .map((opt) => _buildEstateFilterItem(textTheme, opt))
                        .toList(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child:
              connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : estates.isEmpty
                  ? Center(
                    child: Text(
                      'No published listings yet.\n(Set status to "published" in Firestore to see them here.)',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _ExpatHomeColors.helper,
                      ),
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
                            _buildEstateCardFromListing(
                              context,
                              textTheme,
                              estates[index],
                            ),
                          ],
                        );
                      }
                      return _buildEstateCardFromListing(
                        context,
                        textTheme,
                        estates[index],
                      );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    _buildListingPriceRichText(
                      textTheme,
                      estate.type,
                      estate.price,
                    ),
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
        child: const Center(
          child: Icon(Icons.home, size: 48, color: Colors.grey),
        ),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Container(
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
      errorBuilder:
          (_, __, ___) => Container(
            height: height,
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.home, size: 48)),
          ),
    );
  }

  /// Bold `$amount` + smaller `/per month` or `/per night` (reference design).
  Widget _buildListingPriceRichText(
    TextTheme textTheme,
    ListingType type,
    String rawPrice,
  ) {
    final p = splitListingPriceForDisplay(type, rawPrice);
    return RichText(
      text: TextSpan(
        style: textTheme.titleSmall?.copyWith(color: _ExpatHomeColors.bodyText),
        children: [
          TextSpan(
            text: p.amountWithSymbol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _ExpatHomeColors.bodyText,
            ),
          ),
          TextSpan(
            text: p.slashSuffix,
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

  Widget _buildEstateFilterItem(
    TextTheme textTheme,
    _EstateFilterOption option,
  ) {
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
          title: 'Share your experience',
          accentGreen: _ExpatHomeColors.accentGreen,
          primaryDark: _ExpatHomeColors.primaryDark,
          helper: _ExpatHomeColors.helper,
          bodyText: _ExpatHomeColors.bodyText,
          onSubmit: (content, images) async {
            if (_uid == null) return;
            await CommunityService().createPost(
              authorId: _uid!,
              authorName: _userName,
              authorRole: _userRole,
              content: content,
              imageFiles: images.isNotEmpty ? images : null,
              authorImageUrl: _userProfileImageUrl,
            );
          },
        );
      },
    );
  }

  Widget _buildShareExperienceButton(TextTheme textTheme) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 56,
      width: (width * 0.58).clamp(200.0, width - 32),
      child: ElevatedButton(
        onPressed: _showCreatePostDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ExpatHomeColors.accentGreen,
          foregroundColor: _ExpatHomeColors.primaryDark,
          elevation: 6,
          side: const BorderSide(color: _ExpatHomeColors.primaryDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  'Share your experience',
                  maxLines: 1,
                  style: textTheme.titleMedium?.copyWith(
                    color: _ExpatHomeColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.add,
              size: 24,
              color: _ExpatHomeColors.primaryDark,
            ),
          ],
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
            errorBuilder:
                (_, __, ___) => Icon(Icons.circle, size: 22, color: color),
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

class _EstateFilterOption {
  const _EstateFilterOption({required this.label, required this.index});
  final String label;
  final int index;
}
