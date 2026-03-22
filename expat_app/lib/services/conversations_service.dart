import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/conversation.dart';
import '../models/chat_message.dart';

/// Manages Firestore conversations and messages.
class ConversationsService {
  ConversationsService._();
  static final ConversationsService _instance = ConversationsService._();
  factory ConversationsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('messages');

  /// Returns an existing conversation between [participantIds] for [listingId],
  /// or creates a new one with the supplied listing metadata and participant names.
  Future<Conversation> getOrCreateConversation({
    required String listingId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required String listingTitle,
    String listingImage = '',
    String listingPrice = '',
    String listingLocation = '',
  }) async {
    final sorted = List<String>.from(participantIds)..sort();

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
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    Map<String, dynamic> payload = const {},
  }) async {
    final msg = ChatMessage(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      payload: payload,
    );

    final docRef = await _messagesRef.add(msg.toFirestore());

    await _conversationsRef.doc(conversationId).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    final created = await docRef.get();
    return ChatMessage.fromFirestore(created);
  }
}
