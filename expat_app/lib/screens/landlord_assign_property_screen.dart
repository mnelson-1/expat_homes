import 'package:flutter/material.dart';

import 'messages_screen.dart'
    show ConversationScreen, addOrUpdateChatThreadForAgent,
        addOrUpdateChatThreadForAgentLandlordChat,
        getStoredMessagesForThread, kRoleLandlord;

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

class _AssignEstate {
  const _AssignEstate({
    required this.title,
    required this.location,
    required this.price,
    required this.priceSuffix,
    required this.typeLabel,
    required this.typeKey, // 'apartment' | 'house' | 'short_stay'
    required this.imagePath,
  });

  final String title;
  final String location;
  final String price;
  final String priceSuffix;
  final String typeLabel;
  final String typeKey;
  final String imagePath;
}

class _LandlordAssignPropertyScreenState
    extends State<LandlordAssignPropertyScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Apartments, 2 = Houses, 3 = Short-Stay

  static const List<String> _filters = [
    'All',
    'Apartments',
    'Houses',
    'Short-Stay',
  ];

  // Placeholder landlord listings; in a real app this would come from backend.
  static const List<_AssignEstate> _estates = [
    _AssignEstate(
      title: 'Charm Nest Apartments',
      location: 'KG 286, Kigali Rwanda',
      price: '\$857',
      priceSuffix: '/mo',
      typeLabel: 'Apartment',
      typeKey: 'apartment',
      imagePath: 'assets/images/Apartments/Charm Nest Apartments/1.jpg',
    ),
    _AssignEstate(
      title: 'Olympic Hotel',
      location: 'KG 11 AVE, Kigali Rwanda',
      price: '\$1796',
      priceSuffix: '/night',
      typeLabel: 'Short-Stay',
      typeKey: 'short_stay',
      imagePath: 'assets/images/Short-Stay/Olympic Hotel/1.jpg',
    ),
    _AssignEstate(
      title: 'Green Valley Villa',
      location: '49 KG 706 Street 1, Kigali',
      price: '\$2754',
      priceSuffix: '/mo',
      typeLabel: 'House',
      typeKey: 'house',
      imagePath: 'assets/images/Houses/Green Valley Villa/1.jpg',
    ),
  ];

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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: _filteredEstates.length,
              itemBuilder: (context, index) {
                final estate = _filteredEstates[index];
                if (index > 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      _buildEstateCard(context, textTheme, estate),
                    ],
                  );
                }
                return _buildEstateCard(context, textTheme, estate);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_AssignEstate> get _filteredEstates {
    if (_selectedFilter == 0) return _estates;
    final key = _selectedFilter == 1
        ? 'apartment'
        : _selectedFilter == 2
            ? 'house'
            : 'short_stay';
    return _estates.where((e) => e.typeKey == key).toList();
  }

  Widget _buildFilters(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
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

  Widget _buildFilterItem(
    TextTheme textTheme,
    int index,
    String label,
  ) {
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
                color:
                    selected ? _AssignColors.bodyText : _AssignColors.hint,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: double.infinity,
              color: selected
                  ? _AssignColors.bodyText
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstateCard(
    BuildContext context,
    TextTheme textTheme,
    _AssignEstate estate,
  ) {
    return Padding(
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
                        color: _AssignColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estate.location,
                      style: textTheme.bodySmall?.copyWith(
                        color: _AssignColors.bodyText,
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
                      color: _AssignColors.hint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estate.typeLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: _AssignColors.bodyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: estate.price,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: textTheme.titleSmall?.fontSize,
                            color: _AssignColors.bodyText,
                          ),
                        ),
                        TextSpan(
                          text: ' ${estate.priceSuffix}',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: textTheme.bodySmall?.fontSize,
                            color: _AssignColors.bodyText,
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
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => _handleAssign(context, textTheme, estate),
              style: FilledButton.styleFrom(
                backgroundColor: _AssignColors.accentGreen,
                foregroundColor: _AssignColors.bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Assign'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAssign(
    BuildContext context,
    TextTheme textTheme,
    _AssignEstate estate,
  ) {
    final priceWithSuffix = '${estate.price}${estate.priceSuffix}';

    final message =
        'Hi ${widget.agentName}. I would like for you to represent me in the sale of this listing.';

    addOrUpdateChatThreadForAgent(
      agentName: widget.agentName,
      agentId: widget.agentId,
      message: message,
      listingTitle: estate.title,
      location: estate.location,
      price: priceWithSuffix,
      imagePath: estate.imagePath,
    );
    addOrUpdateChatThreadForAgentLandlordChat(
      contactName: 'Landlord',
      listingTitle: estate.title,
      location: estate.location,
      price: priceWithSuffix,
      imagePath: estate.imagePath,
      lastMessage: message,
    );

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
                    icon: const Icon(
                      Icons.close,
                      color: _AssignColors.bodyText,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationScreen(
                            listingTitle: estate.title,
                            location: estate.location,
                            price: priceWithSuffix,
                            imagePath: estate.imagePath,
                            contactName: widget.agentName,
                            contactSubtitle: widget.agentId,
                            initialMessage: message,
                            storedMessages: getStoredMessagesForThread(
                                widget.agentName, widget.agentId, estate.title),
                            returnToLandlordOnBack: true,
                            showInitialAsIncoming: false,
                            listingFromOtherParty: false,
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
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The agent has received your assignment. Once he accepts, the status of this listing will be updated.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _AssignColors.bodyText,
                  ),
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
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

