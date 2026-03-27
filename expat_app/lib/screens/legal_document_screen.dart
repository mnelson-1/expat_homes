import 'package:flutter/material.dart';

/// Scrollable legal copy (Privacy, EULA, Payments, Nondiscrimination).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A2E35),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SelectableText(
            body.trim(),
            style: textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: const Color(0xFF1A2E35),
            ),
          ),
        ),
      ),
    );
  }
}
