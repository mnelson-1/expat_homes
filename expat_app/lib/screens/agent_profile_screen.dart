import 'package:flutter/material.dart';

import 'landlord_assign_property_screen.dart';

/// Agent profile screen shown when the user taps the agent's profile
/// in the chat view (when the listing representative is an agent).
class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({
    super.key,
    this.agentName = 'Jean Claude',
    this.agentFullName = 'Jean D. Claude',
    this.agentId = 'KM-201903',
    this.locationTag = 'Kimironko',
    this.bio,
    this.phone = '(+250) 0792106639',
    this.rating = 4.5,
    this.ratingCount = 10,
    this.bannerImagePath,
    this.reviews = const [],
    this.showAssignProperty = false,
  });

  final String agentName;
  final String agentFullName;
  final String agentId;
  final String locationTag;
  final String? bio;
  final String phone;
  final double rating;
  final int ratingCount;
  final String? bannerImagePath;
  final List<AgentProfileReview> reviews;
  final bool showAssignProperty;

  static const Color _headerDark = Color(0xFF1A2E35);
  static const Color _bodyText = Color(0xFF1A2E35);
  static const Color _hint = Color(0xFF9CA5A8);
  /// Verification badge and "RWAREB verified Agent" (blue for contrast on white).
  static const Color _verifiedBlue = Color(0xFF1976D2);
  static const Color _reviewGreen = Color(0xFFD3F1C5);
  static const Color _accentGreen = Color(0xFF8ED966);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final defaultBio =
        'Fluent in Kinyarwanda, English, and French. Commission Rate starts at 5% of sale price. Varies and Negotiable.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agentName,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    agentId,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNameAndLocation(textTheme),
                  const SizedBox(height: 6),
                  Text(
                    'Agent ID: $agentId',
                    style: textTheme.bodySmall?.copyWith(
                      color: _hint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildVerifiedRow(textTheme),
                  const SizedBox(height: 16),
                  Text(
                    'Bio: ${bio ?? defaultBio}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _bodyText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Phone Number: $phone',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _bodyText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRatingsRow(textTheme),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: _buildReviewsSection(context, textTheme),
                  ),
                  const SizedBox(height: 20),
                  _buildTapToRate(textTheme),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, textTheme, showAssignProperty),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: bannerImagePath != null && bannerImagePath!.isNotEmpty
          ? Image.asset(
              bannerImagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _bannerPlaceholder(),
            )
          : _bannerPlaceholder(),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: _hint.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.person, size: 80, color: Color(0xFF9CA5A8)),
      ),
    );
  }

  Widget _buildNameAndLocation(TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            agentFullName,
            style: textTheme.titleLarge?.copyWith(
              color: _bodyText,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hint.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            locationTag,
            style: textTheme.bodySmall?.copyWith(
              color: _bodyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedRow(TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.verified, size: 18, color: _verifiedBlue),
        const SizedBox(width: 6),
        Text(
          'RWAREB verified Agent',
          style: textTheme.bodySmall?.copyWith(
            color: _verifiedBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsRow(TextTheme textTheme) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rating',
              style: textTheme.headlineMedium?.copyWith(
                color: _bodyText,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Rated',
              style: textTheme.bodySmall?.copyWith(color: _hint),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStarRow(rating, size: 20),
            const SizedBox(height: 2),
            Text(
              '$ratingCount+ Ratings',
              style: textTheme.bodySmall?.copyWith(color: _hint),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStarRow(double value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1).toDouble() <= value;
        final half = !filled && (i.toDouble() < value);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
              size: size,
              color: _bodyText,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewsSection(BuildContext context, TextTheme textTheme) {
    final defaultReview = AgentProfileReview(
      title: 'Behavioural Conduct',
      rating: 5,
      timeAgo: '6mon ago',
      text:
          'Was amiable, polite, and patient in our conversation. Helped me recognise my options, as well as provided advise and insights into the housing market as a whole.',
    );
    final items = reviews.isEmpty
        ? List<AgentProfileReview>.generate(5, (_) => defaultReview)
        : reviews;

    const gap = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return ClipRect(
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final r = items[index];
                return SizedBox(
                  width: cardWidth + gap,
                  child: Padding(
                    padding: EdgeInsets.only(right: gap),
                    child: SizedBox(
                      width: cardWidth,
                      child: _buildReviewCard(r, textTheme),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(AgentProfileReview r, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _reviewGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            r.title,
            style: textTheme.titleSmall?.copyWith(
              color: _bodyText,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStarRow(r.rating.toDouble(), size: 14),
              const SizedBox(width: 6),
              Text(
                r.timeAgo,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A2E35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                r.text,
                style: textTheme.bodySmall?.copyWith(
                  color: _bodyText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapToRate(TextTheme textTheme) {
    int currentRating = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: Column(
            children: [
              Text(
                'Tap to Rate',
                style: textTheme.bodyMedium?.copyWith(
                  color: _hint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= currentRating;

                  return IconButton(
                    padding: const EdgeInsets.only(right: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      size: 28,
                      color: isFilled ? _bodyText : _hint,
                    ),
                    onPressed: () {
                      setState(() {
                        currentRating = starIndex;
                      });
                      _showRatingSuccessDialog(context, textTheme);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRatingSuccessDialog(
      BuildContext context, TextTheme textTheme) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: _verifiedBlue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: _bodyText,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating Successful',
                  style: textTheme.titleLarge?.copyWith(
                    color: _bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This helps the agent improve, and also lets us know areas to improve on.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _bodyText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: _bodyText,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext context, TextTheme textTheme, bool showAssignProperty) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              // Placeholder for future review flow.
            },
            style: FilledButton.styleFrom(
              backgroundColor: _headerDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Write a Review'),
          ),
        ),
        if (showAssignProperty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LandlordAssignPropertyScreen(
                      agentName: agentFullName,
                      agentId: agentId,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: _bodyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Assign Property'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Data for a single review on the agent profile.
class AgentProfileReview {
  AgentProfileReview({
    required this.title,
    required this.rating,
    required this.timeAgo,
    required this.text,
  });
  final String title;
  final int rating;
  final String timeAgo;
  final String text;
}
