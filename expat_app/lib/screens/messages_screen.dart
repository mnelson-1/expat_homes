import 'package:flutter/material.dart';

import 'package:expat_app/models/conversation.dart';
import 'package:expat_app/models/chat_message.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/conversations_service.dart';
import 'package:expat_app/utils/listing_price_display.dart';
import 'package:expat_app/models/listing.dart';
import 'agent_home_screen.dart';
import 'landlord_home_screen.dart';
import 'listing_detail_screen.dart';

const String kRoleLandlord = 'landlord';
const String kRoleAgent = 'agent';
const String kRoleExpat = 'expat';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.emptyStateMessage,
    String? currentUserRole,
  }) : currentUserRole = currentUserRole ?? kRoleExpat;

  final String? emptyStateMessage;
  final String currentUserRole;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const List<BoxShadow> _headerShadow = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 6), blurRadius: 10),
  ];

  String? _uid;
  Stream<List<Conversation>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _uid = AuthService().currentUser?.uid;
    if (_uid != null) {
      _conversationsStream = ConversationsService().conversationsStream(_uid!);
    }
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
          child:
              _uid == null || _conversationsStream == null
                  ? _buildEmptyState(textTheme)
                  : StreamBuilder<List<Conversation>>(
                    stream: _conversationsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final convos = snapshot.data ?? [];
                      if (convos.isEmpty) {
                        return _buildEmptyState(textTheme);
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 56),
                        itemCount: convos.length,
                        itemBuilder: (context, index) {
                          final convo = convos[index];
                          return _buildThreadRow(context, textTheme, convo);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 56),
      children: [
        const SizedBox(height: 200),
        Center(
          child: Text(
            widget.emptyStateMessage ??
                'You have no messages yet. Make enquiries\non listings and watch the magic happen.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9CA5A8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreadRow(
    BuildContext context,
    TextTheme textTheme,
    Conversation convo,
  ) {
    final myUid = _uid!;
    final contactName = convo.contactName(myUid);
    final lastMessage = convo.lastMessage ?? '';
    final lastTime = convo.lastMessageAt ?? convo.createdAt;

    final now = DateTime.now();
    final timeLabel = lastTime != null ? _formatThreadTime(lastTime, now) : '';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => ConversationScreen(
                  conversationId: convo.id,
                  listingTitle: convo.listingTitle,
                  location: convo.listingLocation,
                  price: formatConversationListingPrice(convo.listingPrice),
                  imagePath: convo.listingImage,
                  contactName: contactName,
                  listingDetailRole: widget.currentUserRole,
                ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1A2E35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1A2E35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9CA5A8),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA5A8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _formatThreadTime(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'now';
  final sameDay =
      then.year == now.year && then.month == now.month && then.day == now.day;
  if (sameDay) return _formatTime(then);
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      then.year == yesterday.year &&
      then.month == yesterday.month &&
      then.day == yesterday.day;
  if (isYesterday) return 'Yesterday';
  return _formatTime(then);
}

// ---------------------------------------------------------------------------
// ConversationScreen — real-time Firestore chat
// ---------------------------------------------------------------------------

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.listingTitle,
    required this.location,
    required this.price,
    required this.imagePath,
    this.contactName = 'Contact',
    this.returnToLandlordOnBack = false,
    this.returnToAgentMessagesOnBack = false,
    String? listingDetailRole,
  }) : listingDetailRole = listingDetailRole ?? kRoleExpat;

  final String conversationId;
  final String listingTitle;
  final String location;
  final String price;
  final String imagePath;
  final String contactName;
  final bool returnToLandlordOnBack;
  final bool returnToAgentMessagesOnBack;
  final String listingDetailRole;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _liveTranslateEnabled = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _myUid;
  Stream<List<ChatMessage>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _myUid = AuthService().currentUser?.uid;
    _messagesStream = ConversationsService().messagesStream(
      widget.conversationId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myUid == null) return;
    _messageController.clear();
    ConversationsService().sendMessage(
      conversationId: widget.conversationId,
      senderId: _myUid!,
      content: text,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, textTheme),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                _scrollToBottom();
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  children: [
                    _buildDateAndEncryption(textTheme),
                    const SizedBox(height: 24),
                    _buildListingCard(context, textTheme),
                    ...messages.map((m) {
                      final isMe = m.senderId == _myUid;
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child:
                            isMe
                                ? _buildOutgoingBubble(textTheme, m.content)
                                : _buildIncomingBubble(textTheme, m.content),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          _buildComposer(context, textTheme),
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {
                if (widget.returnToLandlordOnBack) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LandlordHomeScreen(initialIndex: 2),
                    ),
                  );
                } else if (widget.returnToAgentMessagesOnBack) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const AgentHomeScreen(initialIndex: 2),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(child: _buildHeaderContactRow(context, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContactRow(BuildContext context, TextTheme textTheme) {
    final row = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contactName,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.listingTitle,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    return row;
  }

  Widget _buildDateAndEncryption(TextTheme textTheme) {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final dateLabel = '$day/$month/$year';
    return Column(
      children: [
        Text(
          dateLabel,
          style: textTheme.bodySmall?.copyWith(color: const Color(0xFF1A2E35)),
        ),
        const SizedBox(height: 4),
        Text(
          'This chat is end-end encrypted',
          style: textTheme.bodySmall?.copyWith(color: const Color(0xFF1A2E35)),
        ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context, TextTheme textTheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: InkWell(
          onTap: () => _onListingCardTap(context),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Text(
                      widget.listingTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF1A2E35),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                AspectRatio(aspectRatio: 4 / 3, child: _buildCardImage()),
                Container(
                  color: const Color(0xFF1A2E35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatConversationListingPrice(widget.price),
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.location,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _onListingCardTap(context),
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
      ),
    );
  }

  Widget _buildCardImage() {
    final path = widget.imagePath;
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade300);
    }
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }

  void _onListingCardTap(BuildContext context) {
    final role = widget.listingDetailRole;
    final showRequestEditOnly = role == kRoleLandlord;
    final showAgentActions = role == kRoleAgent;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => ListingDetailScreen(
              title: widget.listingTitle,
              location: widget.location,
              price: widget.price,
              listingType: ListingType.apartment,
              typeLabel: 'Apartment',
              imagePaths: widget.imagePath.isNotEmpty ? [widget.imagePath] : [],
              description:
                  'Detailed information about this listing will appear here once connected to the backend.',
              upi: showRequestEditOnly ? null : 'RHA Land UPI (placeholder)',
              isVerifiedByRdb: true,
              representativeName: widget.contactName,
              showRequestEditOnly: showRequestEditOnly,
              showAgentActions: showAgentActions,
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
          style: textTheme.bodyMedium?.copyWith(color: Colors.white),
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
          style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF1A2E35)),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, TextTheme textTheme) {
    const panelBg = Color(0xFF1A2E35);
    const accentGreen = Color(0xFF8ED966);
    const hintColor = Color(0xFF9CA5A8);

    return Container(
      color: panelBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translate',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _liveTranslateEnabled = !_liveTranslateEnabled;
                      });
                    },
                    child: SizedBox(
                      width: 64,
                      height: 24,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color:
                              _liveTranslateEnabled
                                  ? accentGreen
                                  : hintColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              alignment:
                                  _liveTranslateEnabled
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    color: const Color(0xFF243A42),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hintColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type something...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: hintColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _onSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _onSend,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF8ED966),
                          size: 22,
                        ),
                      ),
                    ],
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
