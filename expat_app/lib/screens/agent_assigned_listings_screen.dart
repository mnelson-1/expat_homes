import 'package:flutter/material.dart';

import 'listing_detail_screen.dart';

/// Assigned listings for agents: filter by type, accept or decline each assignment.
class AgentAssignedListingsScreen extends StatefulWidget {
  const AgentAssignedListingsScreen({super.key});

  @override
  State<AgentAssignedListingsScreen> createState() =>
      _AgentAssignedListingsScreenState();
}

class _AgentAssignedListingsColors {
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color declineRed = Color(0xFFC62828);

  /// Accepted tab: single button — blue text, yellow container.
  static const Color acceptedButtonYellow = Color(0xFFFFD54F);
}

class _AssignedListing {
  const _AssignedListing({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.priceSuffix,
    required this.type,
    required this.imagePath,
    required this.description,
    required this.upi,
  });
  final String id;
  final String title;
  final String location;
  final String price;
  final String priceSuffix;
  final String type; // apartment | house | short_stay
  final String imagePath;
  final String description;
  final String upi;
}

class _AgentAssignedListingsScreenState
    extends State<AgentAssignedListingsScreen> {
  int _selectedMainTab = 0; // 0 = Pending, 1 = Accepted
  int _selectedFilter =
      0; // 0 = All, 1 = Apartments, 2 = Houses, 3 = Short-Stay
  final Set<String> _acceptedIds = {};
  final Set<String> _declinedIds = {};
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const List<String> _mainTabLabels = ['Pending', 'Accepted'];

  static const List<String> _filterLabels = [
    'All',
    'Apartments',
    'Houses',
    'Short-Stay',
  ];

  static final List<_AssignedListing> _listings = [
    _AssignedListing(
      id: '1',
      title: 'Charm Nest Apartments',
      location: 'KG 286, Kigali Rwanda',
      price: '\$857',
      priceSuffix: '/mo',
      type: 'apartment',
      imagePath: 'assets/images/Apartments/Charm Nest Apartments/1.jpg',
      description:
          'Charm Nest Apartment by Link in Kigali offers a garden, open-air bath, indoor swimming pool, and free WiFi.',
      upi: 'KG286-APARTMENT-UPI-001',
    ),
    _AssignedListing(
      id: '2',
      title: 'Green Valley Villa',
      location: '49 KG 706 Street 1, Kigali',
      price: '\$2,754',
      priceSuffix: '/mo',
      type: 'house',
      imagePath: 'assets/images/Houses/Green Valley Villa/1.jpg',
      description:
          'Green Valley Villa in Kigali offers a spacious home with multiple bedrooms and private bathrooms.',
      upi: 'KG706-VILLA-UPI-002',
    ),
    _AssignedListing(
      id: '3',
      title: 'Olympic Hotel',
      location: 'KG 11 AVE, Kigali Rwanda',
      price: '\$1,796',
      priceSuffix: '/night',
      type: 'short_stay',
      imagePath: 'assets/images/Short-Stay/Olympic Hotel/1.jpg',
      description:
          'Olympic Hotel in Kigali provides hotel-style rooms with on-site dining and conference facilities.',
      upi: 'KG11-HOTEL-UPI-003',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset =
          _scrollController.hasClients ? _scrollController.offset : 0;
    });
  }

  List<_AssignedListing> get _filteredListings {
    // Pending: not yet accepted and not declined; Accepted: accepted by agent.
    // Declined listings disappear from both tabs.
    final byTab =
        _selectedMainTab == 0
            ? _listings
                .where(
                  (e) =>
                      !_acceptedIds.contains(e.id) &&
                      !_declinedIds.contains(e.id),
                )
                .toList()
            : _listings.where((e) => _acceptedIds.contains(e.id)).toList();
    if (_selectedFilter == 0) return byTab;
    final key =
        _selectedFilter == 1
            ? 'apartment'
            : _selectedFilter == 2
            ? 'house'
            : 'short_stay';
    return byTab.where((e) => e.type == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final listings = _filteredListings;
    final isAcceptedTab = _selectedMainTab == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 48, child: Center(child: _buildMainTabs(textTheme))),
        _buildFilterBar(textTheme),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              if (index > 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    _buildListingCard(
                      context,
                      textTheme,
                      listings[index],
                      isAcceptedTab,
                    ),
                  ],
                );
              }
              return _buildListingCard(
                context,
                textTheme,
                listings[index],
                isAcceptedTab,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _mainTabLabels.length,
        (index) => _buildMainTabItem(textTheme, index),
      ),
    );
  }

  Widget _buildMainTabItem(TextTheme textTheme, int index) {
    final selected = index == _selectedMainTab;
    final label = _mainTabLabels[index];
    return GestureDetector(
      onTap: () => setState(() => _selectedMainTab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color:
                selected
                    ? _AgentAssignedListingsColors.bodyText
                    : _AgentAssignedListingsColors.hint,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static const List<BoxShadow> _tabBarShadow = [
    BoxShadow(
      color: Color(0x15000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  Widget _buildFilterBar(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          if (_scrollOffset > 0) ..._tabBarShadow,
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _filterLabels.length,
          (index) => _buildFilterChip(textTheme, index),
        ),
      ),
    );
  }

  Widget _buildFilterChip(TextTheme textTheme, int index) {
    final selected = index == _selectedFilter;
    final label = _filterLabels[index];
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color:
                    selected
                        ? _AgentAssignedListingsColors.bodyText
                        : _AgentAssignedListingsColors.hint,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              color:
                  selected
                      ? _AgentAssignedListingsColors.bodyText
                      : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  /// Normalizes price suffix for display: "per month" -> "mo", "per night" -> "night".
  static String _normalizePriceSuffix(String suffix) {
    final s = suffix.replaceFirst('/', '').trim().toLowerCase();
    if (s == 'per month') return '/mo';
    if (s == 'per night') return '/night';
    return suffix;
  }

  Widget _buildListingCard(
    BuildContext context,
    TextTheme textTheme,
    _AssignedListing listing,
    bool isAcceptedTab,
  ) {
    final typeLabel =
        listing.type == 'apartment'
            ? 'Apartment'
            : listing.type == 'house'
            ? 'House'
            : 'Short-Stay';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => ListingDetailScreen(
                  title: listing.title,
                  location: listing.location,
                  price:
                      '${listing.price}${_normalizePriceSuffix(listing.priceSuffix)}',
                  typeLabel: typeLabel,
                  imagePaths: [listing.imagePath],
                  description: listing.description,
                  upi: listing.upi,
                  isVerifiedByRdb: true,
                  representativeName: 'Landlord of ${listing.title}',
                  showRequestEditOnly: false,
                  showAgentActions: !isAcceptedTab,
                  listingId: listing.id,
                  onListingAccepted: (id) {
                    setState(() => _acceptedIds.add(id));
                  },
                  onListingDeclined: (id) {
                    setState(() => _declinedIds.add(id));
                  },
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
                listing.imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
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
                        listing.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: _AgentAssignedListingsColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.location,
                        style: textTheme.bodySmall?.copyWith(
                          color: _AgentAssignedListingsColors.bodyText,
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
                        color: _AgentAssignedListingsColors.helper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: _AgentAssignedListingsColors.bodyText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: textTheme.titleSmall?.copyWith(
                          color: _AgentAssignedListingsColors.bodyText,
                        ),
                        children: [
                          TextSpan(
                            text: listing.price,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: _normalizePriceSuffix(listing.priceSuffix),
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: textTheme.bodySmall?.fontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            isAcceptedTab
                ? SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _AgentAssignedListingsColors.acceptedButtonYellow,
                      foregroundColor: _AgentAssignedListingsColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Accepted',
                      style: textTheme.titleMedium?.copyWith(
                        color: _AgentAssignedListingsColors.bodyText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _declinedIds.add(listing.id));
                          ListingDetailScreen.showListingDeclinedDialog(
                            context,
                            textTheme,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _AgentAssignedListingsColors.declineRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _acceptedIds.add(listing.id));
                          ListingDetailScreen.showListingAcceptedDialog(
                            context,
                            textTheme,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _AgentAssignedListingsColors.accentGreen,
                          foregroundColor:
                              _AgentAssignedListingsColors.bodyText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(
                          'Accept',
                          style: textTheme.titleMedium?.copyWith(
                            color: _AgentAssignedListingsColors.bodyText,
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
}
