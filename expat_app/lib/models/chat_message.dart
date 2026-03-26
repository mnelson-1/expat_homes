import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message within a conversation.
/// Stored in the Firestore `messages` collection.
class ChatMessage {
  /// [payload] keys for a file or image shared in chat.
  static const String kPayloadAttachmentUrl = 'attachmentUrl';
  static const String kPayloadAttachmentName = 'attachmentName';
  static const String kPayloadAttachmentMime = 'attachmentMime';
  static const String kPayloadAttachmentKind = 'attachmentKind';

  /// Values for [kPayloadAttachmentKind].
  static const String kAttachmentKindImage = 'image';
  static const String kAttachmentKindFile = 'file';

  /// Listing mini-card (landlord assignment flow, etc.) — same [createdAt] as adjacent text.
  static const String kPayloadListingId = 'listingId';
  static const String kPayloadListingTitle = 'listingTitle';
  static const String kPayloadListingImage = 'listingImage';
  static const String kPayloadListingPrice = 'listingPrice';
  static const String kPayloadListingLocation = 'listingLocation';

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.payload = const {},
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;

  /// Optional structured payload (e.g. listing card data attached to
  /// the first message in a thread).
  final Map<String, dynamic> payload;

  final DateTime? createdAt;

  /// True when this message should render as a property mini-card in the thread.
  bool get isListingCardMessage {
    final id = payload[kPayloadListingId] as String?;
    return id != null && id.trim().isNotEmpty;
  }

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('ChatMessage document ${doc.id} has no data');
    }
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      payload: Map<String, dynamic>.from(data['payload'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'payload': payload,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
