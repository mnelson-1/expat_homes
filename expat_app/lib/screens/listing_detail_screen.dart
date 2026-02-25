import 'package:flutter/material.dart';

import 'messages_screen.dart';

/// Detail page for a single estate listing.
/// This will later be wired up to real data from the backend.
class ListingDetailScreen extends StatelessWidget {
  ListingDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.typeLabel,
    required this.imagePaths,
    required this.description,
    this.isVerifiedByRdb = true,
    this.representativeName,
  });

  final String title;
  final String location;
  final String price; // e.g. "\$2268/mo"
  final String typeLabel; // e.g. "Apartment", "House", "Short-Stay"
  final List<String> imagePaths;
  final String description;
  final bool isVerifiedByRdb;
  /// Optional agent/landlord representative; when null, the section is hidden.
  final String? representativeName;

  // Tracks whether content has been scrolled to show a drop shadow above buttons.
  final ValueNotifier<bool> _showBottomShadow = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = PageController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.vertical) {
                  final metrics = notification.metrics;
                  // Show shadow whenever content is scrollable and
                  // we're NOT at the very bottom. At the bottom, hide it.
                  final bool showShadow =
                      metrics.maxScrollExtent > 0 &&
                      metrics.pixels < metrics.maxScrollExtent;
                  if (_showBottomShadow.value != showShadow) {
                    _showBottomShadow.value = showShadow;
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(controller),
                    _buildPriceAndType(textTheme),
                    _buildLocationAndVerification(textTheme),
                    const SizedBox(height: 16),
                    _buildDescriptionBlock(textTheme),
                    const SizedBox(height: 16),
                    _buildRepresentative(textTheme),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _showBottomShadow,
        builder: (context, showShadow, _) =>
            _buildBottomActions(context, textTheme, showShadow: showShadow),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Container(
      color: const Color(0xFF1A2E35),
      padding: const EdgeInsets.only(top: 40, left: 8, right: 16, bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(PageController controller) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final path = imagePaths[index];
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(
                  imagePaths.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndType(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                  children: [
                    TextSpan(
                      text: price.split('/').first,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (price.contains('/'))
                      TextSpan(
                        text: '/${price.split('/')[1]}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF1A2E35),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9CA5A8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              typeLabel,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1A2E35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndVerification(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
          const SizedBox(height: 8),
          if (isVerifiedByRdb)
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: Color(0xFF1A2E35)),
                const SizedBox(width: 4),
                Text(
                  'Listing and Location Verified by the RDB',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9CA5A8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBlock(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1A2E35),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1A2E35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentative(TextTheme textTheme) {
    if (representativeName == null || representativeName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Color(0xFF1A2E35)),
              const SizedBox(width: 6),
              Text(
                'Representative:',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A2E35),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  representativeName!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    TextTheme textTheme, {
    required bool showShadow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, -6),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2E35),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Get a Ride',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF1A2E35),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Explore Area',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(
                          listingTitle: title,
                          location: location,
                          price: price,
                          imagePath: imagePaths.isNotEmpty
                              ? imagePaths.first
                              : '',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8ED966),
                    foregroundColor: const Color(0xFF1A2E35),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    'Inquire',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          (textTheme.titleMedium?.fontSize ?? 16) + 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

