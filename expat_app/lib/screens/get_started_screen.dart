import 'dart:async';

import 'package:flutter/material.dart';
import 'package:expat_app/constants/user_profile_options.dart';
import 'package:expat_app/screens/agent_sign_up_screen.dart';
import 'package:expat_app/screens/landlord_sign_up_screen.dart';
import 'package:expat_app/screens/sign_in_screen.dart';
import 'package:expat_app/screens/sign_up_screen.dart';
import 'package:expat_app/services/auth_service.dart';

/// Palette and typography for Get Started / onboarding screens.
class _GetStartedColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color bodyText = Color(0xFF1A2E35);

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
  final _authService = AuthService();
  Timer? _emailLookupDebounce;
  EmailRegistrationLookupResult? _emailLookup;
  bool _emailLookupInFlight = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _emailFocus.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _emailLookupDebounce?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailFocus.removeListener(_onEmailFocusChanged);
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (!_emailFocus.hasFocus) {
      _emailLookupDebounce?.cancel();
      unawaited(_runEmailLookup());
    }
  }

  void _onEmailChanged() {
    _emailLookupDebounce?.cancel();
    final text = _emailController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _emailLookup = null;
          _emailLookupInFlight = false;
        });
      }
      return;
    }
    if (!AuthService.emailLooksValid(text)) {
      if (mounted) {
        setState(() {
          _emailLookup = const EmailRegistrationLookupResult(
            kind: EmailLookupKind.invalidFormat,
          );
          _emailLookupInFlight = false;
        });
      }
      return;
    }
    _emailLookupDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_runEmailLookup());
    });
  }

  Future<void> _runEmailLookup() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        setState(() {
          _emailLookup = null;
          _emailLookupInFlight = false;
        });
      }
      return;
    }
    if (!AuthService.emailLooksValid(email)) {
      if (mounted) {
        setState(() {
          _emailLookup = const EmailRegistrationLookupResult(
            kind: EmailLookupKind.invalidFormat,
          );
          _emailLookupInFlight = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _emailLookupInFlight = true);
    final result = await _authService.lookupEmailForRegistration(email);
    if (!mounted) return;
    if (_emailController.text.trim() != email) return;
    setState(() {
      _emailLookup = result;
      _emailLookupInFlight = false;
    });
  }

  Color _emailStatusColor() {
    switch (_emailLookup?.kind) {
      case EmailLookupKind.available:
        return _GetStartedColors.accentGreen;
      case EmailLookupKind.invalidFormat:
      case EmailLookupKind.alreadyRegistered:
      case EmailLookupKind.error:
        return Colors.red.shade700;
      default:
        return _GetStartedColors.helper;
    }
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
                    items: kPreferredLanguages
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
                  _buildEmailField(textTheme),
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

  Widget _buildEmailField(TextTheme textTheme) {
    final msg = _emailLookup?.statusMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: textTheme.bodyLarge?.copyWith(
            fontSize: _GetStartedColors.fieldFontSize,
            color: _GetStartedColors.bodyText,
          ),
          decoration: InputDecoration(
            hintText: 'Email',
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
            suffixIcon: _emailLookupInFlight
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (msg != null) ...[
          const SizedBox(height: 6),
          Text(
            msg,
            style: textTheme.bodySmall?.copyWith(
              color: _emailStatusColor(),
              fontSize: _GetStartedColors.helperFontSize,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: () async {
        if (_selectedRole == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select what best describes you.'),
            ),
          );
          return;
        }
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your email.')),
          );
          return;
        }
        if (mounted) setState(() => _emailLookupInFlight = true);
        final lookup = await _authService.lookupEmailForRegistration(email);
        if (!mounted) return;
        setState(() {
          _emailLookup = lookup;
          _emailLookupInFlight = false;
        });
        if (!lookup.allowsNewRegistration) {
          return;
        }
        if (_selectedRole == _UserRole.expat) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SignUpScreen(
                initialEmail: email,
                preferredLanguage: _selectedLanguage,
              ),
            ),
          );
          return;
        }
        if (_selectedRole == _UserRole.landlord) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LandlordSignUpScreen(
                initialEmail: email,
                preferredLanguage: _selectedLanguage,
              ),
            ),
          );
          return;
        }
        if (_selectedRole == _UserRole.agent) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AgentSignUpScreen(
                initialEmail: email,
                preferredLanguage: _selectedLanguage,
              ),
            ),
          );
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SignInScreen(),
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            style: textTheme.bodyLarge?.copyWith(
              color: _GetStartedColors.bodyText,
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
        foregroundColor: _GetStartedColors.bodyText,
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
              color: _GetStartedColors.bodyText,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
