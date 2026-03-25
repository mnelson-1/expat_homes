import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:expat_app/models/commission_slip.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/utils/calendar_thread_labels.dart';
import 'package:expat_app/services/commission_slips_service.dart';

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() =>
      _LandlordPaymentsScreenState();
}

class _LandlordPaymentsColors {
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  int _selectedTab = 0;

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
  final TextEditingController _agentNameController = TextEditingController();
  final TextEditingController _agentIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController(text: 'MTN Momo');
  final TextEditingController _phoneController = TextEditingController();

  Stream<List<CommissionSlip>>? _slipsStream;
  StreamSubscription<User?>? _authSub;

  /// Currently selected slip (from Track tab "Pay" button).
  CommissionSlip? _activeSlip;

  void _bindSlipsStream(String? uid) {
    _slipsStream =
        uid != null && uid.isNotEmpty
            ? CommissionSlipsService().landlordSlipsStream(uid)
            : null;
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
    _agentNameController.dispose();
    _agentIdController.dispose();
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
              : _buildPayTab(textTheme),
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
                          ? _LandlordPaymentsColors.bodyText
                          : _LandlordPaymentsColors.helper,
                      fontWeight:
                          _selectedTab == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    color: _selectedTab == 0
                        ? _LandlordPaymentsColors.accentGreen
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
                  _clearForm();
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pay',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _selectedTab == 1
                          ? _LandlordPaymentsColors.bodyText
                          : _LandlordPaymentsColors.helper,
                      fontWeight:
                          _selectedTab == 1 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    color: _selectedTab == 1
                        ? _LandlordPaymentsColors.accentGreen
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
            color: _LandlordPaymentsColors.helper,
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
                  'You have no commission payments yet.\nThey will appear here once created.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: _LandlordPaymentsColors.helper,
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
          color: _LandlordPaymentsColors.bodyText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TextTheme textTheme, CommissionSlip slip) {
    final bool canPay = slip.status == SlipStatus.pending;

    final Color statusColor;
    switch (slip.status) {
      case SlipStatus.confirmed:
        statusColor = _LandlordPaymentsColors.accentGreen;
      case SlipStatus.reported:
        statusColor = const Color(0xFFC62828);
      case SlipStatus.agentConfirmationPending:
        statusColor = const Color(0xFFFFD54F);
      default:
        statusColor = _LandlordPaymentsColors.helper;
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
                      color: _LandlordPaymentsColors.bodyText,
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
                  color: _LandlordPaymentsColors.helper,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slip.listingTitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: _LandlordPaymentsColors.bodyText,
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
                          color: _LandlordPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.amount,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _LandlordPaymentsColors.bodyText,
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
                          color: _LandlordPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.paymentMethod,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _LandlordPaymentsColors.bodyText,
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
                          color: _LandlordPaymentsColors.helper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slip.recipientPhone,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _LandlordPaymentsColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canPay) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _selectedTab = 1;
                  _activeSlip = slip;
                  _populateFormFromSlip(slip);
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: _LandlordPaymentsColors.accentGreen,
                foregroundColor: _LandlordPaymentsColors.bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Pay'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPayTab(TextTheme textTheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel(textTheme, 'Commission IDREF'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _commissionIdController,
            hint: 'enter commission IDREF',
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Agent Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _agentNameController,
            hint: 'Agent name',
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Agent ID'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _agentIdController,
            hint: 'RWAREB given ID',
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
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Phone Number of Recipient'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'e.g 0798654987',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _handlePay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: _LandlordPaymentsColors.bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                'Pay via ${_paymentMethodController.text.isEmpty ? 'MTN Momo' : _paymentMethodController.text}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePay() async {
    final ref = _commissionIdController.text.trim();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the commission IDREF.')),
      );
      return;
    }

    CommissionSlip? target = _activeSlip;
    if (target == null || target.reference != ref) {
      target = await CommissionSlipsService().getSlipByReference(ref);
    }

    if (target == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No slip found with reference $ref.')),
      );
      return;
    }

    await CommissionSlipsService().paySlip(target.id);

    if (!mounted) return;
    _showPaymentSuccessDialog();
    _clearForm();
    setState(() {
      _activeSlip = null;
      _selectedTab = 0;
    });
  }

  void _populateFormFromSlip(CommissionSlip slip) {
    _commissionIdController.text = slip.reference;
    _agentNameController.text = slip.agentName;
    _agentIdController.text = slip.agentId;
    _amountController.text = slip.amount;
    _paymentMethodController.text = slip.paymentMethod;
    _phoneController.text = slip.recipientPhone;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (_scrollOffset != offset) {
      setState(() => _scrollOffset = offset);
    }
  }

  void _clearForm() {
    _commissionIdController.clear();
    _agentNameController.clear();
    _agentIdController.clear();
    _amountController.clear();
    _paymentMethodController.text = 'MTN Momo';
    _phoneController.clear();
    _activeSlip = null;
  }

  Widget _buildLabel(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _LandlordPaymentsColors.bodyText,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _LandlordPaymentsColors.bodyText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _LandlordPaymentsColors.helper,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _LandlordPaymentsColors.bodyText),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showPaymentSuccessDialog() {
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
              color: _LandlordPaymentsColors.accentGreen,
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
                      color: _LandlordPaymentsColors.bodyText,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment Successful',
                  style: textTheme.titleLarge?.copyWith(
                    color: _LandlordPaymentsColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully paid the amount due on this slip. '
                  'The status will be updated shortly.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _LandlordPaymentsColors.bodyText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _LandlordPaymentsColors.bodyText,
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
