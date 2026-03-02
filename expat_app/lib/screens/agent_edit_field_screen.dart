import 'package:flutter/material.dart';

class AgentEditFieldScreen extends StatefulWidget {
  const AgentEditFieldScreen({
    super.key,
    required this.title,
    required this.label,
    required this.hintText,
    this.helperText,
    this.initialValue = '',
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String title;
  final String label;
  final String hintText;
  final String? helperText;
  final String initialValue;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  State<AgentEditFieldScreen> createState() => _AgentEditFieldScreenState();
}

class _AgentEditFieldScreenState extends State<AgentEditFieldScreen> {
  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _accentGreen = Color(0xFF8ED966);
  static const Color _bodyText = Color(0xFF1A2E35);
  static const Color _hint = Color(0xFF9CA5A8);

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: _bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    keyboardType: widget.keyboardType,
                    maxLines: widget.maxLines,
                    style: const TextStyle(
                      color: _bodyText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        color: _hint,
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
                          color: _bodyText,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (widget.helperText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.helperText!,
                      style: textTheme.bodySmall?.copyWith(
                        color: _hint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: _bodyText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value);
  }
}

