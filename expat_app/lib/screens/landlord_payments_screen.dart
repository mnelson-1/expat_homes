import 'package:flutter/material.dart';

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() => _LandlordPaymentsScreenState();
}

class _LandlordPaymentsColors {
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color helper = Color(0xFF9CA5A8);
}

class _LandlordPayment {
  const _LandlordPayment({
    required this.reference,
    required this.contractCode,
    required this.agentName,
    required this.agentId,
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
  final String contractCode; // e.g. KM-202005
  final String agentName;
  final String agentId;
  final String landlordName;
  final String estateName;
  final String amount;
  final String paymentMethod;
  final String phoneNumber;
  final String statusLabel; // "Payment Pending" | "Payment Confirmed"
  final bool isConfirmed;
  final DateTime createdAt;
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  int _selectedTab = 0; // 0 = Track, 1 = Pay

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

  static final List<_LandlordPayment> _payments = [
    _LandlordPayment(
      reference: 'COM-8F4K29',
      contractCode: 'KM-202005',
      agentName: 'Jean Claude',
      agentId: 'KM-201903',
      landlordName: 'Eric Niyonsenga',
      estateName: 'Charm Nest Apartments',
      amount: 'RWF100,000',
      paymentMethod: 'MTN Momo',
      phoneNumber: '0792106639',
      statusLabel: 'Payment Pending',
      isConfirmed: false,
      createdAt: DateTime.now(),
    ),
    _LandlordPayment(
      reference: 'COM-9G5K40',
      contractCode: 'KM-201940',
      agentName: 'Jean Claude',
      agentId: 'KM-201903',
      landlordName: 'Jean Claude',
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
          child:
              _selectedTab == 0 ? _buildTrackTab(textTheme) : _buildPayTab(textTheme),
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
    if (_payments.isEmpty) {
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

    final payments = List<_LandlordPayment>.from(_payments)
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
          color: _LandlordPaymentsColors.bodyText,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TextTheme textTheme, _LandlordPayment payment) {
    final statusColor = payment.isConfirmed
        ? const Color(0xFF8ED966)
        : _LandlordPaymentsColors.helper;

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
                      color: _LandlordPaymentsColors.bodyText,
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
                  color: _LandlordPaymentsColors.helper,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                payment.estateName,
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
                        payment.amount,
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
                        payment.paymentMethod,
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
                        payment.phoneNumber,
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
        if (!payment.isConfirmed) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _selectedTab = 1;
                  _populateFormFromPayment(payment);
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
            hint: 'Landlord name',
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
              onPressed: () {
                _markActivePaymentAsConfirmed();
                _showPaymentSuccessDialog();
              },
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

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _markActivePaymentAsConfirmed() {
    final ref = _commissionIdController.text.trim();
    if (ref.isEmpty) return;

    final index = _payments.indexWhere((p) => p.reference == ref);
    if (index == -1) return;

    final payment = _payments[index];
    if (payment.isConfirmed) return;

    setState(() {
      _payments[index] = _LandlordPayment(
        reference: payment.reference,
        contractCode: payment.contractCode,
        agentName: payment.agentName,
        agentId: payment.agentId,
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

  void _onScroll() {
    final offset = _scrollController.offset;
    if (_scrollOffset != offset) {
      setState(() {
        _scrollOffset = offset;
      });
    }
  }

  void _populateFormFromPayment(_LandlordPayment payment) {
    _commissionIdController.text = payment.reference;
    _agentNameController.text = payment.agentName;
    _agentIdController.text = payment.agentId;
    _amountController.text = payment.amount;
    _paymentMethodController.text = payment.paymentMethod;
    _phoneController.text = payment.phoneNumber;
  }

  void _clearForm() {
    _commissionIdController.clear();
    _agentNameController.clear();
    _agentIdController.clear();
    _amountController.clear();
    _paymentMethodController.text = 'MTN Momo';
    _phoneController.clear();
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
          borderSide: const BorderSide(
            color: Color(0xFF9E9E9E),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _LandlordPaymentsColors.bodyText,
          ),
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
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
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

