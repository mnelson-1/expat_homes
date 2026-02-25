import 'package:flutter/material.dart';

/// Empty-state view for the Messages tab.
///
/// When messages are populated and the list becomes scrollable,
/// a drop shadow appears under the Messages header while any
/// part of the list is scrolled beneath it.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const List<BoxShadow> _headerShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 6),
      blurRadius: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (_scrollOffset != offset) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool showShadow = _scrollOffset > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: showShadow ? _headerShadow : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Center(
            child: Text(
              'Messages',
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1A2E35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 56),
            children: [
              const SizedBox(height: 200),
              Center(
                child: Text(
                  'You have no messages yet. Make enquiries\non listings and watch the magic happen.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9CA5A8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Conversation thread screen opened after tapping "Inquire".
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.listingTitle,
    required this.location,
    required this.price,
    required this.imagePath,
    this.contactName = 'Jean Claude',
    this.contactSubtitle = 'Agent of Elizabeth G. Apartments',
  });

  final String listingTitle;
  final String location;
  final String price;
  final String imagePath;
  final String contactName;
  final String contactSubtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                _buildDateAndEncryption(textTheme),
                const SizedBox(height: 24),
                _buildListingCard(context, textTheme),
                const SizedBox(height: 12),
                _buildOutgoingBubble(
                  textTheme,
                  'Hey there! I would like to get more\ninformation on this Listing.',
                ),
                const SizedBox(height: 24),
                _buildIncomingBubble(
                  textTheme,
                  'Hello, how can I help you?',
                ),
                const SizedBox(height: 24),
                _buildTypingIndicatorRow(),
              ],
            ),
          ),
          _buildComposer(textTheme),
        ],
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
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contactName,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contactSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndEncryption(TextTheme textTheme) {
    return Column(
      children: [
        Text(
          '09/02/2026',
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF9CA5A8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This chat is end-end encrypted',
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF9CA5A8),
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context, TextTheme textTheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF8ED966),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: Text(
                    listingTitle,
                    style: textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF1A2E35),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              Container(
                color: const Color(0xFF1A2E35),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(); // back to detail screen
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD54F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_outward,
                          size: 18,
                          color: Color(0xFF1A2E35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingBubble(TextTheme textTheme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8ED966),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF1A2E35),
          ),
        ),
      ),
    );
  }

  Widget _buildOutgoingBubble(TextTheme textTheme, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF8ED966),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Dot(),
            _Dot(),
            _Dot(),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(TextTheme textTheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: false,
                  onChanged: (_) {},
                  activeColor: const Color(0xFF8ED966),
                ),
                Text(
                  'Live-Translate',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1A2E35),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF9CA5A8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Type something...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9CA5A8),
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8ED966),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: Color(0xFF1A2E35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2E35),
        shape: BoxShape.circle,
      ),
    );
  }
}


