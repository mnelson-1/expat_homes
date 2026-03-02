import 'package:flutter/material.dart';

class AgentReviewsScreen extends StatelessWidget {
  const AgentReviewsScreen({super.key});

  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _bodyText = Color(0xFF1A2E35);
  static const Color _reviewGreen = Color(0xFFD3F1C5);

  static final List<_AgentReview> _reviews = [
    _AgentReview(
      title: 'Behavioural Conduct',
      rating: 5,
      timeAgo: '6mon ago',
      text:
          'Was amiable, polite, and patient in our conversation. Helped me recognise my options, '
          'as well as provided advise and insights into the housing market as a whole.',
      createdAt: DateTime(2026, 3, 2),
    ),
    _AgentReview(
      title: 'Behavioural Conduct',
      rating: 5,
      timeAgo: '6mon ago',
      text:
          'Was amiable, polite, and patient in our conversation. Helped me recognise my options, '
          'as well as provided advise and insights into the housing market as a whole.',
      createdAt: DateTime(2026, 3, 2),
    ),
    _AgentReview(
      title: 'Behavioural Conduct',
      rating: 5,
      timeAgo: '6mon ago',
      text:
          'Was amiable, polite, and patient in our conversation. Helped me recognise my options, '
          'as well as provided advise and insights into the housing market as a whole.',
      createdAt: DateTime(2026, 3, 1),
    ),
    _AgentReview(
      title: 'Behavioural Conduct',
      rating: 5,
      timeAgo: '6mon ago',
      text:
          'Was amiable, polite, and patient in our conversation. Helped me recognise my options, '
          'as well as provided advise and insights into the housing market as a whole.',
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

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
          'All Reviews',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(textTheme),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    final reviews = List<_AgentReview>.from(_reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<Widget> children = [];
    DateTime? lastDate;

    for (final review in reviews) {
      final isNewDate =
          lastDate == null || !_isSameDay(lastDate, review.createdAt);

      if (isNewDate) {
        if (lastDate != null) {
          children.add(const SizedBox(height: 18));
        }
        children.add(_buildDateHeader(textTheme, review.createdAt));
        children.add(const SizedBox(height: 12));
        lastDate = _startOfDay(review.createdAt);
      } else {
        children.add(const SizedBox(height: 12));
      }

      children.add(_buildReviewCard(textTheme, review));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: children,
    );
  }

  Widget _buildDateHeader(TextTheme textTheme, DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final label = '$day/$month/$year';

    return Center(
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: _bodyText,
        ),
      ),
    );
  }

  Widget _buildReviewCard(TextTheme textTheme, _AgentReview review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _reviewGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            review.title,
            style: textTheme.titleSmall?.copyWith(
              color: _bodyText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStarRow(textTheme, review.rating.toDouble(), size: 14),
              const SizedBox(width: 6),
              Text(
                review.timeAgo,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1A2E35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: textTheme.bodySmall?.copyWith(
              color: _bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(TextTheme textTheme, double value, {double size = 16}) {
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

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _AgentReview {
  const _AgentReview({
    required this.title,
    required this.rating,
    required this.timeAgo,
    required this.text,
    required this.createdAt,
  });

  final String title;
  final int rating;
  final String timeAgo;
  final String text;
  final DateTime createdAt;
}

