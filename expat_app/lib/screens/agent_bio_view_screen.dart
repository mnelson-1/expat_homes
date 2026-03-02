import 'package:flutter/material.dart';

import 'agent_edit_field_screen.dart';
import 'agent_reviews_screen.dart';

class AgentBioViewScreen extends StatefulWidget {
  const AgentBioViewScreen({super.key});

  @override
  State<AgentBioViewScreen> createState() => _AgentBioViewScreenState();
}

class _AgentBioViewScreenState extends State<AgentBioViewScreen> {
  static const Color _primaryDark = Color(0xFF1A2E35);
  static const Color _bodyText = Color(0xFF1A2E35);
  static const Color _hint = Color(0xFF9CA5A8);
  static const Color _reviewGreen = Color(0xFFD3F1C5);

  // For now we mirror the default Agent profile data; later this will come
  // from the signed-in agent's backend profile so Bio-View and Profile stay in sync.
  String _agentName = 'Jean Claude';
  String _agentId = 'KM-201903';
  String _bioText =
      'Fluent in Kinyarwanda, English, and French. Commission Rate starts at '
      '5% of sale price. Varies and Negotiable.';
  String _phone = '(+250) 0792106639';
  double _rating = 4.5;
  int _ratingCount = 10;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _onEditPictureTap(context),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 72,
                    backgroundColor: _hint.withOpacity(0.4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/agent_profile_placeholder.jpg',
                        fit: BoxFit.cover,
                        width: 144,
                        height: 144,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 72,
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edit Picture',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          _buildEditableRow(
            textTheme,
            title: _agentName,
            subtitle: _agentId,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          _buildEditableField(
            textTheme,
            label: 'Bio',
            value: _bioText,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          _buildEditableField(
            textTheme,
            label: 'Phone Number',
            value: _phone,
          ),
          const SizedBox(height: 24),
          _buildRatingsSummary(
            textTheme,
            rating: _rating,
            ratingCount: _ratingCount,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: _buildReviewsCarousel(textTheme),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AgentReviewsScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text('See all Reviews'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    TextTheme textTheme, {
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: _bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: _hint,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => _onEditNameTap(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/images/Edit Icon.png',
              width: 20,
              height: 20,
              color: _primaryDark,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.edit,
                size: 20,
                color: _primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    TextTheme textTheme, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: _bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: _bodyText,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () {
              if (label == 'Bio') {
                _onEditBioTap(context);
              } else if (label == 'Phone Number') {
                _onEditPhoneTap(context);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/images/Edit Icon.png',
              width: 20,
              height: 20,
              color: _primaryDark,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.edit,
                size: 20,
                color: _primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsSummary(
    TextTheme textTheme, {
    required double rating,
    required int ratingCount,
  }) {
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

  Widget _buildReviewsCarousel(TextTheme textTheme) {
    const String title = 'Behavioural Conduct';
    const String timeAgo = '6mon ago';
    const String text =
        'Was amiable, polite, and patient in our conversation. Helped me recognise my options, '
        'as well as provided advise and insights into the housing market as a whole.';

    final items = List<int>.generate(5, (index) => index);

    const gap = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: cardWidth + (index == items.length - 1 ? 0 : gap),
              child: Padding(
                padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : gap),
                child: Container(
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
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: _bodyText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStarRow(5, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            timeAgo,
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: textTheme.bodySmall?.copyWith(
                          color: _bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onEditPictureTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit picture from gallery will be enabled in the next phase.'),
      ),
    );
  }

  Future<void> _onEditNameTap(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit Name',
          label: 'Name',
          hintText: 'Your Name',
          helperText: 'Make sure this matches the name on your Broker ID.',
          initialValue: _agentName,
          keyboardType: TextInputType.name,
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _agentName = result.trim();
      });
    }
  }

  Future<void> _onEditBioTap(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit Bio',
          label: 'Bio',
          hintText: 'Type new description',
          helperText:
              'Advertise yourself – languages you speak, etc. – and state your rates.',
          initialValue: _bioText,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _bioText = result.trim();
      });
    }
  }

  Future<void> _onEditPhoneTap(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AgentEditFieldScreen(
          title: 'Edit Phone Number',
          label: 'Phone Number',
          hintText: 'Type new phone number',
          helperText: 'This will be used in receiving payments',
          initialValue: _phone,
          keyboardType: TextInputType.phone,
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _phone = result.trim();
      });
    }
  }
}

