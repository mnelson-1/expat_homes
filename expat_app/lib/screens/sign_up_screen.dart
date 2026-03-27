import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expat_app/constants/user_profile_options.dart';
import 'package:expat_app/legal/legal_version.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/widgets/legal_consent_rich_text.dart';

/// Shared palette for onboarding screens (matches Get Started).
class _SignUpColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color link = Color(0xFF157A88);
  static const Color invalidRed = Color(0xFFC62828);

  static const double fieldFontSize = 14;
  static const double helperFontSize = 12;
}

/// Sign Up screen for Expats: legal name, DOB, password, country, terms, Agree & Continue.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.initialEmail,
    this.preferredLanguage = 'English',
  });

  final String? initialEmail;
  final String? preferredLanguage;

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
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _legalConsentChecked = false;

  void _onPasswordFieldChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordFieldChanged);
    _confirmPasswordController.addListener(_onPasswordFieldChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordFieldChanged);
    _confirmPasswordController.removeListener(_onPasswordFieldChanged);
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
                    obscureText: _obscurePassword,
                    trailingIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _SignUpColors.hint,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPasswordFeedback(textTheme),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Country of Citizenship'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _country,
                    hint: 'Select country',
                    items: kCountryOfCitizenshipOptions
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
                  _buildErrorBanner(textTheme),
                  LegalConsentRichText(
                    baseStyle: textTheme.bodySmall?.copyWith(
                      color: _SignUpColors.bodyText,
                      fontSize: _SignUpColors.helperFontSize,
                    ),
                    linkColor: _SignUpColors.link,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _legalConsentChecked,
                    onChanged: (v) =>
                        setState(() => _legalConsentChecked = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I have read and agree to the policies linked above.',
                      style: textTheme.bodySmall?.copyWith(
                        color: _SignUpColors.bodyText,
                        fontSize: _SignUpColors.helperFontSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(8, 56, 24, 24),
      color: _SignUpColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
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
            const SizedBox(width: 48),
          ],
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

  static bool _isStrongPassword(String s) {
    if (s.length < 8) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(s) && RegExp(r'[0-9]').hasMatch(s);
  }

  Widget _buildPasswordFeedback(TextTheme textTheme) {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final hasTyped = password.isNotEmpty || confirm.isNotEmpty;
    if (!hasTyped) return const SizedBox.shrink();

    String message = 'Use 8+ characters with letters and numbers';
    Color color = _SignUpColors.helper;
    if (confirm.isNotEmpty && password != confirm) {
      message = 'Passwords do not match';
      color = _SignUpColors.invalidRed;
    } else if (password.isNotEmpty && !_isStrongPassword(password)) {
      message = 'Weak password';
      color = _SignUpColors.invalidRed;
    } else if (_isStrongPassword(password) && password == confirm) {
      message = 'Passwords match';
      color = _SignUpColors.accentGreen;
    } else if (_isStrongPassword(password)) {
      message = 'Strong password';
      color = _SignUpColors.accentGreen;
    }
    return Text(
      message,
      style: textTheme.bodySmall?.copyWith(
        color: color,
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
    Widget? trailingIcon,
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
              suffixIcon: trailingIcon,
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

  Future<void> _handleAgreeAndContinue() async {
    final email = widget.initialEmail?.trim() ?? '';
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please go back and enter your email on Get Started.');
      return;
    }
    final password = _passwordController.text;
    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 8 || !RegExp(r'[a-zA-Z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _errorMessage = 'Use 8+ characters with letters and numbers');
      return;
    }
    if (!_legalConsentChecked) {
      setState(
        () => _errorMessage =
            'Please read and accept the Terms of Service and Privacy Policy.',
      );
      return;
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await AuthService().register(
        email: email,
        password: password,
        role: UserRole.expat,
        profile: UserProfile(
          id: '', email: email, role: UserRole.expat,
          preferredLanguage: widget.preferredLanguage ?? 'English',
          legalFirstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
          legalLastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
          dateOfBirth: _dateOfBirth,
          countryOfCitizenship: _country,
          termsAndPrivacyConsentAt: DateTime.now(),
          acceptedLegalVersion: kLegalDocumentsVersion,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is FirebaseAuthException ? e.message : e.toString();
      });
    }
  }

  Widget _buildAgreeButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: (_isLoading || !_legalConsentChecked)
          ? null
          : _handleAgreeAndContinue,
      style: FilledButton.styleFrom(
        backgroundColor: _SignUpColors.accentGreen,
        foregroundColor: _SignUpColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              'Agree & Continue',
              style: textTheme.titleMedium?.copyWith(
          color: _SignUpColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(TextTheme textTheme) {
    if (_errorMessage == null || _errorMessage!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        _errorMessage!,
        style: textTheme.bodySmall?.copyWith(color: _SignUpColors.invalidRed),
      ),
    );
  }
}
