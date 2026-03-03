import 'package:flutter/material.dart';

import 'agent_home_screen.dart';
import 'agent_profile_screen.dart';
import 'landlord_home_screen.dart';
import 'listing_detail_screen.dart';

/// Normalizes price string for display: "/per month" -> "/mo", "/per night" -> "/night".
String _normalizePriceForDisplay(String price) {
  if (!price.contains('/')) return price;
  final parts = price.split('/');
  final amount = parts[0];
  final suffix = parts.length > 1 ? parts[1].trim().toLowerCase() : '';
  if (suffix == 'per month') return '$amount/mo';
  if (suffix == 'per night') return '$amount/night';
  return price;
}

/// Empty-state view for the Messages tab.
///
/// When messages are populated and the list becomes scrollable,
/// a drop shadow appears under the Messages header while any
/// part of the list is scrolled beneath it.
/// Role that owns this thread; only that role's Messages tab shows it.
const String kRoleLandlord = 'landlord';
const String kRoleAgent = 'agent';
const String kRoleExpat = 'expat';

class ChatThread {
  ChatThread({
    required this.contactName,
    required this.contactSubtitle,
    required this.lastMessage,
    required this.lastUpdated,
    required this.listingTitle,
    required this.location,
    required this.price,
    required this.imagePath,
    required this.forRole,
  });

  final String contactName;
  final String contactSubtitle;
  final String lastMessage;
  final DateTime lastUpdated;
  final String listingTitle;
  final String location;
  final String price;
  final String imagePath;
  /// Which user role this thread belongs to: [kRoleLandlord], [kRoleAgent], or [kRoleExpat].
  final String forRole;
}

final List<ChatThread> _chatThreads = [];
final ValueNotifier<List<ChatThread>> chatThreadsNotifier =
    ValueNotifier<List<ChatThread>>([]);

void addOrUpdateChatThread(ChatThread thread) {
  final index = _chatThreads.indexWhere((t) =>
      t.contactName == thread.contactName &&
      t.contactSubtitle == thread.contactSubtitle &&
      t.forRole == thread.forRole);
  if (index >= 0) {
    _chatThreads[index] = thread;
  } else {
    _chatThreads.add(thread);
  }
  chatThreadsNotifier.value = List.from(_chatThreads);
}

void addOrUpdateChatThreadForAgent({
  required String agentName,
  required String agentId,
  required String message,
  required String listingTitle,
  required String location,
  required String price,
  required String imagePath,
}) {
  addOrUpdateChatThread(
    ChatThread(
      contactName: agentName,
      contactSubtitle: agentId,
      lastMessage: message,
      lastUpdated: DateTime.now(),
      listingTitle: listingTitle,
      location: location,
      price: price,
      imagePath: imagePath,
      forRole: kRoleLandlord,
    ),
  );
}

/// Call when an Agent taps "Chat Landlord" so the conversation appears in the Messages tab.
/// [contactName] is the landlord's name (main title); subtitle is always "Landlord of [listing]".
void addOrUpdateChatThreadForAgentLandlordChat({
  required String contactName,
  required String listingTitle,
  required String location,
  required String price,
  required String imagePath,
  String lastMessage =
      'Hi there. I would like for you to represent me in the sale of this listing.',
}) {
  final subtitle = 'Landlord of $listingTitle';
  final existingIndex = _chatThreads.indexWhere(
    (t) => t.listingTitle == listingTitle && t.contactSubtitle == subtitle,
  );
  if (existingIndex >= 0) {
    return;
  }

  addOrUpdateChatThread(
    ChatThread(
      contactName: contactName,
      contactSubtitle: subtitle,
      lastMessage: lastMessage,
      lastUpdated: DateTime.now(),
      listingTitle: listingTitle,
      location: location,
      price: price,
      imagePath: imagePath,
      forRole: kRoleAgent,
    ),
  );
}

/// Returns the last message text for a given landlord/listing thread,
/// or null if no such thread exists.
String? getLastMessageForAgentLandlordChat({
  required String listingTitle,
}) {
  final subtitle = 'Landlord of $listingTitle';
  for (final thread in _chatThreads) {
    if (thread.listingTitle == listingTitle &&
        thread.contactSubtitle == subtitle) {
      return thread.lastMessage;
    }
  }
  return null;
}

/// Call when an Expat inquires on a listing so the conversation appears
/// in the Messages tab with timestamp and preview (parity with Landlord).
void addOrUpdateChatThreadForExpatInquiry({
  required String contactName,
  required String contactSubtitle,
  required String listingTitle,
  required String location,
  required String price,
  required String imagePath,
  String lastMessage =
      'Hey there! I would like to get more\ninformation on this Listing.',
}) {
  addOrUpdateChatThread(
    ChatThread(
      contactName: contactName,
      contactSubtitle: contactSubtitle,
      lastMessage: lastMessage,
      lastUpdated: DateTime.now(),
      listingTitle: listingTitle,
      location: location,
      price: price,
      imagePath: imagePath,
      forRole: kRoleExpat,
    ),
  );
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.emptyStateMessage,
    String? currentUserRole,
  }) : currentUserRole = currentUserRole ?? kRoleExpat;

  final String? emptyStateMessage;
  /// Only threads with [forRole] == [currentUserRole] are shown. Use [kRoleLandlord], [kRoleAgent], or [kRoleExpat].
  final String currentUserRole;

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
          child: ValueListenableBuilder<List<ChatThread>>(
            valueListenable: chatThreadsNotifier,
            builder: (context, threads, _) {
              final forCurrentRole = threads
                  .where((t) => t.forRole == widget.currentUserRole)
                  .toList();
              if (forCurrentRole.isEmpty) {
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
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 56),
                itemCount: forCurrentRole.length,
                itemBuilder: (context, index) {
                  final thread = forCurrentRole[index];
                  return _buildThreadRow(context, textTheme, thread);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThreadRow(
    BuildContext context,
    TextTheme textTheme,
    ChatThread thread,
  ) {
    final now = DateTime.now();
    final diff = now.difference(thread.lastUpdated);
    final timeLabel = _formatThreadTime(thread.lastUpdated, now, diff);

    final isAgentLandlordThread = thread.contactSubtitle.startsWith('Landlord of ');
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(
              listingTitle: thread.listingTitle,
              location: thread.location,
              price: thread.price,
              imagePath: thread.imagePath,
              contactName: thread.contactName,
              contactSubtitle: thread.contactSubtitle,
              initialMessage: thread.lastMessage,
              storedMessages: getStoredMessagesForThread(
                thread.contactName,
                thread.contactSubtitle,
                thread.listingTitle,
              ),
              showInitialAsIncoming: isAgentLandlordThread,
              listingFromOtherParty: isAgentLandlordThread,
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
                    thread.contactName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1A2E35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.lastMessage,
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
                const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF9CA5A8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute;
  final hh = h.toString().padLeft(2, '0');
  final mm = m.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Timestamp for the Messages tab thread list: "now", "Today", "Yesterday", or time.
String _formatThreadTime(DateTime then, DateTime now, Duration diff) {
  if (diff.inMinutes < 1) return 'now';
  final sameDay = then.year == now.year &&
      then.month == now.month &&
      then.day == now.day;
  if (sameDay) return _formatTime(then);
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = then.year == yesterday.year &&
      then.month == yesterday.month &&
      then.day == yesterday.day;
  if (isYesterday) return 'Yesterday';
  return _formatTime(then);
}

/// Single message in a conversation. Rule: user sent = right, blue; received = left, green.
class ConversationMessage {
  const ConversationMessage({required this.text, required this.isFromUser});
  final String text;
  final bool isFromUser;
}

/// In-memory store for conversation messages until backend persists them.
/// Key: contactName|contactSubtitle|listingTitle. When backend exists, replace with API load/save.
final Map<String, List<ConversationMessage>> _conversationMessageStore = {};

String _threadKey(String contactName, String contactSubtitle, String listingTitle) =>
    '$contactName|$contactSubtitle|$listingTitle';

List<ConversationMessage> getStoredMessagesForThread(
  String contactName,
  String contactSubtitle,
  String listingTitle,
) {
  final key = _threadKey(contactName, contactSubtitle, listingTitle);
  return List.from(_conversationMessageStore[key] ?? []);
}

void appendMessageToStore(
  String contactName,
  String contactSubtitle,
  String listingTitle,
  ConversationMessage message,
) {
  final key = _threadKey(contactName, contactSubtitle, listingTitle);
  _conversationMessageStore[key] ??= [];
  _conversationMessageStore[key]!.add(message);
}

/// Conversation thread screen opened after tapping "Inquire" (Expat) or
/// after assigning a property (Landlord).
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.listingTitle,
    required this.location,
    required this.price,
    required this.imagePath,
    this.contactName = 'Jean Claude',
    this.contactSubtitle = 'Agent of Elizabeth G. Apartments',
    this.initialMessage,
    this.storedMessages,
    this.returnToLandlordOnBack = false,
    this.returnToAgentMessagesOnBack = false,
    this.showInitialAsIncoming = false,
    this.listingFromOtherParty = false,
    String? listingDetailRole,
  }) : listingDetailRole = listingDetailRole ?? kRoleExpat;

  final String listingTitle;
  final String location;
  final String price;
  final String imagePath;
  final String contactName;
  final String contactSubtitle;
  final String? initialMessage;
  /// Persisted messages for this thread (so chat continues when reopened). When backend exists, load from API.
  final List<ConversationMessage>? storedMessages;
  /// When true (Landlord flow), back button goes to Landlord home Messages tab.
  final bool returnToLandlordOnBack;
  /// When true (Agent flow from Chat Landlord), back button goes to Agent home Messages tab.
  final bool returnToAgentMessagesOnBack;
  /// When true, the [initialMessage] is rendered as an incoming (green) bubble
  /// instead of an outgoing (blue) one.
  final bool showInitialAsIncoming;
  /// When true, the listing card is visually aligned as if it was sent by the
  /// other party (left-aligned); otherwise it is aligned as the current user's card.
  final bool listingFromOtherParty;
  /// Role used when opening listing detail from the card: [kRoleLandlord] = Request Edit,
  /// [kRoleAgent] = Decline/Accept/Chat Landlord, [kRoleExpat] = Get a Ride/Explore/Inquire.
  final String listingDetailRole;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _liveTranslateEnabled = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ConversationMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    final stored = widget.storedMessages ?? getStoredMessagesForThread(
      widget.contactName,
      widget.contactSubtitle,
      widget.listingTitle,
    );
    if (stored.isNotEmpty) {
      _messages.addAll(stored);
    } else if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      final initial = ConversationMessage(
        text: widget.initialMessage!,
        isFromUser: !widget.showInitialAsIncoming,
      );
      _messages.add(initial);
      appendMessageToStore(
        widget.contactName,
        widget.contactSubtitle,
        widget.listingTitle,
        initial,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final message = ConversationMessage(text: text, isFromUser: true);
    setState(() {
      _messages.add(message);
    });
    appendMessageToStore(
      widget.contactName,
      widget.contactSubtitle,
      widget.listingTitle,
      message,
    );
    _updateThreadLastMessage(text);
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

  void _updateThreadLastMessage(String lastMessage) {
    final index = _chatThreads.indexWhere(
      (t) =>
          t.contactName == widget.contactName &&
          t.contactSubtitle == widget.contactSubtitle &&
          t.listingTitle == widget.listingTitle,
    );
    if (index >= 0) {
      final t = _chatThreads[index];
      _chatThreads[index] = ChatThread(
        contactName: t.contactName,
        contactSubtitle: t.contactSubtitle,
        lastMessage: lastMessage,
        lastUpdated: DateTime.now(),
        listingTitle: t.listingTitle,
        location: t.location,
        price: t.price,
        imagePath: t.imagePath,
        forRole: t.forRole,
      );
      chatThreadsNotifier.value = List.from(_chatThreads);
    }
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
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                _buildDateAndEncryption(textTheme),
                const SizedBox(height: 24),
                _buildListingCard(context, textTheme),
                ..._messages.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: m.isFromUser
                        ? _buildOutgoingBubble(textTheme, m.text)
                        : _buildIncomingBubble(textTheme, m.text),
                  );
                }),
              ],
            ),
          ),
          _buildComposer(context, textTheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    final contactName = widget.contactName;
    final contactSubtitle = widget.contactSubtitle;
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
              onPressed: () {
                if (widget.returnToLandlordOnBack) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LandlordHomeScreen(
                        initialIndex: 2,
                      ),
                    ),
                  );
                } else if (widget.returnToAgentMessagesOnBack) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const AgentHomeScreen(
                        initialIndex: 2,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: _buildHeaderContactRow(
                context,
                textTheme,
                contactName: contactName,
                contactSubtitle: contactSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header contact row: tappable to open Agent profile only when contact is
  /// an agent. Landlords do not have profiles — tap does nothing.
  Widget _buildHeaderContactRow(
    BuildContext context,
    TextTheme textTheme, {
    required String contactName,
    required String contactSubtitle,
  }) {
    final isLandlord = contactSubtitle.startsWith('Landlord of ');
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
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    if (isLandlord) {
      return row;
    }
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => AgentProfileScreen(
              agentName: contactName,
              agentFullName: contactName,
              agentId: contactSubtitle,
            ),
          ),
        );
      },
      child: row,
    );
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
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF1A2E35),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This chat is end-end encrypted',
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF1A2E35),
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context, TextTheme textTheme) {
    final isFromOther = widget.listingFromOtherParty;
    return Align(
      alignment: isFromOther ? Alignment.centerLeft : Alignment.centerRight,
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
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                  ),
                ),
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
                              _normalizePriceForDisplay(widget.price),
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

  void _onListingCardTap(BuildContext context) {
    // Open listing detail with the correct view for the current user's role:
    // Landlord = Request Edit only; Agent = Decline, Accept, Chat Landlord; Expat = Get a Ride, Explore, Inquire.
    final role = widget.listingDetailRole;
    final showRequestEditOnly = role == kRoleLandlord;
    final showAgentActions = role == kRoleAgent;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailScreen(
          title: widget.listingTitle,
          location: widget.location,
          price: _normalizePriceForDisplay(widget.price),
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
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
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
                          color: _liveTranslateEnabled
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
                              alignment: _liveTranslateEnabled
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
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
              const SizedBox(width: 8),
              // Plus icon button (e.g. for uploads)
              InkWell(
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.white),
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

