import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/conversation.dart';
import '../models/chat_message.dart';
import 'message_translation_service.dart';
import 'perf_metrics_service.dart';

/// Storage path: `chat_attachments/{senderId}/{conversationId}/{objectName}`.
const String kChatAttachmentsStoragePrefix = 'chat_attachments';

/// Max attachment size for chat uploads (bytes).
const int kChatAttachmentMaxBytes = 25 * 1024 * 1024;

/// Manages Firestore conversations and messages.
class ConversationsService {
  ConversationsService._();
  static final ConversationsService _instance = ConversationsService._();
  factory ConversationsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('messages');

  /// Stable doc id for one thread per landlord↔agent pair (assignments + Chat Landlord).
  static String pairThreadDocumentId(List<String> participantIds) {
    final sorted = List<String>.from(participantIds)..sort();
    if (sorted.length != 2) {
      throw ArgumentError('pairThreadDocumentId expects exactly 2 participants');
    }
    return 'pair_${sorted[0]}_${sorted[1]}';
  }

  /// Returns an existing conversation between [participantIds] for [listingId],
  /// or creates a new one with the supplied listing metadata and participant names.
  ///
  /// When [sharedLandlordAgentThread] is true, the same document is reused for the
  /// two participants regardless of [listingId] (multiple listing assignments share
  /// one chat). Conversation listing fields are refreshed to the latest context.
  /// Use for landlord↔agent only; expat inquiries should leave this false (default).
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required String listingTitle,
    String listingImage = '',
    String listingPrice = '',
    String listingLocation = '',
    bool sharedLandlordAgentThread = false,
  }) async {
    final sorted = List<String>.from(participantIds)..sort();

    if (sharedLandlordAgentThread) {
      if (sorted.length != 2) {
        throw ArgumentError(
          'sharedLandlordAgentThread requires exactly 2 participants',
        );
      }
      final docId = pairThreadDocumentId(sorted);
      final ref = _conversationsRef.doc(docId);
      final existing = await ref.get();
      if (existing.exists) {
        await ref.update({
          'listingId': listingId,
          'listingTitle': listingTitle,
          'listingImage': listingImage,
          'listingPrice': listingPrice,
          'listingLocation': listingLocation,
          'participantNames': participantNames,
        });
        final updated = await ref.get();
        return Conversation.fromFirestore(updated);
      }
      final convo = Conversation(
        id: docId,
        listingId: listingId,
        participantIds: sorted,
        participantNames: participantNames,
        listingTitle: listingTitle,
        listingImage: listingImage,
        listingPrice: listingPrice,
        listingLocation: listingLocation,
      );
      await ref.set(convo.toFirestoreCreate());
      final created = await ref.get();
      return Conversation.fromFirestore(created);
    }

    // Look for an existing conversation with the same participants and listing.
    final snap = await _conversationsRef
        .where('listingId', isEqualTo: listingId)
        .where('participantIds', isEqualTo: sorted)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return Conversation.fromFirestore(snap.docs.first);
    }

    final convo = Conversation(
      id: '',
      listingId: listingId,
      participantIds: sorted,
      participantNames: participantNames,
      listingTitle: listingTitle,
      listingImage: listingImage,
      listingPrice: listingPrice,
      listingLocation: listingLocation,
    );

    final docRef = await _conversationsRef.add(convo.toFirestoreCreate());
    final created = await docRef.get();
    return Conversation.fromFirestore(created);
  }

  /// Real-time stream of all conversations for [userId], newest first.
  Stream<List<Conversation>> conversationsStream(String userId) {
    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Conversation.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Typing heartbeat freshness for [peerTypingStream].
  static const Duration typingFreshness = Duration(seconds: 6);

  CollectionReference<Map<String, dynamic>> _typingCol(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('typing');

  /// Emits true while another participant has a recent typing heartbeat.
  Stream<bool> peerTypingStream(String conversationId, String myUid) {
    return _typingCol(conversationId).snapshots().map((snap) {
      final now = DateTime.now();
      for (final doc in snap.docs) {
        if (doc.id == myUid) continue;
        final raw = doc.data()['at'];
        DateTime? at;
        if (raw is Timestamp) at = raw.toDate();
        if (at != null && now.difference(at) <= typingFreshness) {
          return true;
        }
      }
      return false;
    });
  }

  /// Writes or clears the current user's typing indicator for [conversationId].
  Future<void> setTypingState({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    final ref = _typingCol(conversationId).doc(userId);
    if (!isTyping) {
      await ref.delete();
    } else {
      await ref.set({'at': FieldValue.serverTimestamp()});
    }
  }

  /// Real-time stream of messages for a conversation, oldest first.
  /// Client-side sort avoids the need for a Firestore composite index.
  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2100);
        final bTime = b.createdAt ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });
      return list;
    });
  }

  /// Sends a message and updates the conversation's last-message metadata.
  ///
  /// [lastMessagePreview] overrides the text shown in the conversation list
  /// (e.g. `📎 filename` when [content] is empty but an attachment was sent).
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    Map<String, dynamic> payload = const {},
    String? lastMessagePreview,
  }) async {
    final sw = Stopwatch()..start();
    final msg = ChatMessage(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      payload: payload,
    );

    final docRef = await _messagesRef.add(msg.toFirestore());

    final preview =
        (lastMessagePreview != null && lastMessagePreview.isNotEmpty)
            ? lastMessagePreview
            : content;

    final updates = <String, dynamic>{
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (preview.trim().isNotEmpty) {
      final tr =
          await MessageTranslationService.buildLastMessageTranslationsForFirestore(
        preview: preview,
        conversationId: conversationId,
      );
      if (tr.isNotEmpty) {
        updates['lastMessageTranslations'] = tr;
      }
    } else {
      updates['lastMessageTranslations'] = FieldValue.delete();
    }

    await _conversationsRef.doc(conversationId).update(updates);

    final created = await docRef.get();
    sw.stop();
    PerfMetricsService().addSample('send_message', sw.elapsedMilliseconds);
    return ChatMessage.fromFirestore(created);
  }

  /// Measures latency from send call to message visibility in [messagesStream].
  /// Uses the same stream path consumed by the UI.
  Future<int> measureSendToReceiveLatency({
    required String conversationId,
    required String senderId,
    required String content,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sw = Stopwatch()..start();
    final completer = Completer<int>();
    late final StreamSubscription<List<ChatMessage>> sub;
    String? targetId;

    sub = messagesStream(conversationId).listen((messages) {
      if (targetId == null) return;
      final seen = messages.any((m) => m.id == targetId);
      if (seen && !completer.isCompleted) {
        sw.stop();
        completer.complete(sw.elapsedMilliseconds);
      }
    });

    try {
      final created = await sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
      );
      targetId = created.id;
      final ms = await completer.future.timeout(timeout);
      PerfMetricsService().setMessageLatencyMs(ms);
      return ms;
    } finally {
      await sub.cancel();
    }
  }

  /// Uploads [fileBytes] to Storage, then sends a message with attachment metadata in [payload].
  Future<ChatMessage> uploadAndSendChatAttachment({
    required String conversationId,
    required String senderId,
    required Uint8List fileBytes,
    required String fileName,
    String caption = '',
  }) async {
    if (fileBytes.length > kChatAttachmentMaxBytes) {
      throw StateError(
        'File is too large (max ${kChatAttachmentMaxBytes ~/ (1024 * 1024)} MB).',
      );
    }

    final mime = _guessMimeType(fileName);
    final kind =
        mime.startsWith('image/')
            ? ChatMessage.kAttachmentKindImage
            : ChatMessage.kAttachmentKindFile;

    final objectName = _storageObjectName(fileName);
    final storagePath =
        '$kChatAttachmentsStoragePrefix/$senderId/$conversationId/$objectName';

    final ref = _storage.ref(storagePath);
    await ref.putData(
      fileBytes,
      SettableMetadata(contentType: mime),
    );
    final downloadUrl = await ref.getDownloadURL();

    final safeDisplayName = _safeDisplayFileName(fileName);
    final captionTrim = caption.trim();
    final preview =
        captionTrim.isNotEmpty ? captionTrim : '📎 $safeDisplayName';

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: captionTrim,
      lastMessagePreview: preview,
      payload: {
        ChatMessage.kPayloadAttachmentUrl: downloadUrl,
        ChatMessage.kPayloadAttachmentName: safeDisplayName,
        ChatMessage.kPayloadAttachmentMime: mime,
        ChatMessage.kPayloadAttachmentKind: kind,
      },
    );
  }

  static String _safeDisplayFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'attachment';
    final parts = trimmed.split(RegExp(r'[/\\]'));
    return parts.last.isEmpty ? 'attachment' : parts.last;
  }

  static String _storageObjectName(String fileName) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final display = _safeDisplayFileName(fileName);
    final dot = display.lastIndexOf('.');
    String ext = '';
    var base = display;
    if (dot > 0) {
      ext = display.substring(dot);
      base = display.substring(0, dot);
    }
    ext = ext.replaceAll(RegExp(r'[^\w.]'), '');
    final sanitized =
        base.replaceAll(RegExp(r'[/\\]'), '_').replaceAll(' ', '_').trim();
    final short =
        sanitized.length > 80 ? sanitized.substring(0, 80) : sanitized;
    final basePart = short.isEmpty ? 'file' : short;
    return '${ts}_$basePart$ext';
  }

  static String _guessMimeType(String fileName) {
    final ext =
        fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
