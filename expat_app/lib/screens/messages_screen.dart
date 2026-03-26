import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:expat_app/models/conversation.dart';
import 'package:expat_app/models/chat_message.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/conversations_service.dart'
    show ConversationsService, kChatAttachmentMaxBytes;
import 'package:expat_app/utils/calendar_thread_labels.dart';
import 'package:expat_app/utils/read_platform_file_bytes.dart';
import 'package:expat_app/utils/listing_price_display.dart';
import 'package:expat_app/widgets/user_profile_avatar.dart';
import 'package:expat_app/app_route_names.dart';
import 'agent_home_screen.dart';
import 'landlord_home_screen.dart';
import 'peer_profile_screen.dart';

const String kRoleLandlord = 'landlord';
const String kRoleAgent = 'agent';
const String kRoleExpat = 'expat';

/// Android: used with [FileType.custom] because [FileType.any] is unreliable on API 33+.
const List<String> kChatPickFileExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp',
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods',
  'txt', 'csv', 'rtf', 'md',
  'zip', 'rar', '7z', 'gz',
  'mp3', 'wav', 'm4a', 'aac', 'flac',
  'mp4', 'mov', 'avi', 'mkv', 'webm',
  'json', 'xml', 'html', 'htm',
];

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
    final hadShadow = _scrollOffset > 0;
    final hasShadow = offset > 0;
    if (hadShadow != hasShadow) {
      setState(() => _scrollOffset = offset);
    } else if (_scrollOffset != offset) {
      _scrollOffset = offset;
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
    final contactUid = convo.otherUid(myUid);
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
                  listingId: convo.listingId,
                  listingTitle: convo.listingTitle,
                  location: convo.listingLocation,
                  price: formatConversationListingPrice(convo.listingPrice),
                  imagePath: convo.listingImage,
                  contactName: contactName,
                  contactUid: contactUid,
                  listingDetailRole: widget.currentUserRole,
                ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            contactUid != null
                ? UserProfileAvatar(uid: contactUid, radius: 20)
                : CircleAvatar(
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

/// Interleaves each new calendar day (as [DateTime] midnight local) with [ChatMessage]s.
List<Object> _threadSlotsFromMessages(List<ChatMessage> messages) {
  final slots = <Object>[];
  DateTime? lastDay;
  for (final m in messages) {
    final created = m.createdAt ?? DateTime.now();
    final day = dateOnlyLocal(created);
    if (lastDay == null || !isSameCalendarDay(day, lastDay)) {
      slots.add(day);
      lastDay = day;
    }
    slots.add(m);
  }
  return slots;
}

/// Insert after the first day divider when the thread uses conversation metadata
/// for the property card (e.g. expat inquiry) rather than a listing message payload.
class _LegacyListingCardMarker {
  const _LegacyListingCardMarker();
}

const _legacyListingCardMarker = _LegacyListingCardMarker();

// ---------------------------------------------------------------------------
// ConversationScreen — real-time Firestore chat
// ---------------------------------------------------------------------------

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.listingId,
    required this.listingTitle,
    required this.location,
    required this.price,
    required this.imagePath,
    this.contactName = 'Contact',
    this.contactUid,
    this.returnToLandlordOnBack = false,
    this.returnToAgentMessagesOnBack = false,
    String? listingDetailRole,
  }) : listingDetailRole = listingDetailRole ?? kRoleExpat;

  final String conversationId;
  /// Firestore listing document id; used to open full [ListingDetailScreenById] from the mini card.
  final String listingId;
  final String listingTitle;
  final String location;
  final String price;
  final String imagePath;
  final String contactName;
  /// Firebase UID of the other participant (for profile photo).
  final String? contactUid;
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
  int _lastMessageCount = 0;
  bool _uploadingAttachment = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _myUid = AuthService().currentUser?.uid;
    _messagesStream = ConversationsService().messagesStream(
      widget.conversationId,
    );
    _authSub = AuthService().authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _myUid = user?.uid);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
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

  /// Android 13/14: [FileType.any] often fails; we split media vs typed extensions.
  Future<String?> _promptAndroidAttachmentSource() {
    final textTheme = Theme.of(context).textTheme;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Attach',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Photos & videos'),
                  subtitle: const Text('Screenshots, gallery, clips'),
                  onTap: () => Navigator.pop(ctx, 'media'),
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: const Text('Files'),
                  subtitle: const Text('PDFs, documents, archives, etc.'),
                  onTap: () => Navigator.pop(ctx, 'file'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAttachFile() async {
    if (_uploadingAttachment) return;
    if (_myUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in to attach files.'),
        ),
      );
      return;
    }

    FilePickerResult? pick;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final source = await _promptAndroidAttachmentSource();
        if (source == null) return;
        if (source == 'media') {
          pick = await FilePicker.platform.pickFiles(
            type: FileType.media,
            allowMultiple: false,
            withData: true,
          );
        } else {
          pick = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: kChatPickFileExtensions,
            allowMultiple: false,
            withData: true,
          );
        }
      } else {
        pick = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      }
    } on PlatformException catch (e, st) {
      debugPrint('FilePicker failed: $e\n$st');
      if (!mounted) return;
      final detail =
          (e.message != null && e.message!.isNotEmpty)
              ? e.message!
              : (e.code.isNotEmpty ? e.code : e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail)),
      );
      return;
    } catch (e, st) {
      debugPrint('FilePicker failed: $e\n$st');
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.length > 180 ? '${msg.substring(0, 180)}…' : msg,
          ),
        ),
      );
      return;
    }

    if (pick == null || pick.files.isEmpty) return;

    final f = pick.files.single;
    if (f.size > 0 && f.size > kChatAttachmentMaxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File too large (max ${kChatAttachmentMaxBytes ~/ (1024 * 1024)} MB).',
          ),
        ),
      );
      return;
    }

    final bytes = await readPlatformFileBytes(f);
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that file. Try again or pick another.'),
        ),
      );
      return;
    }

    if (bytes.length > kChatAttachmentMaxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File too large (max ${kChatAttachmentMaxBytes ~/ (1024 * 1024)} MB).',
          ),
        ),
      );
      return;
    }

    setState(() => _uploadingAttachment = true);
    try {
      final caption = _messageController.text.trim();
      await ConversationsService().uploadAndSendChatAttachment(
        conversationId: widget.conversationId,
        senderId: _myUid!,
        fileBytes: bytes,
        fileName: f.name,
        caption: caption,
      );
      if (mounted) _messageController.clear();
    } catch (e, st) {
      debugPrint('Chat attachment upload failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError ? e.message : 'Could not send attachment.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
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

  bool _needsLegacyListingCard(List<ChatMessage> messages) {
    if (widget.listingId.trim().isEmpty) return false;
    if (messages.isEmpty) return false;
    return !messages.any((m) => m.isListingCardMessage);
  }

  List<Object> _conversationDisplaySlots(List<ChatMessage> messages) {
    final slots = _threadSlotsFromMessages(messages);
    if (!_needsLegacyListingCard(messages)) return slots;

    final out = <Object>[];
    var inserted = false;
    for (var i = 0; i < slots.length; i++) {
      out.add(slots[i]);
      if (!inserted && slots[i] is DateTime) {
        final next = i + 1 < slots.length ? slots[i + 1] : null;
        if (next is ChatMessage) {
          out.add(_legacyListingCardMarker);
          inserted = true;
        }
      }
    }
    return out;
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
                if (messages.length > _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scrollToBottom();
                }
                const headerCount = 2;
                final slots = _conversationDisplaySlots(messages);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  itemCount: headerCount + slots.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildEncryptionBanner(textTheme);
                    }
                    if (index == 1) return const SizedBox(height: 8);

                    final slot = slots[index - headerCount];
                    if (slot is DateTime) {
                      return _buildThreadDayDivider(textTheme, slot);
                    }
                    if (slot is _LegacyListingCardMarker) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildLegacyStaticListingCard(context, textTheme),
                      );
                    }
                    final m = slot as ChatMessage;
                    if (m.isListingCardMessage) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildListingCardFromMessage(context, textTheme, m),
                      );
                    }
                    final isMe = m.senderId == _myUid;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child:
                          isMe
                              ? _buildOutgoingBubble(textTheme, m)
                              : _buildIncomingBubble(textTheme, m),
                    );
                  },
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
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    widget.contactUid == null
                        ? null
                        : () {
                          // Contact profile (peer) for the other participant.
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => PeerProfileScreen(
                                uid: widget.contactUid!,
                              ),
                            ),
                          );
                        },
                child: _buildHeaderContactRow(context, textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContactRow(BuildContext context, TextTheme textTheme) {
    final row = Row(
      children: [
        widget.contactUid != null
            ? UserProfileAvatar(uid: widget.contactUid!, radius: 18)
            : CircleAvatar(
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
              _buildHeaderSubtitleLine(textTheme),
            ],
          ),
        ),
      ],
    );
    return row;
  }

  /// Landlord → agent: show agent's institution ID. Agent → landlord: listing title.
  /// Expat flow: "Agent of [property]".
  Widget _buildHeaderSubtitleLine(TextTheme textTheme) {
    final style = textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.8),
    );
    final role = widget.listingDetailRole;

    if (role == kRoleAgent) {
      return Text(
        widget.listingTitle,
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (role == kRoleExpat) {
      return Text(
        'Agent of ${widget.listingTitle}',
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Landlord messaging assigned agent: subtitle is agent ID from profile.
    final uid = widget.contactUid;
    if (uid == null) {
      return Text('—', style: style, overflow: TextOverflow.ellipsis);
    }

    return StreamBuilder<UserProfile?>(
      stream: AuthService().userProfileStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Text('…', style: style, overflow: TextOverflow.ellipsis);
        }
        final agentId = snap.data?.agentId;
        final line =
            (agentId != null && agentId.isNotEmpty) ? agentId : '—';
        return Text(line, style: style, overflow: TextOverflow.ellipsis);
      },
    );
  }

  Widget _buildEncryptionBanner(TextTheme textTheme) {
    return Center(
      child: Text(
        'This chat is end-end encrypted',
        style: textTheme.bodySmall?.copyWith(color: const Color(0xFF1A2E35)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildThreadDayDivider(TextTheme textTheme, DateTime day) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Center(
        child: Text(
          threadDayDividerLabel(day, now),
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF1A2E35),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyStaticListingCard(BuildContext context, TextTheme textTheme) {
    final alignOutgoing = widget.listingDetailRole != kRoleAgent;
    return _buildListingCardLayout(
      context,
      textTheme,
      listingId: widget.listingId.trim(),
      title: widget.listingTitle,
      imagePath: widget.imagePath,
      priceRaw: widget.price,
      location: widget.location,
      alignOutgoing: alignOutgoing,
    );
  }

  Widget _buildListingCardFromMessage(
    BuildContext context,
    TextTheme textTheme,
    ChatMessage m,
  ) {
    final isMe = m.senderId == _myUid;
    final id = (m.payload[ChatMessage.kPayloadListingId] as String?)?.trim() ?? '';
    final title = m.payload[ChatMessage.kPayloadListingTitle] as String? ?? '';
    final imagePath =
        m.payload[ChatMessage.kPayloadListingImage] as String? ?? '';
    final priceRaw =
        m.payload[ChatMessage.kPayloadListingPrice] as String? ?? '';
    final location =
        m.payload[ChatMessage.kPayloadListingLocation] as String? ?? '';
    return _buildListingCardLayout(
      context,
      textTheme,
      listingId: id,
      title: title,
      imagePath: imagePath,
      priceRaw: priceRaw,
      location: location,
      alignOutgoing: isMe,
    );
  }

  Widget _buildListingCardLayout(
    BuildContext context,
    TextTheme textTheme, {
    required String listingId,
    required String title,
    required String imagePath,
    required String priceRaw,
    required String location,
    required bool alignOutgoing,
  }) {
    void onTap() => _onListingCardTapWithId(context, listingId);
    return Align(
      alignment: alignOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: InkWell(
          onTap: onTap,
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
                      title,
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
                  child: _buildListingCardImage(imagePath),
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
                              formatConversationListingPrice(priceRaw),
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onTap,
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

  Widget _buildListingCardImage(String path) {
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

  void _onListingCardTapWithId(BuildContext context, String listingId) {
    final id = listingId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing details are unavailable for this thread.'),
        ),
      );
      return;
    }

    final role = widget.listingDetailRole;
    Navigator.of(context).pushNamed(
      AppRouteNames.listingDetailFromChat,
      arguments: <String, dynamic>{
        'listingId': id,
        'showRequestEditOnly': role == kRoleLandlord,
        'showAgentActions': role == kRoleAgent,
      },
    );
  }

  Widget _buildOutgoingBubble(TextTheme textTheme, ChatMessage m) {
    return _buildMessageBubble(textTheme, m, isOutgoing: true);
  }

  Widget _buildIncomingBubble(TextTheme textTheme, ChatMessage m) {
    return _buildMessageBubble(textTheme, m, isOutgoing: false);
  }

  Widget _buildMessageBubble(
    TextTheme textTheme,
    ChatMessage m, {
    required bool isOutgoing,
  }) {
    final url = m.payload[ChatMessage.kPayloadAttachmentUrl] as String?;
    final attachmentName =
        m.payload[ChatMessage.kPayloadAttachmentName] as String? ??
            'Attachment';
    final kind =
        m.payload[ChatMessage.kPayloadAttachmentKind] as String? ??
            ChatMessage.kAttachmentKindFile;
    final text = m.content.trim();
    final hasAttachment = url != null && url.isNotEmpty;

    final bubbleBg =
        isOutgoing ? const Color(0xFF1A2E35) : const Color(0xFF8ED966);
    final fg = isOutgoing ? Colors.white : const Color(0xFF1A2E35);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAttachment)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: _buildAttachmentBlock(
                  textTheme,
                  url: url,
                  displayName: attachmentName,
                  isImage: kind == ChatMessage.kAttachmentKindImage,
                  isOutgoing: isOutgoing,
                ),
              ),
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  hasAttachment ? 6 : 10,
                  16,
                  10,
                ),
                child: Text(
                  text,
                  style: textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachmentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open this link.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildAttachmentBlock(
    TextTheme textTheme, {
    required String url,
    required String displayName,
    required bool isImage,
    required bool isOutgoing,
  }) {
    final fg = isOutgoing ? Colors.white : const Color(0xFF1A2E35);
    final muted =
        isOutgoing
            ? Colors.white.withValues(alpha: 0.72)
            : const Color(0xFF1A2E35).withValues(alpha: 0.65);

    Future<void> onOpen() => _openAttachmentUrl(url);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.15),
          child: InkWell(
            onTap: onOpen,
            child: Image.network(
              url,
              width: 264,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 264,
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: isOutgoing ? Colors.white70 : const Color(0xFF1A2E35),
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.broken_image_outlined, color: fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: textTheme.bodySmall?.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color:
          isOutgoing
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file_rounded, color: fg, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: muted),
            ],
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
              IconButton(
                onPressed:
                    (_uploadingAttachment || _myUid == null)
                        ? null
                        : _onAttachFile,
                icon:
                    _uploadingAttachment
                        ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8ED966),
                          ),
                        )
                        : Icon(
                          Icons.add,
                          color:
                              _myUid == null
                                  ? hintColor.withValues(alpha: 0.45)
                                  : const Color(0xFF8ED966),
                          size: 28,
                        ),
                tooltip:
                    _myUid == null
                        ? 'Sign in to attach files'
                        : 'Attach file',
              ),
              const SizedBox(width: 4),
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
