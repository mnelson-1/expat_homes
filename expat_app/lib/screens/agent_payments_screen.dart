import 'package:flutter/material.dart';

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

class _AgentPayment {
  const _AgentPayment({
    required this.reference,
    required this.contractCode,
    required this.landlordName,
    required this.estateName,
    required this.amount,
    required this.paymentMethod,
    required this.phoneNumber,
    required this.statusLabel,
    required this.isConfirmed,
    required this.createdAt,
  });

  final String reference; // e.g. COM-8F4K29
  final String contractCode; // e.g. UPI-KIG-REM-00034
  final String landlordName;
  final String estateName;
  final String amount;
  final String paymentMethod;
  final String phoneNumber;
  final String statusLabel; // "Payment Pending" | "Payment Confirmed"
  final bool isConfirmed;
  final DateTime createdAt;
}

class _AgentPaymentsScreenState extends State<AgentPaymentsScreen> {
  int _selectedTab = 0; // 0 = Track, 1 = Create

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

  static final List<_AgentPayment> _payments = [
    _AgentPayment(
      reference: 'COM-8F4K29',
      contractCode: 'UPI-KIG-REM-00034',
      landlordName: 'Jean Uwimana',
      estateName: 'Charm Nest Apartments',
      amount: 'RWF100,000',
      paymentMethod: 'MTN Momo',
      phoneNumber: '0792106639',
      statusLabel: 'Payment Pending',
      isConfirmed: false,
      createdAt: DateTime.now(),
    ),
    _AgentPayment(
      reference: 'COM-9G5K40',
      contractCode: 'UPI-KIG-REM-00035',
      landlordName: 'Jean Uwimana',
      estateName: 'Charm Nest Apartments',
      amount: 'RWF50,000',
      paymentMethod: 'MTN Momo',
      phoneNumber: '0792106639',
      statusLabel: 'Payment Confirmed',
      isConfirmed: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
              : _buildCreateTab(textTheme),
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
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
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
                  _clearForm();
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
    if (_payments.isEmpty) {
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

    final payments = List<_AgentPayment>.from(_payments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<Widget> children = [];
    DateTime? lastDate;

    for (final payment in payments) {
      final isNewDate =
          lastDate == null || !_isSameDay(lastDate, payment.createdAt);

      if (isNewDate) {
        if (lastDate != null) {
          children.add(const SizedBox(height: 18));
        }
        children.add(_buildDateHeader(textTheme, payment.createdAt));
        children.add(const SizedBox(height: 16));
        lastDate = _startOfDay(payment.createdAt);
      } else {
        children.add(const Divider(height: 1, color: Color(0xFFE0E0E0)));
        children.add(const SizedBox(height: 12));
      }

      children.add(_buildPaymentCard(textTheme, payment));
      children.add(const SizedBox(height: 12));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      controller: _scrollController,
      children: children,
    );
  }

  Widget _buildDateHeader(TextTheme textTheme, DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final label = '$day/$month/$year';

    return Center(
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: _AgentPaymentsColors.bodyText,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TextTheme textTheme, _AgentPayment payment) {
    final statusColor = payment.isConfirmed
        ? _AgentPaymentsColors.accentGreen
        : _AgentPaymentsColors.helper;

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
                    payment.reference,
                    style: textTheme.titleSmall?.copyWith(
                      color: _AgentPaymentsColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.statusLabel,
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
                '${payment.contractCode} • ${payment.landlordName}',
                style: textTheme.bodySmall?.copyWith(
                  color: _AgentPaymentsColors.helper,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                payment.estateName,
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
                        payment.amount,
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
                        payment.paymentMethod,
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
                        payment.phoneNumber,
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
        if (!payment.isConfirmed) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      _showReportDialog(payment);
                    },
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
                    child: const Text('Report'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      _markPaymentAsConfirmed(payment.reference);
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

  Widget _buildCreateTab(TextTheme textTheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel(textTheme, 'Property Title'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _estateNameController,
            hint: 'e.g 3–Bedroom Apartment etc.',
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'House UPI (Unique Parcel Identifier)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _commissionIdController,
            hint: 'RHA given Land UPI',
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Home Owner'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _landlordNameController,
            hint: 'Landlord name',
          ),
          const SizedBox(height: 16),
          _buildLabel(textTheme, 'Home Owner ID'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _homeOwnerIdController,
            hint: 'ID of Landlord',
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

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (_scrollOffset != offset) {
      setState(() {
        _scrollOffset = offset;
      });
    }
  }

  void _markPaymentAsConfirmed(String reference) {
    final index = _payments.indexWhere((p) => p.reference == reference);
    if (index == -1) return;

    final payment = _payments[index];
    if (payment.isConfirmed) return;

    setState(() {
      _payments[index] = _AgentPayment(
        reference: payment.reference,
        contractCode: payment.contractCode,
        landlordName: payment.landlordName,
        estateName: payment.estateName,
        amount: payment.amount,
        paymentMethod: payment.paymentMethod,
        phoneNumber: payment.phoneNumber,
        statusLabel: 'Payment Confirmed',
        isConfirmed: true,
        createdAt: payment.createdAt,
      );
    });
  }

  void _handleCreateSlip() {
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

    setState(() {
      _payments.add(
        _AgentPayment(
          reference: 'COM-DEMO-${_payments.length + 1}',
          contractCode: houseUpi,
          landlordName: landlord,
          estateName: propertyTitle,
          amount: formattedAmount,
          paymentMethod: method,
          phoneNumber: phone,
          statusLabel: 'Payment Pending',
          isConfirmed: false,
          createdAt: DateTime.now(),
        ),
      );
    });

    _showSlipCreatedDialog(ownerId);

    _clearForm();
    setState(() {
      _selectedTab = 0;
    });
  }

  void _clearForm() {
    _estateNameController.clear();
    _commissionIdController.clear();
    _landlordNameController.clear();
    _homeOwnerIdController.clear();
    _amountController.clear();
    _paymentMethodController.text = 'MTN Momo';
    _phoneController.clear();
  }

  void _showSlipCreatedDialog(String ownerId) {
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
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
                  'You have successfully created your commission payment slip, '
                  'and it has been issued to the landlord with ID-$ownerId.',
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
  }) {
    return TextField(
      controller: controller,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF9E9E9E),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _AgentPaymentsColors.bodyText,
          ),
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
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
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

  void _showReportDialog(_AgentPayment payment) {
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
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
                  'Report Successful',
                  style: textTheme.titleLarge?.copyWith(
                    color: _AgentPaymentsColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully reported this slip to the right '
                  'authorities. The issue is being investigated, and updates '
                  'will be sent soon.',
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

