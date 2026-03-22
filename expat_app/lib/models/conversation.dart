import 'package:cloud_firestore/cloud_firestore.dart';

/// A conversation thread between two participants about a listing.
/// Stored in the Firestore `conversations` collection.
class Conversation {
  Conversation({
    required this.id,
    required this.listingId,
    required this.participantIds,
    this.participantNames = const {},
    this.lastMessage,
    this.lastMessageAt,
    this.listingTitle = '',
    this.listingImage = '',
    this.listingPrice = '',
    this.listingLocation = '',
    this.createdAt,
  });

  final String id;
  final String listingId;

  /// Firebase UIDs of both participants.
  final List<String> participantIds;

  /// uid → display name map, denormalized for fast thread rendering.
  final Map<String, String> participantNames;

  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// Denormalized listing metadata for the thread list and conversation card.
  final String listingTitle;
  final String listingImage;
  final String listingPrice;
  final String listingLocation;

  final DateTime? createdAt;

  /// Returns the other participant's display name given the current user's UID.
  String contactName(String myUid) {
    for (final entry in participantNames.entries) {
      if (entry.key != myUid) return entry.value;
    }
    return 'Unknown';
  }

  /// Returns the other participant's UID.
  String? otherUid(String myUid) {
    for (final uid in participantIds) {
      if (uid != myUid) return uid;
    }
    return null;
  }

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Conversation document ${doc.id} has no data');
    }
    final ids = (data['participantIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final names = (data['participantNames'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
        {};

    return Conversation(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      participantIds: ids,
      participantNames: names,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      listingTitle: data['listingTitle'] as String? ?? '',
      listingImage: data['listingImage'] as String? ?? '',
      listingPrice: data['listingPrice'] as String? ?? '',
      listingLocation: data['listingLocation'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : FieldValue.serverTimestamp(),
        'listingTitle': listingTitle,
        'listingImage': listingImage,
        'listingPrice': listingPrice,
        'listingLocation': listingLocation,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
