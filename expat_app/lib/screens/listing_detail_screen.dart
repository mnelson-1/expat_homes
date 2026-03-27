import 'package:flutter/material.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/listing_edit_request.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/conversations_service.dart';
import 'package:expat_app/services/edit_requests_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/models/listing_assignment.dart';
import 'package:expat_app/utils/listing_price_display.dart';
import 'landlord_make_listing_screen.dart';
import 'messages_screen.dart' show ConversationScreen, kRoleAgent, kRoleExpat;

/// Detail page for a single estate listing.
/// This will later be wired up to real data from the backend.
class ListingDetailScreen extends StatelessWidget {
  ListingDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.listingType,
    required this.typeLabel,
    required this.imagePaths,
    required this.description,
    this.upi,
    this.isVerifiedByRdb = true,
    this.representativeName,
    this.showRequestEditOnly = false,
    this.showAgentActions = false,
    /// Firestore `listing_assignments` doc id for this agent + listing (when [showAgentActions]).
    this.agentAssignmentId,
    /// When [showAgentActions] and [agentAssignmentId] set: show Accept next to Decline (pending only).
    this.agentShowsAcceptButton = false,
    this.listingId,
    /// Expat "Inquire" recipient: representative UID or landlord. Agent flows may use [listingOwnerUid] for Chat Landlord.
    this.landlordId,
    /// Listing document `landlordId` (owner). Agent "Chat Landlord" must use this so [getOrCreateConversation] matches the original thread.
    this.listingOwnerUid,
    this.onListingAccepted,
    this.onListingDeclined,
    this.editRequest,
    this.onRequestEdit,
    /// Super admin: show landlord email / phone / uid from `users/{landlordId}`.
    this.showLandlordContactSection = false,
    this.landlordContactUid,
  });

  final String title;
  final String location;

  /// Raw value from Firestore (often digits only); formatted with [listingType].
  final String price;
  final ListingType listingType;
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

  /// When true (agent view), bottom bar shows agent actions (not expat enquire UI).
  final bool showAgentActions;

  /// Assignment document id for Accept/Decline API; null → only "Chat Landlord".
  final String? agentAssignmentId;

  /// Pending assignment: Decline + Accept row. Accepted: full-width Decline only.
  final bool agentShowsAcceptButton;

  /// When opening from agent Listings; used to notify when listing is accepted.
  final String? listingId;

  /// Primary messaging peer for Expat inquire (representative or landlord).
  final String? landlordId;

  /// Owner's Firebase UID from listing (always the landlord). Used for agent ↔ landlord chat.
  final String? listingOwnerUid;

  /// Called when agent taps Accept (so the listing can move to Accepted tab).
  final void Function(String listingId)? onListingAccepted;

  /// Called when agent taps Decline (so the listing is removed from Pending).
  final void Function(String listingId)? onListingDeclined;

  /// Current edit request for this listing (landlord view only). Controls which
  /// action the bottom button performs.
  final ListingEditRequest? editRequest;

  /// Called when landlord taps "Request Edit" — opens the edit form.
  final void Function()? onRequestEdit;

  /// When true (super admin), loads and shows [landlordContactUid] profile block.
  final bool showLandlordContactSection;

  /// Firestore user id of the listing owner (landlord).
  final String? landlordContactUid;

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
                    if (showLandlordContactSection &&
                        landlordContactUid != null &&
                        landlordContactUid!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _LandlordContactAdminPanel(
                        landlordUid: landlordContactUid!.trim(),
                      ),
                    ],
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
        builder:
            (context, showShadow, _) =>
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
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
    final count = imagePaths.isEmpty ? 1 : imagePaths.length;
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: count,
            itemBuilder: (context, index) {
              if (imagePaths.isEmpty) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.home, size: 64, color: Colors.grey),
                  ),
                );
              }
              final path = imagePaths[index];
              final isNetwork = path.startsWith('http');
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child:
                    isNetwork
                        ? Image.network(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Container(color: Colors.grey.shade300),
                        )
                        : Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
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
                  count,
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

  Widget _buildPriceAndType(TextTheme textTheme) {
    final priceParts = splitListingPriceForDisplay(listingType, price);

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
                      text: priceParts.amountWithSymbol,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: priceParts.slashSuffix,
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
      final reqStatus = editRequest?.status;

      // Prevent requesting edits until the super admin has published the listing.
      if (!isVerifiedByRdb) {
        const label = 'Verification Pending';
        const bgColor = Color(0xFFFFD54F);
        const fgColor = Color(0xFF1A2E35);

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
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    disabledBackgroundColor: bgColor,
                    disabledForegroundColor: fgColor,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final String label;
      final Color bgColor;
      final Color fgColor;
      final VoidCallback? action;

      if (reqStatus == EditRequestStatus.pending) {
        label = 'Edit Request being Processed';
        bgColor = const Color(0xFFFFD54F);
        fgColor = const Color(0xFF1A2E35);
        action = null;
      } else if (reqStatus == EditRequestStatus.approved) {
        final er = editRequest;
        if (er != null && er.showsLandlordApprovedBanner) {
          label = 'Edit Request Approved';
          bgColor = const Color(0xFF8ED966);
          fgColor = const Color(0xFF1A2E35);
          action = () async {
            try {
              await EditRequestsService().landlordAcknowledgeApprovedEdit(
                er.id,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update: $e')),
                );
              }
            }
          };
        } else {
          label = 'Request Edit';
          bgColor = const Color(0xFF1A2E35);
          fgColor = Colors.white;
          action = onRequestEdit;
        }
      } else {
        label = 'Request Edit';
        bgColor = const Color(0xFF1A2E35);
        fgColor = Colors.white;
        action = onRequestEdit;
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow:
              showShadow
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
                onPressed: action,
                style: FilledButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  disabledBackgroundColor: bgColor,
                  disabledForegroundColor: fgColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (showAgentActions) {
      final hasAssignment = agentAssignmentId != null;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow:
              showShadow
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
                if (hasAssignment && agentShowsAcceptButton)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            ListingDetailScreen.showListingDeclinedDialog(
                              context,
                              textTheme,
                              () async {
                                if (listingId != null) {
                                  if (onListingDeclined != null) {
                                    onListingDeclined!.call(listingId!);
                                  } else if (agentAssignmentId != null) {
                                    await AgentsService().declineAssignment(
                                      agentAssignmentId!,
                                    );
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
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
                              () async {
                                if (listingId != null) {
                                  if (onListingAccepted != null) {
                                    onListingAccepted!.call(listingId!);
                                  } else if (agentAssignmentId != null) {
                                    await AgentsService().acceptAssignment(
                                      agentAssignmentId!,
                                    );
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
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
                if (hasAssignment && !agentShowsAcceptButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ListingDetailScreen.showListingDeclinedDialog(
                          context,
                          textTheme,
                          () async {
                            if (listingId != null) {
                              if (onListingDeclined != null) {
                                onListingDeclined!.call(listingId!);
                              } else if (agentAssignmentId != null) {
                                await AgentsService().declineAssignment(
                                  agentAssignmentId!,
                                );
                              }
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
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
                ],
                if (hasAssignment) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final myUid = AuthService().currentUser?.uid;
                      final landlordUid = (listingOwnerUid != null &&
                              listingOwnerUid!.trim().isNotEmpty)
                          ? listingOwnerUid!.trim()
                          : landlordId;
                      if (myUid == null ||
                          listingId == null ||
                          landlordUid == null ||
                          landlordUid.isEmpty) {
                        return;
                      }

                      final myProfile =
                          await AuthService().getCurrentUserProfile();
                      final myName = myProfile?.legalName ?? 'Agent';
                      final landlordProfile =
                          await AuthService().getUserProfile(landlordUid);
                      final landlordName =
                          landlordProfile?.legalName ?? 'Landlord';

                      final convo = await ConversationsService()
                          .getOrCreateConversation(
                            listingId: listingId!,
                            participantIds: [myUid, landlordUid],
                            participantNames: {
                              myUid: myName,
                              landlordUid: landlordName,
                            },
                            listingTitle: title,
                            listingImage:
                                imagePaths.isNotEmpty ? imagePaths.first : '',
                            listingPrice: formatListingPricePlain(
                              listingType,
                              price,
                            ),
                            listingLocation: location,
                            sharedLandlordAgentThread: true,
                          );

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => ConversationScreen(
                                conversationId: convo.id,
                                listingId: listingId!,
                                listingTitle: title,
                                location: location,
                                price: formatListingPricePlain(
                                  listingType,
                                  price,
                                ),
                                imagePath:
                                    imagePaths.isNotEmpty
                                        ? imagePaths.first
                                        : '',
                                contactName: landlordName,
                                contactUid: landlordUid,
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
        boxShadow:
            showShadow
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
                        Navigator.of(context).pop<String>(location);
                      },
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
                  onPressed: () async {
                    final myUid = AuthService().currentUser?.uid;
                    if (myUid == null || listingId == null || landlordId == null) {
                      return;
                    }

                    const defaultInquiryMessage =
                        'Hey there! I would like to get more\ninformation on this Listing.';
                    final contactName = representativeName ?? 'Representative';

                    final myProfile =
                        await AuthService().getCurrentUserProfile();
                    final myName = myProfile?.legalName ?? 'Expat';

                    final convo = await ConversationsService()
                        .getOrCreateConversation(
                          listingId: listingId!,
                          participantIds: [myUid, landlordId!],
                          participantNames: {
                            myUid: myName,
                            landlordId!: contactName,
                          },
                          listingTitle: title,
                          listingImage:
                              imagePaths.isNotEmpty ? imagePaths.first : '',
                          listingPrice: formatListingPricePlain(
                            listingType,
                            price,
                          ),
                          listingLocation: location,
                        );

                    // Only send the default inquiry on first contact.
                    if (convo.lastMessage == null) {
                      await ConversationsService().sendMessage(
                        conversationId: convo.id,
                        senderId: myUid,
                        content: defaultInquiryMessage,
                      );
                    }

                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => ConversationScreen(
                              conversationId: convo.id,
                              listingId: listingId!,
                              listingTitle: title,
                              location: location,
                              price: formatListingPricePlain(
                                listingType,
                                price,
                              ),
                              imagePath:
                                  imagePaths.isNotEmpty ? imagePaths.first : '',
                              contactName: contactName,
                              contactUid: landlordId,
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
                      fontSize: (textTheme.titleMedium?.fontSize ?? 16) + 1,
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

/// Loads landlord profile for super-admin verification (email, optional phone, uid).
class _LandlordContactAdminPanel extends StatelessWidget {
  const _LandlordContactAdminPanel({required this.landlordUid});

  final String landlordUid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<UserProfile?>(
      future: AuthService().getUserProfile(landlordUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final p = snap.data;
        if (p == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Could not load landlord profile.',
              style: textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          );
        }
        final phoneStr =
            (p.phone != null && p.phone!.trim().isNotEmpty)
                ? p.phone!.trim()
                : '—';

        Widget row(String label, String value) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1A2E35),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 20,
                      color: Color(0xFF1A2E35),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Landlord (admin)',
                      style: textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF1A2E35),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                row('Name', p.legalName),
                row('Email', p.email.isEmpty ? '—' : p.email),
                row('Phone', phoneStr),
                row('User ID', p.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loads a listing by id from Firestore and shows [ListingDetailScreen].
/// Use for landlord "My Listings" and expat Estates when opening by id.
/// When [showRequestEditOnly] is true, also streams the edit request and revision
/// state to drive the contextual action button.
class ListingDetailScreenById extends StatefulWidget {
  const ListingDetailScreenById({
    super.key,
    required this.listingId,
    this.showRequestEditOnly = false,
    this.showAgentActions = false,
    this.onListingAccepted,
    this.onListingDeclined,
  });

  final String listingId;
  final bool showRequestEditOnly;
  final bool showAgentActions;
  final void Function(String listingId)? onListingAccepted;
  final void Function(String listingId)? onListingDeclined;

  @override
  State<ListingDetailScreenById> createState() =>
      _ListingDetailScreenByIdState();
}

class _ListingDetailBootstrap {
  _ListingDetailBootstrap({
    required this.listing,
    this.agentAssignmentId,
    required this.agentShowsAcceptButton,
    this.showLandlordContactForAdmin = false,
    this.landlordContactUid,
  });

  final Listing listing;
  final String? agentAssignmentId;
  final bool agentShowsAcceptButton;
  final bool showLandlordContactForAdmin;
  final String? landlordContactUid;
}

class _ListingDetailScreenByIdState extends State<ListingDetailScreenById> {
  late final Future<_ListingDetailBootstrap?> _bootstrapFuture =
      _loadBootstrap();

  Future<_ListingDetailBootstrap?> _loadBootstrap() async {
    final listing =
        await ListingsService().getListingByIdWithRepresentative(
      widget.listingId,
    );
    if (listing == null) return null;

    String? agentAid;
    var agentShowAccept = false;
    if (widget.showAgentActions) {
      final assn = await AgentsService().getActiveAssignment(widget.listingId);
      final uid = AuthService().currentUser?.uid;
      if (assn != null && assn.agentUid == uid) {
        agentAid = assn.id;
        agentShowAccept = assn.status == AssignmentStatus.pending;
      }
    }

    final me = await AuthService().getCurrentUserProfile();
    final landlordUid = listing.landlordId.trim();
    final showLandlordAdmin =
        me?.role == UserRole.superAdmin && landlordUid.isNotEmpty;

    return _ListingDetailBootstrap(
      listing: listing,
      agentAssignmentId: agentAid,
      agentShowsAcceptButton: agentShowAccept,
      showLandlordContactForAdmin: showLandlordAdmin,
      landlordContactUid: showLandlordAdmin ? landlordUid : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ListingDetailBootstrap?>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Listing')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Something went wrong.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final payload = snapshot.data;
        if (payload == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Listing')),
            body: const Center(child: Text('Listing not found.')),
          );
        }
        final listing = payload.listing;
        final imagePaths =
            listing.mediaUrls.isEmpty ? <String>[] : listing.mediaUrls;

        if (widget.showRequestEditOnly) {
          return StreamBuilder<ListingEditRequest?>(
            stream: EditRequestsService().listingEditRequestStream(
              widget.listingId,
            ),
            builder: (context, reqSnap) {
              return _buildDetail(
                context,
                listing,
                imagePaths,
                editRequest: reqSnap.data,
                agentAssignmentId: payload.agentAssignmentId,
                agentShowsAcceptButton: payload.agentShowsAcceptButton,
                showLandlordContactForAdmin: payload.showLandlordContactForAdmin,
                landlordContactUid: payload.landlordContactUid,
              );
            },
          );
        }

        return _buildDetail(
          context,
          listing,
          imagePaths,
          agentAssignmentId: payload.agentAssignmentId,
          agentShowsAcceptButton: payload.agentShowsAcceptButton,
          showLandlordContactForAdmin: payload.showLandlordContactForAdmin,
          landlordContactUid: payload.landlordContactUid,
        );
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    Listing listing,
    List<String> imagePaths, {
    ListingEditRequest? editRequest,
    String? agentAssignmentId,
    bool agentShowsAcceptButton = false,
    bool showLandlordContactForAdmin = false,
    String? landlordContactUid,
  }) {
    return ListingDetailScreen(
      title: listing.title,
      location: listing.location,
      price: listing.price,
      listingType: listing.type,
      typeLabel: listing.typeLabel,
      imagePaths: imagePaths,
      description: listing.description,
      upi: listing.upi,
      isVerifiedByRdb:
          listing.status == ListingStatus.published &&
              listing.verifiedBy != null,
      representativeName: listing.representativeName,
      showRequestEditOnly: widget.showRequestEditOnly,
      showAgentActions: widget.showAgentActions,
      agentAssignmentId: agentAssignmentId,
      agentShowsAcceptButton: agentShowsAcceptButton,
      listingId: widget.listingId,
      landlordId: listing.representativeUid ?? listing.landlordId,
      listingOwnerUid:
          listing.landlordId.trim().isEmpty ? null : listing.landlordId,
      onListingAccepted: widget.onListingAccepted,
      onListingDeclined: widget.onListingDeclined,
      editRequest: editRequest,
      onRequestEdit: () => _handleRequestEdit(context, listing),
      showLandlordContactSection: showLandlordContactForAdmin,
      landlordContactUid: landlordContactUid,
    );
  }

  void _handleRequestEdit(BuildContext context, Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => LandlordMakeListingScreen(
              isEdit: true,
              listingId: widget.listingId,
              initialTitle: listing.title,
              initialPrice: listing.price,
              initialLocation: listing.location,
              initialDescription: listing.description,
              initialUpi: listing.upi,
              initialOwnerName: listing.representativeName,
            ),
      ),
    );
  }
}
