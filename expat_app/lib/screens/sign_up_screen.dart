import 'package:flutter/material.dart';

/// Shared palette for onboarding screens (matches Get Started).
class _SignUpColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF757575);
  static const Color helper = Color(0xFF9E9E9E);
  static const Color bodyText = Color(0xFF212121);
  static const Color link = Color(0xFF1A2E35);

  static const double fieldFontSize = 14;
  static const double helperFontSize = 12;
}

/// Sign Up screen for Expats: legal name, DOB, password, country, terms, Agree & Continue.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dateOfBirth;
  String _country = 'Nigeria';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(textTheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionLabel(textTheme, 'Legal name'),
                  const SizedBox(height: 8),
                  _buildStackedFields(
                    context,
                    firstHint: 'First name on ID',
                    secondHint: 'Last name on ID',
                    firstController: _firstNameController,
                    secondController: _lastNameController,
                  ),
                  const SizedBox(height: 4),
                  _buildHelper(textTheme,
                      'Make sure this matches the name on your government ID.'),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Date of birth'),
                  const SizedBox(height: 8),
                  _buildDateField(context, textTheme),
                  const SizedBox(height: 4),
                  _buildHelper(textTheme,
                      'You need to be at least 18. Your birthday won\'t be shared with other users.'),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Create your password'),
                  const SizedBox(height: 8),
                  _buildStackedFields(
                    context,
                    firstHint: 'Password',
                    secondHint: 'Confirm password',
                    firstController: _passwordController,
                    secondController: _confirmPasswordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Country of Citizenship'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _country,
                    hint: 'Select country',
                    items: ['Nigeria', 'Rwanda', 'Kenya', 'Uganda', 'Tanzania']
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: _fieldTextStyle(context)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _country = v ?? 'Nigeria'),
                  ),
                  const SizedBox(height: 4),
                  _buildHelper(textTheme,
                      'This will be used to automatically assign you to bowls.'),
                  const SizedBox(height: 24),
                  _buildTermsText(textTheme),
                  const SizedBox(height: 28),
                  _buildAgreeButton(textTheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      color: _SignUpColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Text(
          'Few More Steps',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(TextTheme textTheme, String label) {
    return Text(
      label,
      style: textTheme.titleMedium?.copyWith(
        color: _SignUpColors.bodyText,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHelper(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _SignUpColors.helper,
        fontSize: _SignUpColors.helperFontSize,
      ),
    );
  }

  TextStyle? _fieldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: _SignUpColors.fieldFontSize,
          color: _SignUpColors.bodyText,
        );
  }

  Widget _buildStackedFields(
    BuildContext context, {
    required String firstHint,
    required String secondHint,
    required TextEditingController firstController,
    required TextEditingController secondController,
    bool obscureText = false,
  }) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _SignUpColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(
            controller: firstController,
            obscureText: obscureText,
            style: _fieldTextStyle(context),
            decoration: InputDecoration(
              hintText: firstHint,
              hintStyle: TextStyle(
                color: _SignUpColors.hint,
                fontSize: _SignUpColors.fieldFontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: padding,
            ),
          ),
          const Divider(height: 1, color: _SignUpColors.border),
          TextField(
            controller: secondController,
            obscureText: obscureText,
            style: _fieldTextStyle(context),
            decoration: InputDecoration(
              hintText: secondHint,
              hintStyle: TextStyle(
                color: _SignUpColors.hint,
                fontSize: _SignUpColors.fieldFontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: padding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, TextTheme textTheme) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _SignUpColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dateOfBirth == null
                    ? 'Birthday (dd/mm/yyyy)'
                    : _formatDate(_dateOfBirth),
                style: _dateOfBirth == null
                    ? textTheme.bodyLarge?.copyWith(
                        color: _SignUpColors.hint,
                        fontSize: _SignUpColors.fieldFontSize,
                      )
                    : _fieldTextStyle(context),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _SignUpColors.bodyText),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _SignUpColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: _SignUpColors.bodyText),
          dropdownColor: Colors.white,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: _SignUpColors.fieldFontSize,
            color: _SignUpColors.bodyText,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText(TextTheme textTheme) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodySmall?.copyWith(
          color: _SignUpColors.bodyText,
          fontSize: _SignUpColors.helperFontSize,
        ),
        children: [
          const TextSpan(
              text:
                  'By selecting Agree & continue, I agree to ExpatHomes\' '),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: _SignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'Payments Terms of Service',
            style: TextStyle(
              color: _SignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Nondiscrimination Policy',
            style: TextStyle(
              color: _SignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and acknowledge the '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: _SignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildAgreeButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: _SignUpColors.accentGreen,
        foregroundColor: _SignUpColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Agree & Continue',
        style: textTheme.titleMedium?.copyWith(
          color: _SignUpColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }
}
