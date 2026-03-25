import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/conversations_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';
import 'messages_screen.dart' show ConversationScreen, kRoleLandlord;

/// Screen where a Landlord selects one of their listings
/// to assign to a chosen agent.
class LandlordAssignPropertyScreen extends StatefulWidget {
  const LandlordAssignPropertyScreen({
    super.key,
    required this.agentName,
    required this.agentId,
  });

  final String agentName;
  final String agentId;

  @override
  State<LandlordAssignPropertyScreen> createState() =>
      _LandlordAssignPropertyScreenState();
}

class _AssignColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color hint = Color(0xFF9CA5A8);
}

class _LandlordAssignPropertyScreenState
    extends State<LandlordAssignPropertyScreen> {
  int _selectedFilter = 0;
  Stream<List<Listing>>? _listingsStream;

  static const List<String> _filters = [
    'All',
    'Apartments',
    'Houses',
    'Short-Stay',
  ];

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      _listingsStream = ListingsService().landlordListingsStream(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _AssignColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Assign Property',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(textTheme),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(child: _buildListingsList(textTheme)),
        ],
      ),
    );
  }

  Widget _buildListingsList(TextTheme textTheme) {
    if (_listingsStream == null) {
      return const Center(child: Text('Not signed in'));
    }
    return StreamBuilder<List<Listing>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allListings = snapshot.data ?? [];
        final filtered = _applyFilter(allListings);

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No listings to assign.',
              style: textTheme.bodySmall?.copyWith(color: _AssignColors.hint),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final listing = filtered[index];
            if (index > 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildEstateCard(context, textTheme, listing),
                ],
              );
            }
            return _buildEstateCard(context, textTheme, listing);
          },
        );
      },
    );
  }

  List<Listing> _applyFilter(List<Listing> listings) {
    if (_selectedFilter == 0) return listings;
    final key = _selectedFilter == 1
        ? ListingType.apartment
        : _selectedFilter == 2
            ? ListingType.house
            : ListingType.shortStay;
    return listings.where((e) => e.type == key).toList();
  }

  Widget _buildFilters(TextTheme textTheme) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          _filters.length,
          (index) => _buildFilterItem(textTheme, index, _filters[index]),
        ),
      ),
    );
  }

  Widget _buildFilterItem(TextTheme textTheme, int index, String label) {
    final selected = index == _selectedFilter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: selected ? _AssignColors.bodyText : _AssignColors.hint,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: double.infinity,
              color: selected ? _AssignColors.bodyText : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstateCard(
    BuildContext context,
    TextTheme textTheme,
    Listing listing,
  ) {
    final imagePath = (listing.mediaUrls.isNotEmpty)
        ? listing.mediaUrls.first
        : 'assets/images/placeholder.png';
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final priceParts = splitListingPriceForDisplay(
      listing.type,
      listing.price,
    );

    return Padding(
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
                    errorBuilder: (_, __, ___) =>
                        Container(height: 180, color: Colors.grey.shade300)),
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
                            color: _AssignColors.bodyText,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(listing.location,
                        style: textTheme.bodySmall
                            ?.copyWith(color: _AssignColors.bodyText)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _AssignColors.hint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(listing.typeLabel,
                        style: textTheme.bodySmall
                            ?.copyWith(color: _AssignColors.bodyText)),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: priceParts.amountWithSymbol,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: textTheme.titleSmall?.fontSize,
                            color: _AssignColors.bodyText)),
                    TextSpan(
                        text: priceParts.slashSuffix,
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: textTheme.bodySmall?.fontSize,
                            color: _AssignColors.bodyText)),
                  ])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => _handleAssign(context, textTheme, listing),
              style: FilledButton.styleFrom(
                backgroundColor: _AssignColors.accentGreen,
                foregroundColor: _AssignColors.bodyText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
                textStyle: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              child: const Text('Assign'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAssign(
    BuildContext context,
    TextTheme textTheme,
    Listing listing,
  ) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final imagePath = listing.mediaUrls.isNotEmpty
        ? listing.mediaUrls.first
        : 'assets/images/placeholder.png';
    final priceWithSuffix =
        formatListingPricePlain(listing.type, listing.price);
    final message =
        'Hi ${widget.agentName}. I would like for you to represent me in the sale of this listing.';

    String? agentUidValue;
    try {
      agentUidValue = await AgentsService().getAgentUid(widget.agentId);
      await AgentsService().createAssignment(
        listingId: listing.id,
        agentId: widget.agentId,
        landlordId: uid,
        agentUid: agentUidValue,
        agentName: widget.agentName,
        listingTitle: listing.title,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }

    if (agentUidValue == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent has not registered yet.')),
      );
      return;
    }

    final myProfile = await AuthService().getCurrentUserProfile();
    final myName = myProfile?.legalName ?? 'Landlord';

    final convo = await ConversationsService().getOrCreateConversation(
      listingId: listing.id,
      participantIds: [uid, agentUidValue],
      participantNames: {uid: myName, agentUidValue: widget.agentName},
      listingTitle: listing.title,
      listingImage: imagePath,
      listingPrice: priceWithSuffix,
      listingLocation: listing.location,
    );

    await ConversationsService().sendMessage(
      conversationId: convo.id,
      senderId: uid,
      content: message,
    );

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: _AssignColors.accentGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: _AssignColors.bodyText, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationScreen(
                            conversationId: convo.id,
                            listingId: listing.id,
                            listingTitle: listing.title,
                            location: listing.location,
                            price: priceWithSuffix,
                            imagePath: imagePath,
                            contactName: widget.agentName,
                            contactUid: agentUidValue,
                            returnToLandlordOnBack: true,
                            listingDetailRole: kRoleLandlord,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assignment Successful',
                  style: textTheme.titleLarge?.copyWith(
                      color: _AssignColors.bodyText,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The agent has received your assignment. Once he accepts, the status of this listing will be updated.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: _AssignColors.bodyText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _AssignColors.bodyText,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
