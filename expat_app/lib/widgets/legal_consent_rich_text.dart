import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:expat_app/legal/legal_documents.dart';
import 'package:expat_app/screens/legal_document_screen.dart';

/// “By selecting Agree & continue…” with tappable links to legal screens.
class LegalConsentRichText extends StatefulWidget {
  const LegalConsentRichText({
    super.key,
    required this.baseStyle,
    required this.linkColor,
  });

  final TextStyle? baseStyle;
  final Color linkColor;

  @override
  State<LegalConsentRichText> createState() => _LegalConsentRichTextState();
}

class _LegalConsentRichTextState extends State<LegalConsentRichText> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _paymentsTap;
  late final TapGestureRecognizer _nondiscriminationTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = () => _openEula();
    _paymentsTap = TapGestureRecognizer()..onTap = () => _openPayments();
    _nondiscriminationTap =
        TapGestureRecognizer()..onTap = () => _openNondiscrimination();
    _privacyTap = TapGestureRecognizer()..onTap = () => _openPrivacy();
  }

  void _openEula() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegalDocumentScreen(
          title: 'Terms of Service (EULA)',
          body: kEulaText,
        ),
      ),
    );
  }

  void _openPayments() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegalDocumentScreen(
          title: 'Payments Terms of Service',
          body: kPaymentsTermsText,
        ),
      ),
    );
  }

  void _openNondiscrimination() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegalDocumentScreen(
          title: 'Nondiscrimination Policy',
          body: kNondiscriminationPolicyText,
        ),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegalDocumentScreen(
          title: 'Privacy Policy',
          body: kPrivacyPolicyText,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _paymentsTap.dispose();
    _nondiscriminationTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: widget.linkColor,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      fontSize: widget.baseStyle?.fontSize,
    );
    return RichText(
      text: TextSpan(
        style: widget.baseStyle,
        children: [
          const TextSpan(
            text:
                'By selecting Agree & continue, I agree to ExpatHomes\' ',
          ),
          TextSpan(text: 'Terms of Service', style: linkStyle, recognizer: _termsTap),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'Payments Terms of Service',
            style: linkStyle,
            recognizer: _paymentsTap,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Nondiscrimination Policy',
            style: linkStyle,
            recognizer: _nondiscriminationTap,
          ),
          const TextSpan(text: ' and acknowledge the '),
          TextSpan(text: 'Privacy Policy', style: linkStyle, recognizer: _privacyTap),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
