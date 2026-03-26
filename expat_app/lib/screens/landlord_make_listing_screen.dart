import 'dart:async';
import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expat_app/models/listing.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/edit_requests_service.dart';
import 'package:expat_app/services/listings_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';

class LandlordMakeListingScreen extends StatefulWidget {
  const LandlordMakeListingScreen({
    super.key,
    this.isEdit,
    this.listingId,
    this.initialTitle,
    this.initialPrice,
    this.initialUpi,
    this.initialLocation,
    this.initialDescription,
    this.initialOwnerName,
  });

  /// When true, submitting creates an edit request instead of a new listing.
  final bool? isEdit;

  /// The listing being edited.
  final String? listingId;
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
  /// In-memory only — avoids Android clearing `code_cache` / picker paths before upload.
  List<Uint8List> _selectedImageBytes = [];
  bool _isLoading = false;
  String _loadingMessage = '';

  static ListingType _listingTypeFromUi(String uiType) {
    switch (uiType) {
      case 'House':
        return ListingType.house;
      case 'Short-Stay':
        return ListingType.shortStay;
      default:
        return ListingType.apartment;
    }
  }

  String get _priceFieldLabel =>
      _selectedType == 'Short-Stay' ? 'Price per night' : 'Price per month';

  Future<void> _submitListing(
    BuildContext context,
    bool isEditMode,
    TextTheme textTheme,
  ) async {
    final title = _titleController.text.trim();
    final priceInput = _priceController.text.trim();
    final priceStored = listingPriceNumericCore(priceInput);
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final upi = _upiController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a property title')),
      );
      return;
    }
    if (priceStored.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter price')));
      return;
    }
    if (location.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter location')));
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a listing'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage =
          _selectedImageBytes.isEmpty ? 'Saving listing...' : 'Preparing...';
    });
    try {
      if (isEditMode) {
        final lstId = widget.listingId;
        if (lstId == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot save: listing ID is missing.'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        setState(() => _loadingMessage = 'Submitting edit request...');
        await EditRequestsService().createEditRequest(
          listingId: lstId,
          landlordId: user.uid,
          proposedFields: {
            'title': title,
            'price': priceStored,
            'location': location,
            'description':
                description.isEmpty ? 'No description.' : description,
            'type': _listingTypeFromUi(_selectedType).value,
            if (upi.isNotEmpty) 'upi': upi,
          },
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit request submitted and awaiting approval.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      final svc = ListingsService();
      svc.onProgress = (message) {
        if (mounted) setState(() => _loadingMessage = message);
      };
      try {
        await svc
            .createListing(
              landlordId: user.uid,
              type: _listingTypeFromUi(_selectedType),
              title: title,
              description:
                  description.isEmpty ? 'No description.' : description,
              location: location,
              price: priceStored,
              upi: upi.isEmpty ? null : upi,
              imageBytes: _selectedImageBytes,
            )
            .timeout(
              const Duration(seconds: 120),
              onTimeout:
                  () =>
                      throw TimeoutException(
                        'Request timed out. Check: 1) Firebase Storage is enabled, 2) Storage rules allow uploads, 3) Your internet connection.',
                      ),
            );
      } finally {
        svc.onProgress = null;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing submitted for verification.')),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!context.mounted) return;
      String message;
      if (e is FirebaseException) {
        message =
            '${e.message ?? e.code}. Check Firebase Console: Storage enabled and rules allow uploads.';
      } else if (e is TimeoutException) {
        message =
            e.message ?? 'Timed out. See docs/FIREBASE_SETUP.md for checklist.';
      } else {
        message = '$e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $message'),
          duration: const Duration(seconds: 8),
        ),
      );
      debugPrint('createListing error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);

    if (!mounted || images.isEmpty) return;

    try {
      final out = <Uint8List>[];
      for (final x in images) {
        out.add(await x.readAsBytes());
      }
      if (!mounted) return;
      setState(() => _selectedImageBytes = out);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not use those photos (${e is FileSystemException ? 'file missing — pick again' : e}).',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _priceController.text = listingPriceNumericCore(
      widget.initialPrice ?? '',
    );
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
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
              _buildLabel(textTheme, _priceFieldLabel),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: 'Amount in USD (numbers only, e.g. 857)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  onPressed:
                      _isLoading
                          ? null
                          : () =>
                              _submitListing(context, isEditMode, textTheme),
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
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            isEditMode ? 'Save Changes' : 'Verify Listing',
                          ),
                ),
              ),
              if (_isLoading && _loadingMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _loadingMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: _MakeListingColors.hint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
      style: const TextStyle(color: _MakeListingColors.bodyText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _MakeListingColors.hint,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _MakeListingColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _MakeListingColors.bodyText),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: _MakeListingColors.bodyText,
          ),
          items: const [
            DropdownMenuItem(value: 'Apartment', child: Text('Apartment')),
            DropdownMenuItem(value: 'House', child: Text('House')),
            DropdownMenuItem(value: 'Short-Stay', child: Text('Short-Stay')),
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
          child:
              _selectedImageBytes.isEmpty
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
                      children:
                          _selectedImageBytes
                              .map(
                                (bytes) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      bytes,
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

    final Paint paint =
        Paint()
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
          metric.extractPath(distance, nextDistance.clamp(0.0, metric.length)),
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
