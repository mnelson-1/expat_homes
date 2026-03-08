import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/auth_service.dart';

/// Seed data: agents issued by RWAREB (or app's copy of that database).
/// In production the backend will validate against the institution's data.
class _SeedAgent {
  const _SeedAgent({
    required this.agentId,
    required this.firstName,
    required this.lastName,
  });
  final String agentId;
  final String firstName;
  final String lastName;
}

const List<_SeedAgent> _seedAgents = [
  _SeedAgent(agentId: 'KM-201903', firstName: 'Jean', lastName: 'Claude'),
  _SeedAgent(agentId: 'KM-202005', firstName: 'Eric', lastName: 'Niyonsenga'),
  _SeedAgent(agentId: 'KM-201940', firstName: 'Jean', lastName: 'Claude'),
  _SeedAgent(agentId: 'RM-204112', firstName: 'Aline', lastName: 'Uwase'),
  _SeedAgent(agentId: 'KG-198745', firstName: 'Eric', lastName: 'Niyonzima'),
  _SeedAgent(agentId: 'KG-205678', firstName: 'Linda', lastName: 'Mukamana'),
];

/// Palette for Agent signup (mirrors Expat / Landlord signup).
class _AgentSignUpColors {
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

/// Agent signup screen: legal name, language, agent ID, password, terms, Sign Up.
class AgentSignUpScreen extends StatefulWidget {
  const AgentSignUpScreen({
    super.key,
    this.initialEmail,
    this.preferredLanguage = 'English',
  });

  final String? initialEmail;
  final String? preferredLanguage;

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
  /// null = default message, 'valid' = Valid ID, 'invalid' = Invalid ID
  String? _idValidationStatus;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.preferredLanguage ?? 'English';
    _agentIdController.addListener(_onAgentIdChanged);
    _passwordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _agentIdController.removeListener(_onAgentIdChanged);
    _passwordController.removeListener(_onFormChanged);
    _confirmPasswordController.removeListener(_onFormChanged);
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

  void _onAgentIdChanged() {
    final id = _agentIdController.text.trim();
    if (id.isEmpty) {
      setState(() {
        _idValidationStatus = null;
        _firstNameController.text = '';
        _lastNameController.text = '';
      });
      return;
    }
    _SeedAgent? agent;
    for (final a in _seedAgents) {
      if (a.agentId.toUpperCase() == id.toUpperCase()) {
        agent = a;
        break;
      }
    }
    if (agent == null) {
      setState(() {
        _idValidationStatus = 'invalid';
        _firstNameController.text = '';
        _lastNameController.text = '';
      });
      return;
    }
    final first = agent.firstName;
    final last = agent.lastName;
    setState(() {
      _idValidationStatus = 'valid';
      _firstNameController.text = first;
      _lastNameController.text = last;
    });
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
                  _buildSectionLabel(textTheme, 'Agent-ID Number'),
                  const SizedBox(height: 8),
                  _buildSingleField(
                    context,
                    controller: _agentIdController,
                    hint: 'Agent-ID Number',
                  ),
                  const SizedBox(height: 4),
                  _buildAgentIdHelper(textTheme),
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
                    'Pulled from RWAREB Database',
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
                  const SizedBox(height: 4),
                  _buildPasswordFeedback(textTheme),
                  const SizedBox(height: 24),
                  _buildErrorBanner(textTheme),
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
      padding: const EdgeInsets.fromLTRB(8, 56, 24, 24),
      color: _AgentSignUpColors.primaryDark,
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
                'Verification',
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

  String get _agentIdHelperText {
    if (_idValidationStatus == 'valid') return 'Valid ID';
    if (_idValidationStatus == 'invalid') return 'Invalid ID';
    return 'You must have been issued a Real Estate Broker ID by the RWAREB first.';
  }

  Color get _agentIdHelperColor {
    if (_idValidationStatus == 'valid') return _AgentSignUpColors.accentGreen;
    if (_idValidationStatus == 'invalid') return _AgentSignUpColors.invalidRed;
    return _AgentSignUpColors.helper;
  }

  /// Strong = 8+ chars and mix of letters and digits. Backend can enforce a stricter regex (e.g. upper + lower + digit + symbol).
  static bool _isStrongPassword(String s) {
    if (s.length < 8) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(s) && RegExp(r'[0-9]').hasMatch(s);
  }

  Widget _buildAgentIdHelper(TextTheme textTheme) {
    return Text(
      _agentIdHelperText,
      style: textTheme.bodySmall?.copyWith(
        color: _agentIdHelperColor,
        fontSize: _AgentSignUpColors.helperFontSize,
      ),
    );
  }

  /// Password feedback: only visible once the user has started typing.
  /// Strength uses length + mix of letters and digits; backend can enforce a stricter regex.
  Widget _buildPasswordFeedback(TextTheme textTheme) {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final hasTyped = password.isNotEmpty || confirm.isNotEmpty;
    if (!hasTyped) return const SizedBox.shrink();

    String message = 'Use 8+ characters with letters and numbers';
    Color color = _AgentSignUpColors.helper;
    if (confirm.isNotEmpty && password != confirm) {
      message = 'Passwords do not match';
      color = _AgentSignUpColors.invalidRed;
    } else if (password.isNotEmpty && !_isStrongPassword(password)) {
      message = 'Weak password';
      color = _AgentSignUpColors.invalidRed;
    } else if (_isStrongPassword(password) && password == confirm) {
      message = 'Passwords match';
      color = _AgentSignUpColors.accentGreen;
    } else if (_isStrongPassword(password)) {
      message = 'Strong password';
      color = _AgentSignUpColors.accentGreen;
    }
    return Text(
      message,
      style: textTheme.bodySmall?.copyWith(
        color: color,
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

  Future<void> _handleSignUp() async {
    final email = widget.initialEmail?.trim() ?? '';
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please go back and enter your email on Get Started.');
      return;
    }
    if (_idValidationStatus != 'valid') {
      setState(() => _errorMessage = 'Please enter a valid Agent ID.');
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
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await AuthService().register(
        email: email,
        password: password,
        role: UserRole.agent,
        profile: UserProfile(
          id: '',
          email: email,
          role: UserRole.agent,
          preferredLanguage: widget.preferredLanguage ?? _selectedLanguage,
          legalFirstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
          legalLastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
          agentId: _agentIdController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is FirebaseAuthException ? e.message : e.toString();
      });
    }
  }

  Widget _buildSignUpButton(TextTheme textTheme) {
    final canSignUp = _idValidationStatus == 'valid' &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
    return FilledButton(
      onPressed: (_isLoading || !canSignUp) ? null : _handleSignUp,
      style: FilledButton.styleFrom(
        backgroundColor: _AgentSignUpColors.accentGreen,
        foregroundColor: _AgentSignUpColors.bodyText,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
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
              'Sign Up',
              style: textTheme.titleMedium?.copyWith(
                color: _AgentSignUpColors.bodyText,
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
        style: textTheme.bodySmall?.copyWith(color: _AgentSignUpColors.invalidRed),
      ),
    );
  }
}

