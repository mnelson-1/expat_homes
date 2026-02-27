import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LandlordMakeListingScreen extends StatefulWidget {
  const LandlordMakeListingScreen({
    super.key,
    this.isEdit,
    this.initialTitle,
    this.initialPrice,
    this.initialUpi,
    this.initialLocation,
    this.initialDescription,
    this.initialOwnerName,
  });

  /// When true, the screen behaves as an "Edit Listing" form
  /// instead of "Make a Listing".
  final bool? isEdit;
  final String? initialTitle;
  final String? initialPrice;
  final String? initialUpi;
  final String? initialLocation;
  final String? initialDescription;
  final String? initialOwnerName;

  @override
  State<LandlordMakeListingScreen> createState() =>
      _LandlordMakeListingScreenState();
}

class _MakeListingColors {
  static const Color primaryDark = Color(0xFF1A2E35);
  static const Color accentGreen = Color(0xFF8ED966);
  static const Color border = Color(0xFF9E9E9E);
  static const Color hint = Color(0xFF9CA5A8);
  static const Color bodyText = Color(0xFF1A2E35);
}

class _LandlordMakeListingScreenState extends State<LandlordMakeListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _upiController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ownerNameController = TextEditingController();

  String _selectedType = 'Apartment';
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    if (!mounted || images.isEmpty) return;

    setState(() {
      _selectedImages = images;
    });
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _priceController.text = widget.initialPrice ?? '';
    _upiController.text = widget.initialUpi ?? '';
    _locationController.text = widget.initialLocation ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _ownerNameController.text = widget.initialOwnerName ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _upiController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isEditMode = widget.isEdit ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _MakeListingColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditMode ? 'Edit Listing' : 'Make a Listing',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel(textTheme, 'Property Title'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g 3–Bedroom Apartment etc.',
              ),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'Type of Property'),
              const SizedBox(height: 8),
              _buildTypeDropdown(textTheme),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'Price per month'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: 'price in usd (Fx‑rate aware)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'House UPI (Unique Parcel Identifier)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _upiController,
                hint: 'RHA given Land UPI',
              ),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'Location'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _locationController,
                hint: 'Enter house location',
              ),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'House Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Advertise your house',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildLabel(textTheme, 'Name of Land‑Owner'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ownerNameController,
                hint: 'Landlord name',
              ),
              const SizedBox(height: 24),
              _buildUploadBox(textTheme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final message = isEditMode
                        ? 'Changes saved (placeholder).'
                        : 'Listing submitted for verification.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _MakeListingColors.accentGreen,
                    foregroundColor: _MakeListingColors.bodyText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(isEditMode ? 'Save Changes' : 'Verify Listing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(TextTheme textTheme, String text) {
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: _MakeListingColors.bodyText,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: _MakeListingColors.bodyText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _MakeListingColors.hint,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _MakeListingColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _MakeListingColors.bodyText,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTypeDropdown(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _MakeListingColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: _MakeListingColors.bodyText),
          items: const [
            DropdownMenuItem(
              value: 'Apartment',
              child: Text('Apartment'),
            ),
            DropdownMenuItem(
              value: 'House',
              child: Text('House'),
            ),
            DropdownMenuItem(
              value: 'Short-Stay',
              child: Text('Short-Stay'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedType = value);
          },
          style: textTheme.bodyMedium?.copyWith(
            color: _MakeListingColors.bodyText,
          ),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUploadBox(TextTheme textTheme) {
    return GestureDetector(
      onTap: _pickImages,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: _MakeListingColors.border,
          borderRadius: BorderRadius.circular(8),
          strokeWidth: 1.0,
          dashLength: 6.0,
          gap: 4.0,
        ),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: _selectedImages.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: _MakeListingColors.hint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload pictures',
                      style: textTheme.bodySmall?.copyWith(
                        color: _MakeListingColors.hint,
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedImages
                        .map(
                          (image) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(image.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.dashLength = 6.0,
    this.gap = 4.0,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius.toRRect(rect);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDistance = distance + dashLength;
        dashedPath.addPath(
          metric.extractPath(
            distance,
            nextDistance.clamp(0.0, metric.length),
          ),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        gap != oldDelegate.gap ||
        borderRadius != oldDelegate.borderRadius;
  }
}

