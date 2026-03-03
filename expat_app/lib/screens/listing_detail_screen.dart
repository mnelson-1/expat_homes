import 'package:flutter/material.dart';

import 'landlord_make_listing_screen.dart';
import 'messages_screen.dart';

/// Detail page for a single estate listing.
/// This will later be wired up to real data from the backend.
class ListingDetailScreen extends StatelessWidget {
  ListingDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.typeLabel,
    required this.imagePaths,
    required this.description,
    this.upi,
    this.isVerifiedByRdb = true,
    this.representativeName,
    this.showRequestEditOnly = false,
    this.showAgentActions = false,
    this.listingId,
    this.onListingAccepted,
    this.onListingDeclined,
  });

  final String title;
  final String location;
  final String price; // e.g. "\$2268/mo"
  final String typeLabel; // e.g. "Apartment", "House", "Short-Stay"
  final List<String> imagePaths;
  final String description;
  /// Optional house UPI (placeholder for now in Expat flow).
  final String? upi;
  final bool isVerifiedByRdb;
  /// Optional agent/landlord representative; when null, the section is hidden.
  final String? representativeName;
  /// When true (landlord view), bottom bar shows only a single "Request Edit" button.
  final bool showRequestEditOnly;
  /// When true (agent view), bottom bar shows Decline, Accept, and Chat Landlord.
  final bool showAgentActions;
  /// When opening from agent Listings; used to notify when listing is accepted.
  final String? listingId;
  /// Called when agent taps Accept (so the listing can move to Accepted tab).
  final void Function(String listingId)? onListingAccepted;
  /// Called when agent taps Decline (so the listing is removed from Pending).
  final void Function(String listingId)? onListingDeclined;

  // Tracks whether content has been scrolled to show a drop shadow above buttons.
  final ValueNotifier<bool> _showBottomShadow = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = PageController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.vertical) {
                  final metrics = notification.metrics;
                  // Show shadow whenever content is scrollable and
                  // we're NOT at the very bottom. At the bottom, hide it.
                  final bool showShadow =
                      metrics.maxScrollExtent > 0 &&
                      metrics.pixels < metrics.maxScrollExtent;
                  if (_showBottomShadow.value != showShadow) {
                    _showBottomShadow.value = showShadow;
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(controller),
                    _buildPriceAndType(textTheme),
                    _buildLocationAndVerification(textTheme),
                    const SizedBox(height: 16),
                    _buildDescriptionBlock(textTheme),
                    const SizedBox(height: 16),
                    _buildRepresentative(textTheme),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _showBottomShadow,
        builder: (context, showShadow, _) =>
            _buildBottomActions(context, textTheme, showShadow: showShadow),
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
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(PageController controller) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final path = imagePaths[index];
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(
                  imagePaths.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normalizes price suffix for display: "per month" -> "mo", "per night" -> "night".
  static String _normalizePriceSuffix(String suffix) {
    final s = suffix.trim().toLowerCase();
    if (s == 'per month') return 'mo';
    if (s == 'per night') return 'night';
    return suffix;
  }

  Widget _buildPriceAndType(TextTheme textTheme) {
    final parts = price.split('/');
    final amount = parts.isNotEmpty ? parts[0] : price;
    final rawSuffix = parts.length > 1 ? parts[1] : '';
    final suffix = rawSuffix.isEmpty ? '' : '/${_normalizePriceSuffix(rawSuffix)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                  children: [
                    TextSpan(
                      text: amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (suffix.isNotEmpty)
                      TextSpan(
                        text: suffix,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF1A2E35),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9CA5A8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              typeLabel,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1A2E35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndVerification(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
          const SizedBox(height: 8),
          if (isVerifiedByRdb)
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: Color(0xFF1976D2)),
                const SizedBox(width: 4),
                Text(
                  'Listing and Location Verified by the RDB',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          if (upi != null && upi!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'House UPI: $upi',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9CA5A8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionBlock(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1A2E35),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentative(TextTheme textTheme) {
    if (representativeName == null || representativeName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Color(0xFF1A2E35)),
              const SizedBox(width: 6),
              Text(
                'Representative:',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A2E35),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  representativeName!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    TextTheme textTheme, {
    required bool showShadow,
  }) {
    if (showRequestEditOnly) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: showShadow
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, -6),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LandlordMakeListingScreen(
                        isEdit: true,
                        initialTitle: title,
                        initialPrice: price,
                        initialLocation: location,
                        initialDescription: description,
                        // UPI and owner name will be provided later
                        // when backend data is available.
                        initialUpi: null,
                        initialOwnerName: representativeName,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2E35),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  'Request Edit',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (showAgentActions) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: showShadow
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, -6),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ListingDetailScreen.showListingDeclinedDialog(
                            context,
                            textTheme,
                            () {
                              if (listingId != null) {
                                onListingDeclined?.call(listingId!);
                              }
                              Navigator.of(context).pop();
                            },
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ListingDetailScreen.showListingAcceptedDialog(
                            context,
                            textTheme,
                            () {
                              if (listingId != null) {
                                onListingAccepted?.call(listingId!);
                              }
                              Navigator.of(context).pop();
                            },
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8ED966),
                          foregroundColor: const Color(0xFF1A2E35),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(
                          'Accept',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E35),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      const landlordName = 'Landlord';
                      final subtitle = 'Landlord of $title';
                      addOrUpdateChatThreadForAgentLandlordChat(
                        contactName: landlordName,
                        listingTitle: title,
                        location: location,
                        price: price,
                        imagePath: imagePaths.isNotEmpty
                            ? imagePaths.first
                            : '',
                      );
                      final initialMessage =
                          getLastMessageForAgentLandlordChat(
                        listingTitle: title,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationScreen(
                            listingTitle: title,
                            location: location,
                            price: price,
                            imagePath: imagePaths.isNotEmpty
                                ? imagePaths.first
                                : '',
                            contactName: landlordName,
                            contactSubtitle: subtitle,
                            initialMessage: initialMessage,
                            storedMessages: getStoredMessagesForThread(
                                landlordName, subtitle, title),
                            showInitialAsIncoming: true,
                            listingFromOtherParty: true,
                            returnToLandlordOnBack: false,
                            returnToAgentMessagesOnBack: true,
                            listingDetailRole: kRoleAgent,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: const Color(0xFF1A2E35),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Chat Landlord',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, -6),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2E35),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Get a Ride',
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
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF1A2E35),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Explore Area',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    const defaultInquiryMessage =
                        'Hey there! I would like to get more\ninformation on this Listing.';
                    final contactName = representativeName ?? 'Representative';
                    final contactSubtitle = 'Representative';
                    addOrUpdateChatThreadForExpatInquiry(
                      contactName: contactName,
                      contactSubtitle: contactSubtitle,
                      listingTitle: title,
                      location: location,
                      price: price,
                      imagePath: imagePaths.isNotEmpty
                          ? imagePaths.first
                          : '',
                      lastMessage: defaultInquiryMessage,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ConversationScreen(
                          listingTitle: title,
                          location: location,
                          price: price,
                          imagePath: imagePaths.isNotEmpty
                              ? imagePaths.first
                              : '',
                          contactName: contactName,
                          contactSubtitle: contactSubtitle,
                          initialMessage: defaultInquiryMessage,
                          storedMessages: getStoredMessagesForThread(
                              contactName, contactSubtitle, title),
                          returnToLandlordOnBack: false,
                          listingDetailRole: kRoleExpat,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8ED966),
                    foregroundColor: const Color(0xFF1A2E35),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    'Inquire',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          (textTheme.titleMedium?.fontSize ?? 16) + 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Color _agentAcceptGreen = Color(0xFF8ED966);
  static const Color _agentDeclineRed = Color(0xFFC62828);
  /// Body text blue used in Assignment Successful and other modals.
  static const Color _agentDialogBodyBlue = Color(0xFF1A2E35);

  /// Shows the "Listing Accepted" pop-up. [onClose] is called after the dialog
  /// is dismissed (e.g. pass () => Navigator.pop(context) when opened from
  /// listing detail so the detail is closed too).
  static void showListingAcceptedDialog(
    BuildContext context,
    TextTheme textTheme, [
    void Function()? onClose,
  ]) {
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
              color: _agentAcceptGreen,
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
                      color: _agentDialogBodyBlue,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onClose?.call();
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listing Accepted',
                  style: textTheme.titleLarge?.copyWith(
                    color: _agentDialogBodyBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Any and all enquiries for this listing will be redirected to you.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _agentDialogBodyBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _agentDialogBodyBlue,
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

  /// Shows the "Listing Declined" pop-up. [onClose] is called after the
  /// dialog is dismissed.
  static void showListingDeclinedDialog(
    BuildContext context,
    TextTheme textTheme, [
    void Function()? onClose,
  ]) {
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
              color: _agentDeclineRed,
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
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onClose?.call();
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listing Declined',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Any and all other related Listings will be removed from your feed.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _agentDialogBodyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

