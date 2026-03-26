import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:expat_app/models/commission_slip.dart';
import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/listing_assignment.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/utils/calendar_thread_labels.dart';
import 'package:expat_app/services/commission_slips_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';

class AgentPaymentsScreen extends StatefulWidget {
  const AgentPaymentsScreen({super.key});

  @override
  State<AgentPaymentsScreen> createState() => _AgentPaymentsScreenState();
}

class _AgentPaymentsColors {
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
}

enum _AgentCreateSlipStep { pickListing, form }

class _AgentPaymentsScreenState extends State<AgentPaymentsScreen> {
  int _selectedTab = 0;
  _AgentCreateSlipStep _createStep = _AgentCreateSlipStep.pickListing;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const List<BoxShadow> _headerShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 6),
      blurRadius: 10,
    ),
  ];

  final TextEditingController _commissionIdController = TextEditingController();
  final TextEditingController _landlordNameController = TextEditingController();
  final TextEditingController _estateNameController = TextEditingController();
  final TextEditingController _homeOwnerIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController(text: 'MTN Momo');
  final TextEditingController _phoneController = TextEditingController();

  String? _agentUid;
  Stream<List<CommissionSlip>>? _slipsStream;
  Stream<List<Listing>>? _acceptedListingsStream;
  StreamSubscription<User?>? _authSub;

  /// UPI/phone locks when pre-filled from listing / licensed agent.
  bool _upiNeedsManualEntry = false;
  bool _phoneReadOnly = false;
  /// Firestore listing id for the slip being created (one slip per listing).
  String? _formListingId;

  /// Listings the agent has an **accepted** assignment for (for commission slip picker).
  Stream<List<Listing>>? _makeAcceptedListingsStream(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    // Client-filter to accepted only so Firestore needs only the agentUid index.
    return AgentsService().agentAssignmentsStream(uid).asyncMap((assignments) async {
      final accepted = assignments
          .where((a) => a.status == AssignmentStatus.accepted)
          .toList();
      final withSlip =
          await CommissionSlipsService().listingIdsWithSlipForAgent(uid);
      final listings = <Listing>[];
      for (final a in accepted) {
        if (withSlip.contains(a.listingId)) continue;
        final listing = await ListingsService().getListingById(a.listingId);
        if (listing != null) listings.add(listing);
      }
      return listings;
    });
  }

  void _bindSlipsStream(String? uid) {
    _agentUid = uid;
    _slipsStream =
        uid != null && uid.isNotEmpty
            ? CommissionSlipsService().agentSlipsStream(uid)
            : null;
    _acceptedListingsStream = _makeAcceptedListingsStream(uid);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bindSlipsStream(AuthService().currentUser?.uid);
    _authSub = AuthService().authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _bindSlipsStream(user?.uid));
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commissionIdController.dispose();
    _landlordNameController.dispose();
    _estateNameController.dispose();
    _homeOwnerIdController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool showShadow = _scrollOffset > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: showShadow ? _headerShadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabSwitcher(textTheme),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _buildTrackTab(textTheme)
              : _buildCreateTabContent(textTheme),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _selectedTab == 0
                          ? _AgentPaymentsColors.bodyText
                          : _AgentPaymentsColors.helper,
                      fontWeight:
                          _selectedTab == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    color: _selectedTab == 0
                        ? _AgentPaymentsColors.accentGreen
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                  _resetCreateSlipFlow();
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _selectedTab == 1
                          ? _AgentPaymentsColors.bodyText
                          : _AgentPaymentsColors.helper,
                      fontWeight:
                          _selectedTab == 1 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    color: _selectedTab == 1
                        ? _AgentPaymentsColors.accentGreen
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTab(TextTheme textTheme) {
    if (_slipsStream == null) {
      return Center(
        child: Text(
          'Not signed in.',
          style: textTheme.bodySmall?.copyWith(
            color: _AgentPaymentsColors.helper,
          ),
        ),
      );
    }

    return StreamBuilder<List<CommissionSlip>>(
      stream: _slipsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final slips = snapshot.data ?? [];
        if (slips.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  'You have no commission slips yet.\nThey will appear here once created.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: _AgentPaymentsColors.helper,
                  ),
                ),
              ),
            ],
          );
        }

        final List<Widget> children = [];
        DateTime? lastDate;

        for (final slip in slips) {
          final date = slip.createdAt ?? DateTime.now();
          final isNewDate =
              lastDate == null || !isSameCalendarDay(lastDate, date);

          if (isNewDate) {
            if (lastDate != null) {
              children.add(const SizedBox(height: 18));
            }
            children.add(_buildDateHeader(textTheme, date));
            children.add(const SizedBox(height: 16));
            lastDate = dateOnlyLocal(date);
          } else {
            children.add(const Divider(height: 1, color: Color(0xFFE0E0E0)));
            children.add(const SizedBox(height: 12));
          }

          children.add(_buildPaymentCard(textTheme, slip));
          children.add(const SizedBox(height: 12));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          controller: _scrollController,
          children: children,
        );
      },
    );
  }

  Widget _buildDateHeader(TextTheme textTheme, DateTime date) {
    final label = threadDayDividerLabel(dateOnlyLocal(date), DateTime.now());
    return Center(
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: _AgentPaymentsColors.bodyText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TextTheme textTheme, CommissionSlip slip) {
    final isActionable =
        slip.status == SlipStatus.pending ||
        slip.status == SlipStatus.agentConfirmationPending;

    final Color statusColor;
    switch (slip.status) {
      case SlipStatus.confirmed:
        statusColor = _AgentPaymentsColors.accentGreen;
      case SlipStatus.reported:
        statusColor = const Color(0xFFC62828);
      default:
        statusColor = _AgentPaymentsColors.helper;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    slip.reference,
                    style: textTheme.titleSmall?.copyWith(
                      color: _AgentPaymentsColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      slip.status.displayLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${slip.contractCode} • ${slip.landlordName}',
                style: textTheme.bodySmall?.copyWith(
                  color: _AgentPaymentsColors.helper,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slip.listingTitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: _AgentPaymentsColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Due',
                        style: textTheme.bodySmall?.copyWith(
                          color: _AgentPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.amount,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _AgentPaymentsColors.bodyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: textTheme.bodySmall?.copyWith(
                          color: _AgentPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.paymentMethod,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _AgentPaymentsColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone No.',
                        style: textTheme.bodySmall?.copyWith(
                          color: _AgentPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.recipientPhone,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _AgentPaymentsColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isActionable) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => _confirmDeleteSlip(context, textTheme, slip),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () async {
                      await CommissionSlipsService().confirmSlip(slip.id);
                      if (!context.mounted) return;
                      _showPaymentConfirmedDialog();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _AgentPaymentsColors.accentGreen,
                      foregroundColor: _AgentPaymentsColors.bodyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCreateTabContent(TextTheme textTheme) {
    if (_createStep == _AgentCreateSlipStep.pickListing) {
      return _buildListingPicker(textTheme);
    }
    return _buildCreateForm(textTheme);
  }

  Widget _buildListingPicker(TextTheme textTheme) {
    if (_acceptedListingsStream == null) {
      return Center(
        child: Text(
          'Not signed in.',
          style: textTheme.bodySmall?.copyWith(
            color: _AgentPaymentsColors.helper,
          ),
        ),
      );
    }

    return StreamBuilder<List<Listing>>(
      stream: _acceptedListingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: [
              Text(
                'No accepted listings yet.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: _AgentPaymentsColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Commission slips can only be created for properties where you '
                'have accepted an assignment, and only one slip per listing. '
                'If every accepted listing already has a slip, delete one on '
                'the Track tab to create it again here.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: _AgentPaymentsColors.helper,
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final listing = listings[index];
            return _buildListingPickCard(textTheme, listing);
          },
        );
      },
    );
  }

  Widget _buildListingPickCard(TextTheme textTheme, Listing listing) {
    final imagePath = listing.mediaUrls.isNotEmpty
        ? listing.mediaUrls.first
        : 'assets/images/placeholder.png';
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final priceParts = splitListingPriceForDisplay(
      listing.type,
      listing.price,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(
                    imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 180, color: Colors.grey.shade300),
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
                        color: _AgentPaymentsColors.bodyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.location,
                      style: textTheme.bodySmall?.copyWith(
                        color: _AgentPaymentsColors.bodyText,
                      ),
                    ),
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
                      color: _AgentPaymentsColors.helper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      listing.typeLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: _AgentPaymentsColors.bodyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: priceParts.amountWithSymbol,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: textTheme.titleSmall?.fontSize,
                            color: _AgentPaymentsColors.bodyText,
                          ),
                        ),
                        TextSpan(
                          text: priceParts.slashSuffix,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: textTheme.bodySmall?.fontSize,
                            color: _AgentPaymentsColors.bodyText,
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
              onPressed: () => _onPickListingForSlip(listing),
              style: FilledButton.styleFrom(
                backgroundColor: _AgentPaymentsColors.accentGreen,
                foregroundColor: _AgentPaymentsColors.bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPickListingForSlip(Listing listing) async {
    final uid = _agentUid ?? AuthService().currentUser?.uid;
    if (uid != null &&
        uid.isNotEmpty &&
        await CommissionSlipsService().agentHasSlipForListing(uid, listing.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have a commission slip for this listing. Delete it first to create a new one.',
          ),
        ),
      );
      return;
    }

    final landlord = await AuthService().getUserProfile(listing.landlordId);
    final profile = await AuthService().getCurrentUserProfile();
    var phone = '';
    final aid = profile?.agentId;
    if (aid != null && aid.isNotEmpty) {
      final la = await AgentsService().getAgent(aid);
      phone = la?.phone?.trim() ?? '';
    }

    if (!mounted) return;
    final upi = listing.upi?.trim() ?? '';
    setState(() {
      _createStep = _AgentCreateSlipStep.form;
      _formListingId = listing.id;
      _upiNeedsManualEntry = upi.isEmpty;
      _estateNameController.text = listing.title;
      _commissionIdController.text = upi;
      _landlordNameController.text = landlord?.legalName ?? '';
      _homeOwnerIdController.text = listing.landlordId;
      _amountController.clear();
      _paymentMethodController.text = 'MTN Momo';
      _phoneController.text = phone;
      _phoneReadOnly = phone.isNotEmpty;
    });
  }

  Widget _buildCreateForm(TextTheme textTheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(_resetCreateSlipFlow);
              },
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              label: Text(
                'Choose another listing',
                style: textTheme.bodyMedium?.copyWith(
                  color: _AgentPaymentsColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLabel(textTheme, 'Property Title'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _estateNameController,
            hint: 'e.g 3–Bedroom Apartment etc.',
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'House UPI (Unique Parcel Identifier)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _commissionIdController,
            hint: 'RHA given Land UPI',
            readOnly: !_upiNeedsManualEntry,
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Home Owner'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _landlordNameController,
            hint: 'Landlord name',
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Home Owner ID'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _homeOwnerIdController,
            hint: 'ID of Landlord',
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Amount Due'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _amountController,
            hint: 'Price in RWF (Fx rate aware)',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Payment Method'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _paymentMethodController,
            hint: 'MTN Momo',
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Phone Number of Recipient'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'e.g 0798654987',
            keyboardType: TextInputType.phone,
            readOnly: _phoneReadOnly,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _handleCreateSlip,
              style: FilledButton.styleFrom(
                backgroundColor: _AgentPaymentsColors.accentGreen,
                foregroundColor: _AgentPaymentsColors.bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Create Commission Slip'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSlip(
    BuildContext context,
    TextTheme textTheme,
    CommissionSlip slip,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _AgentPaymentsColors.bodyText,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Delete commission slip?',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: Text(
            'This removes slip ${slip.reference} permanently. You can create '
            'a new slip for this listing afterwards.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await CommissionSlipsService().deleteSlip(slip.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission slip deleted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  String _formatAmountRwf(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return raw;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    final formatted = buffer.toString();
    return 'RWF$formatted';
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (_scrollOffset != offset) {
      setState(() => _scrollOffset = offset);
    }
  }

  Future<void> _handleCreateSlip() async {
    final propertyTitle = _estateNameController.text.trim();
    final houseUpi = _commissionIdController.text.trim();
    final landlord = _landlordNameController.text.trim();
    final ownerId = _homeOwnerIdController.text.trim();
    final amount = _amountController.text.trim();
    final method = _paymentMethodController.text.trim().isEmpty
        ? 'MTN Momo'
        : _paymentMethodController.text.trim();
    final phone = _phoneController.text.trim();

    if (propertyTitle.isEmpty ||
        houseUpi.isEmpty ||
        landlord.isEmpty ||
        ownerId.isEmpty ||
        amount.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields to create a commission slip.'),
        ),
      );
      return;
    }

    final formattedAmount = _formatAmountRwf(amount);
    final profile = await AuthService().getCurrentUserProfile();
    final agentName = profile?.legalName ?? 'Agent';
    final agentId = profile?.agentId ?? '';
    final uid = _agentUid ?? AuthService().currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a commission slip.'),
        ),
      );
      return;
    }

    final listingId = _formListingId?.trim() ?? '';
    if (listingId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a listing from the list before creating a slip.'),
        ),
      );
      return;
    }

    try {
      final created = await CommissionSlipsService().createSlip(
        listingId: listingId,
        listingTitle: propertyTitle,
        contractCode: houseUpi,
        landlordId: ownerId,
        landlordName: landlord,
        agentId: agentId,
        agentUid: uid,
        agentName: agentName,
        amount: formattedAmount,
        recipientPhone: phone,
        homeOwnerId: ownerId,
        paymentMethod: method,
      );

      if (!mounted) return;
      _showSlipCreatedDialog(
        landlordId: ownerId,
        slipReference: created.reference,
      );
      setState(() {
        _resetCreateSlipFlow();
        _selectedTab = 0;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, st) {
      debugPrint('createSlip failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save commission slip. Check internet and Firestore rules. ($e)',
          ),
        ),
      );
    }
  }

  void _resetCreateSlipFlow() {
    _createStep = _AgentCreateSlipStep.pickListing;
    _formListingId = null;
    _upiNeedsManualEntry = false;
    _phoneReadOnly = false;
    _estateNameController.clear();
    _commissionIdController.clear();
    _landlordNameController.clear();
    _homeOwnerIdController.clear();
    _amountController.clear();
    _paymentMethodController.text = 'MTN Momo';
    _phoneController.clear();
  }

  void _showSlipCreatedDialog({
    required String landlordId,
    required String slipReference,
  }) {
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: _AgentPaymentsColors.accentGreen,
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
                      color: _AgentPaymentsColors.bodyText,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment Slip Created',
                  style: textTheme.titleLarge?.copyWith(
                    color: _AgentPaymentsColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Commission slip created successfully for Landlord $landlordId.\n\n'
                  'Reference: $slipReference',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _AgentPaymentsColors.bodyText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _AgentPaymentsColors.bodyText,
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

  Widget _buildLabel(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _AgentPaymentsColors.bodyText,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _AgentPaymentsColors.bodyText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _AgentPaymentsColors.helper,
          fontSize: 14,
        ),
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF4F5F7) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _AgentPaymentsColors.bodyText),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showPaymentConfirmedDialog() {
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: _AgentPaymentsColors.accentGreen,
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
                      color: _AgentPaymentsColors.bodyText,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment Confirmed',
                  style: textTheme.titleLarge?.copyWith(
                    color: _AgentPaymentsColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This is to confirm that the landlord has successfully paid '
                  'the commission. Status will update soon.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _AgentPaymentsColors.bodyText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _AgentPaymentsColors.bodyText,
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
