import 'package:cloud_firestore/cloud_firestore.dart';

/// Listing status (BACKEND_CHECKLIST §1.2).
enum ListingStatus {
  draft('draft'),
  pendingVerification('pending_verification'),
  published('published'),
  archived('archived');

  const ListingStatus(this.value);
  final String value;

  static ListingStatus fromString(String? v) {
    if (v == null) return ListingStatus.draft;
    return ListingStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => ListingStatus.draft,
    );
  }
}

/// Property type for listings.
enum ListingType {
  apartment('apartment'),
  house('house'),
  shortStay('short_stay');

  const ListingType(this.value);
  final String value;

  static ListingType fromString(String? v) {
    if (v == null) return ListingType.apartment;
    return ListingType.values.firstWhere(
      (t) => t.value == v,
      orElse: () => ListingType.apartment,
    );
  }

  String get displayLabel {
    switch (this) {
      case ListingType.apartment:
        return 'Apartment';
      case ListingType.house:
        return 'House';
      case ListingType.shortStay:
        return 'Short-Stay';
    }
  }
}

/// Property listing stored in Firestore `listings` collection.
/// Mirrors BACKEND_CHECKLIST §1.2; media stored as URLs on document.
class Listing {
  Listing({
    required this.id,
    required this.landlordId,
    this.agentId,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    this.upi,
    this.mediaUrls = const [],
    this.status = ListingStatus.pendingVerification,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.verifiedBy,
    this.representativeName,
    this.representativeRole,
  });

  final String id;
  final String landlordId;
  final String? agentId;
  final ListingType type;
  final String title;
  final String description;
  final String location;
  final String price;
  final String? upi;
  final List<String> mediaUrls;
  final ListingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final String? verifiedBy;
  /// Resolved representative display name (landlord or agent).
  final String? representativeName;
  /// "Landlord" or "Agent".
  final String? representativeRole;

  String get typeLabel => type.displayLabel;

  /// First image URL for cards; fallback to placeholder.
  String? get firstImageUrl =>
      mediaUrls.isNotEmpty ? mediaUrls.first : null;

  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Listing document ${doc.id} has no data');
    }
    final urls = data['mediaUrls'];
    return Listing(
      id: doc.id,
      landlordId: data['landlordId'] as String? ?? '',
      agentId: data['agentId'] as String?,
      type: ListingType.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      price: data['price'] as String? ?? '',
      upi: data['upi'] as String?,
      mediaUrls: urls is List ? urls.map((e) => e.toString()).toList() : [],
      status: ListingStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'] as String?,
      representativeName: data['representativeName'] as String?,
      representativeRole: data['representativeRole'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'landlordId': landlordId,
      'type': type.value,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'mediaUrls': mediaUrls,
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (agentId != null) map['agentId'] = agentId;
    if (upi != null && upi!.isNotEmpty) map['upi'] = upi;
    if (createdAt != null) map['createdAt'] = Timestamp.fromDate(createdAt!);
    if (publishedAt != null) map['publishedAt'] = Timestamp.fromDate(publishedAt!);
    if (verifiedBy != null) map['verifiedBy'] = verifiedBy;
    if (representativeName != null) map['representativeName'] = representativeName;
    if (representativeRole != null) map['representativeRole'] = representativeRole;
    return map;
  }

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
