import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet to compose a community post with optional photos (multi-select).
typedef CommunityPostSubmit = Future<void> Function(
  String content,
  List<XFile> images,
);

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

class CommunityPostComposerSheet extends StatefulWidget {
  const CommunityPostComposerSheet({
    super.key,
    required this.title,
    required this.onSubmit,
    this.accentGreen = const Color(0xFF8ED966),
    this.primaryDark = const Color(0xFF1A2E35),
    this.helper = const Color(0xFF9CA5A8),
    this.bodyText = const Color(0xFF1A2E35),
  });

  final String title;
  final CommunityPostSubmit onSubmit;
  final Color accentGreen;
  final Color primaryDark;
  final Color helper;
  final Color bodyText;

  /// Max images per post (storage / UX cap).
  static const int maxImages = 10;

  @override
  State<CommunityPostComposerSheet> createState() =>
      _CommunityPostComposerSheetState();
}

class _CommunityPostComposerSheetState
    extends State<CommunityPostComposerSheet> {
  final TextEditingController _text = TextEditingController();
  final List<_PickedImage> _images = [];
  bool _submitting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final t = _text.text.trim();
    return !_submitting && (t.isNotEmpty || _images.isNotEmpty);
  }

  Future<void> _pickImages() async {
    final remaining = CommunityPostComposerSheet.maxImages - _images.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final List<XFile> picked =
        await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;

    final toAdd = <_PickedImage>[];
    for (final x in picked) {
      if (_images.length + toAdd.length >= CommunityPostComposerSheet.maxImages) {
        break;
      }
      final bytes = await x.readAsBytes();
      toAdd.add(_PickedImage(x, bytes));
    }
    if (toAdd.isEmpty || !mounted) return;
    setState(() => _images.addAll(toAdd));
  }

  void _removeAt(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final files = _images.map((e) => e.file).toList();
      await widget.onSubmit(_text.text.trim(), files);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.bodyText,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What would you like to share?',
                hintStyle: TextStyle(color: widget.helper),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _images.length >= CommunityPostComposerSheet.maxImages
                  ? null
                  : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _images.isEmpty
                    ? 'Add photos'
                    : 'Add photos (${_images.length}/${CommunityPostComposerSheet.maxImages})',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.primaryDark,
                side: BorderSide(
                  color: widget.helper.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _images[index].bytes,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: Colors.black87,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _removeAt(index),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentGreen,
                  foregroundColor: widget.primaryDark,
                  disabledBackgroundColor:
                      widget.helper.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.primaryDark,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
