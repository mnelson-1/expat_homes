import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/listing_assignment.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';
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
  static const Color acceptedButtonYellow = Color(0xFFFFD54F);
}

class _AgentAssignedListingsScreenState
    extends State<AgentAssignedListingsScreen> {
  int _selectedMainTab = 0; // 0 = Pending, 1 = Accepted
  int _selectedFilter = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const List<String> _mainTabLabels = ['Pending', 'Accepted'];
  static const List<String> _filterLabels = [
    'All',
    'Apartments',
    'Houses',
    'Short-Stay',
  ];

  String? _agentUid;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _agentUid = AuthService().currentUser?.uid;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final newOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((_scrollOffset > 0) != (newOffset > 0)) {
      setState(() => _scrollOffset = newOffset);
    } else {
      _scrollOffset = newOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 48, child: Center(child: _buildMainTabs(textTheme))),
        _buildFilterBar(textTheme),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(child: _buildAssignmentsList(textTheme)),
      ],
    );
  }

  Widget _buildAssignmentsList(TextTheme textTheme) {
    if (_agentUid == null) {
      return const Center(child: Text('Not signed in.'));
    }

    final status = _selectedMainTab == 0
        ? AssignmentStatus.pending
        : AssignmentStatus.accepted;

    return StreamBuilder<List<ListingAssignment>>(
      stream:
          AgentsService().agentAssignmentsStream(_agentUid!, status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _selectedMainTab == 0
                    ? 'No pending assignments.'
                    : 'No accepted assignments.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                    color: _AgentAssignedListingsColors.hint),
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _AssignmentCard(
              key: ValueKey(assignment.id),
              assignment: assignment,
              isAcceptedTab: _selectedMainTab == 1,
              selectedFilter: _selectedFilter,
              onAccepted: () async {
                await AgentsService().acceptAssignment(assignment.id);
                if (context.mounted) {
                  ListingDetailScreen.showListingAcceptedDialog(
                      context, textTheme);
                }
              },
              onDeclined: () async {
                await AgentsService().declineAssignment(assignment.id);
                if (context.mounted) {
                  ListingDetailScreen.showListingDeclinedDialog(
                      context, textTheme);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMainTabs(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _mainTabLabels.length,
        (index) {
          final selected = index == _selectedMainTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedMainTab = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _mainTabLabels[index],
                style: textTheme.titleMedium?.copyWith(
                  color: selected
                      ? _AgentAssignedListingsColors.bodyText
                      : _AgentAssignedListingsColors.hint,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 2),
              blurRadius: 4),
          if (_scrollOffset > 0)
            const BoxShadow(
                color: Color(0x15000000),
                offset: Offset(0, 4),
                blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _filterLabels.length,
          (index) {
            final selected = index == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _filterLabels[index],
                      style: textTheme.titleMedium?.copyWith(
                        color: selected
                            ? _AgentAssignedListingsColors.bodyText
                            : _AgentAssignedListingsColors.hint,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 2,
                      color: selected
                          ? _AgentAssignedListingsColors.bodyText
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Card for a single assignment. Fetches the listing data from Firestore.
class _AssignmentCard extends StatefulWidget {
  const _AssignmentCard({
    super.key,
    required this.assignment,
    required this.isAcceptedTab,
    required this.selectedFilter,
    required this.onAccepted,
    required this.onDeclined,
  });

  final ListingAssignment assignment;
  final bool isAcceptedTab;
  final int selectedFilter;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  Listing? _listing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchListing();
  }

  Future<void> _fetchListing() async {
    final listing = await ListingsService()
        .getListingByIdWithRepresentative(widget.assignment.listingId);
    if (mounted) {
      setState(() {
        _listing = listing;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final listing = _listing;
    if (listing == null) return const SizedBox.shrink();

    // Apply type filter
    if (widget.selectedFilter != 0) {
      final key = widget.selectedFilter == 1
          ? ListingType.apartment
          : widget.selectedFilter == 2
              ? ListingType.house
              : ListingType.shortStay;
      if (listing.type != key) return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final imagePath = listing.mediaUrls.isNotEmpty
        ? listing.mediaUrls.first
        : 'assets/images/placeholder.png';
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final priceParts = splitListingPriceForDisplay(
      listing.type,
      listing.price,
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ListingDetailScreenById(
              listingId: listing.id,
              showAgentActions: !widget.isAcceptedTab,
              onListingAccepted: (_) => widget.onAccepted(),
              onListingDeclined: (_) => widget.onDeclined(),
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
              child: isNetwork
                  ? Image.network(imagePath,
                      height: 180, width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(imagePath,
                      height: 180, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.shade300,
                          child:
                              const Center(child: Icon(Icons.home, size: 48)))),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title,
                          style: textTheme.titleMedium?.copyWith(
                              color: _AgentAssignedListingsColors.bodyText,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(listing.location,
                          style: textTheme.bodySmall?.copyWith(
                              color: _AgentAssignedListingsColors.bodyText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _AgentAssignedListingsColors.helper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(listing.typeLabel,
                          style: textTheme.bodySmall?.copyWith(
                              color: _AgentAssignedListingsColors.bodyText)),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: textTheme.titleSmall?.copyWith(
                            color: _AgentAssignedListingsColors.bodyText),
                        children: [
                          TextSpan(
                              text: priceParts.amountWithSymbol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: priceParts.slashSuffix,
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: textTheme.bodySmall?.fontSize)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.isAcceptedTab
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _AgentAssignedListingsColors
                            .acceptedButtonYellow,
                        disabledBackgroundColor: _AgentAssignedListingsColors
                            .acceptedButtonYellow,
                        foregroundColor:
                            _AgentAssignedListingsColors.bodyText,
                        disabledForegroundColor:
                            _AgentAssignedListingsColors.bodyText,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                      ),
                      child: Text('Accepted',
                          style: textTheme.titleMedium?.copyWith(
                              color: _AgentAssignedListingsColors.bodyText,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.onDeclined,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _AgentAssignedListingsColors.declineRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7)),
                          ),
                          child: Text('Decline',
                              style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.onAccepted,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _AgentAssignedListingsColors.accentGreen,
                            foregroundColor:
                                _AgentAssignedListingsColors.bodyText,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7)),
                          ),
                          child: Text('Accept',
                              style: textTheme.titleMedium?.copyWith(
                                  color: _AgentAssignedListingsColors.bodyText,
                                  fontWeight: FontWeight.bold)),
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
