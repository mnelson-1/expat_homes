import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expat_app/screens/sign_up_screen.dart';
import 'package:expat_app/services/auth_service.dart';

/// Palette for Sign In (matches Get Started / Sign Up).
class _SignInColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color helper = Color(0xFF9CA5A8);
  static const Color bodyText = Color(0xFF1A2E35);
  static const Color invalidRed = Color(0xFFC62828);

  static const double fieldFontSize = 14;
  static const double helperFontSize = 12;
}

/// Sign In screen for Expats: email, password, Sign In button, Sign Up link, Google.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  _buildErrorBanner(textTheme),
                  _buildStackedFields(context),
                  const SizedBox(height: 4),
                  _buildHelper(
                    textTheme,
                    'This lets you sign in with your email if Google sign-in is unavailable.',
                  ),
                  const SizedBox(height: 28),
                  _buildSignInButton(textTheme),
                  const SizedBox(height: 16),
                  _buildSignUpPrompt(textTheme),
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
      padding: const EdgeInsets.fromLTRB(8, 56, 24, 24),
      color: _SignInColors.primaryDark,
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
                'Sign In',
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

  TextStyle? _fieldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: _SignInColors.fieldFontSize,
          color: _SignInColors.bodyText,
        );
  }

  Widget _buildStackedFields(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _SignInColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: _fieldTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(
                color: _SignInColors.hint,
                fontSize: _SignInColors.fieldFontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: padding,
            ),
          ),
          const Divider(height: 1, color: _SignInColors.border),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            style: _fieldTextStyle(context),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(
                color: _SignInColors.hint,
                fontSize: _SignInColors.fieldFontSize,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: padding,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _SignInColors.hint,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelper(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _SignInColors.helper,
        fontSize: _SignInColors.helperFontSize,
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await AuthService().signIn(email: email, password: password);
      if (!mounted) return;
      // Auth state updated; pop to root so _AppEntry rebuilds with new profile
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is FirebaseAuthException ? e.message : e.toString();
      });
    }
  }

  Widget _buildSignInButton(TextTheme textTheme) {
    return FilledButton(
      onPressed: _isLoading ? null : _handleSignIn,
      style: FilledButton.styleFrom(
        backgroundColor: _SignInColors.accentGreen,
        foregroundColor: _SignInColors.primaryDark,
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
              'Sign In',
              style: textTheme.titleMedium?.copyWith(
          color: _SignInColors.primaryDark,
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
        style: textTheme.bodySmall?.copyWith(color: _SignInColors.invalidRed),
      ),
    );
  }

  Widget _buildSignUpPrompt(TextTheme textTheme) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SignUpScreen(),
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            style: textTheme.bodyLarge?.copyWith(
              color: _SignInColors.bodyText,
            ),
            children: [
              const TextSpan(text: 'Don\'t have an account? '),
              TextSpan(
                text: 'Sign Up',
                style: textTheme.bodyLarge?.copyWith(
                  color: _SignInColors.accentGreen,
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
        const Expanded(child: Divider(color: _SignInColors.helper)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: textTheme.bodyMedium?.copyWith(
              color: _SignInColors.helper,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _SignInColors.helper)),
      ],
    );
  }

  Widget _buildGoogleButton(TextTheme textTheme) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: _SignInColors.bodyText,
        side: const BorderSide(color: _SignInColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
              color: _SignInColors.bodyText,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
