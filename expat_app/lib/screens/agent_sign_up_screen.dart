import 'package:flutter/material.dart';

/// Palette for Agent signup (mirrors Expat / Landlord signup).
class _AgentSignUpColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color link = Color(0xFF157A88);

  static const double fieldFontSize = 14;
  static const double helperFontSize = 12;
}

/// Agent signup screen: legal name, language, agent ID, password, terms, Sign Up.
class AgentSignUpScreen extends StatefulWidget {
  const AgentSignUpScreen({super.key});

  @override
  State<AgentSignUpScreen> createState() => _AgentSignUpScreenState();
}

class _AgentSignUpScreenState extends State<AgentSignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _agentIdController = TextEditingController();
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _agentIdController.dispose();
    super.dispose();
  }

  static const List<String> _languages = [
    'English',
    'Kinyarwanda',
    'French',
    'Swahili',
  ];

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
                  _buildHelper(
                    textTheme,
                    'Make sure this matches the name on your Broker ID.',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Preferred language'),
                  const SizedBox(height: 8),
                  _buildLanguageDropdown(),
                  const SizedBox(height: 4),
                  _buildHelper(
                    textTheme,
                    "We'll use this to personalise your experience and translate messages.",
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(textTheme, 'Agent-ID Number'),
                  const SizedBox(height: 8),
                  _buildSingleField(
                    context,
                    controller: _agentIdController,
                    hint: 'Agent-ID Number',
                  ),
                  const SizedBox(height: 4),
                  _buildHelper(
                    textTheme,
                    'You must have been issued a Real Estate Broker ID by the RWAREB first.',
                  ),
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
                  const SizedBox(height: 24),
                  _buildTermsText(textTheme),
                  const SizedBox(height: 28),
                  _buildSignUpButton(textTheme),
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
      color: _AgentSignUpColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Text(
          'Verification',
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
        color: _AgentSignUpColors.bodyText,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHelper(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _AgentSignUpColors.helper,
        fontSize: _AgentSignUpColors.helperFontSize,
      ),
    );
  }

  TextStyle? _fieldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: _AgentSignUpColors.fieldFontSize,
          color: _AgentSignUpColors.bodyText,
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
        border: Border.all(color: _AgentSignUpColors.border),
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
                color: _AgentSignUpColors.hint,
                fontSize: _AgentSignUpColors.fieldFontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: padding,
            ),
          ),
          const Divider(height: 1, color: _AgentSignUpColors.border),
          TextField(
            controller: secondController,
            obscureText: obscureText,
            style: _fieldTextStyle(context),
            decoration: InputDecoration(
              hintText: secondHint,
              hintStyle: TextStyle(
                color: _AgentSignUpColors.hint,
                fontSize: _AgentSignUpColors.fieldFontSize,
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

  Widget _buildSingleField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: _fieldTextStyle(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _AgentSignUpColors.hint,
          fontSize: _AgentSignUpColors.fieldFontSize,
        ),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _AgentSignUpColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _AgentSignUpColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _AgentSignUpColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          items: _languages
              .map(
                (lang) => DropdownMenuItem<String>(
                  value: lang,
                  child: Text(
                    lang,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: _AgentSignUpColors.fieldFontSize,
                      color: _AgentSignUpColors.bodyText,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedLanguage = v ?? _selectedLanguage),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: _AgentSignUpColors.bodyText,
          ),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTermsText(TextTheme textTheme) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodySmall?.copyWith(
          color: _AgentSignUpColors.bodyText,
          fontSize: _AgentSignUpColors.helperFontSize,
        ),
        children: [
          const TextSpan(
            text:
                'By selecting Agree & continue, I agree to ExpatHomes\' ',
          ),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: _AgentSignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'Payments Terms of Service',
            style: TextStyle(
              color: _AgentSignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Nondiscrimination Policy',
            style: TextStyle(
              color: _AgentSignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and acknowledge the '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: _AgentSignUpColors.link,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: _AgentSignUpColors.accentGreen,
        foregroundColor: _AgentSignUpColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Sign Up',
        style: textTheme.titleMedium?.copyWith(
          color: _AgentSignUpColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }
}

