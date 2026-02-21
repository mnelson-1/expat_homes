import 'package:flutter/material.dart';

/// Palette and typography for Get Started / onboarding screens.
class _GetStartedColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF757575);
  static const Color helper = Color(0xFF9E9E9E);
  static const Color bodyText = Color(0xFF212121);

  static const double fieldFontSize = 14;
  static const double helperFontSize = 12;
}

/// Role options for "What best describes you?"
enum _UserRole {
  expat('Expat'),
  landlord('Landlord'),
  agent('Agent');

  const _UserRole(this.label);
  final String label;
}

const List<String> _supportedLanguages = [
  'English',
  'Kinyarwanda',
  'French',
  'Swahili',
];

/// Get Started onboarding screen: role, language, email, Continue, Login, Google.
class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  _UserRole? _selectedRole;
  String _selectedLanguage = 'English';
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _verificationMessageSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
                  _buildSectionLabel(textTheme, 'What best describes you?'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedRole?.label,
                    hint: 'Select an option',
                    items: _UserRole.values
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r.label,
                            child: Text(
                              r.label,
                              style: _dropdownItemStyle(context),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedRole =
                            _UserRole.values.firstWhere((r) => r.label == v);
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildHelper(
                    textTheme,
                    'The interface will be customized according to your selection.',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Preferred language'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedLanguage,
                    hint: 'Select language',
                    items: _supportedLanguages
                        .map(
                          (lang) => DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang,
                                style: _dropdownItemStyle(context)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedLanguage = v ?? 'English'),
                  ),
                  const SizedBox(height: 4),
                  _buildHelper(
                    textTheme,
                    "We'll use this to personalise your experience and translate messages.",
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  if (_verificationMessageSent) ...[
                    const SizedBox(height: 4),
                    _buildHelper(
                      textTheme,
                      'A verification link will be sent to you shortly. '
                      'Click the link to continue creating your account.',
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildContinueButton(textTheme),
                  const SizedBox(height: 16),
                  _buildLoginPrompt(textTheme),
                  const SizedBox(height: 24),
                  _buildDivider(textTheme),
                  const SizedBox(height: 24),
                  _buildGoogleButton(textTheme),
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
      color: _GetStartedColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Text(
          'Get Started',
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
        color: _GetStartedColors.bodyText,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHelper(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _GetStartedColors.helper,
        fontSize: _GetStartedColors.helperFontSize,
      ),
    );
  }

  TextStyle? _dropdownItemStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: _GetStartedColors.fieldFontSize,
          color: _GetStartedColors.bodyText,
        );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final fieldStyle = textTheme.bodyLarge?.copyWith(
      fontSize: _GetStartedColors.fieldFontSize,
      color: _GetStartedColors.bodyText,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _GetStartedColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: textTheme.bodyLarge?.copyWith(
              color: _GetStartedColors.hint,
              fontSize: _GetStartedColors.fieldFontSize,
            ),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          dropdownColor: Colors.white,
          style: fieldStyle,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      readOnly: readOnly,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: _GetStartedColors.fieldFontSize,
        color: _GetStartedColors.bodyText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _GetStartedColors.hint,
          fontSize: _GetStartedColors.fieldFontSize,
        ),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _GetStartedColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _GetStartedColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildContinueButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: () {
        final email = _emailController.text.trim();
        if (email.isNotEmpty) {
          setState(() => _verificationMessageSent = true);
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: _GetStartedColors.accentGreen,
        foregroundColor: _GetStartedColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Continue',
        style: textTheme.titleMedium?.copyWith(
          color: _GetStartedColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(TextTheme textTheme) {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: RichText(
          text: TextSpan(
            style: textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF424242),
            ),
            children: [
              const TextSpan(text: 'Have an account? '),
              TextSpan(
                text: 'Login',
                style: textTheme.bodyLarge?.copyWith(
                  color: _GetStartedColors.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(TextTheme textTheme) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _GetStartedColors.helper)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: textTheme.bodyMedium?.copyWith(
              color: _GetStartedColors.helper,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _GetStartedColors.helper)),
      ],
    );
  }

  Widget _buildGoogleButton(TextTheme textTheme) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF212121),
        side: const BorderSide(color: _GetStartedColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/google-icon.png',
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Google',
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF212121),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
