import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a landlord's request to edit a listing (BACKEND_CHECKLIST §1.3).
enum EditRequestStatus {
  pending('pending'),
  approved('approved'),
  declined('declined');

  const EditRequestStatus(this.value);
  final String value;

  static EditRequestStatus fromString(String? v) {
    if (v == null) return EditRequestStatus.pending;
    return EditRequestStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => EditRequestStatus.pending,
    );
  }
}

/// Landlord request to edit a listing; Super Admin approves or declines.
class ListingEditRequest {
  ListingEditRequest({
    required this.id,
    required this.listingId,
    required this.landlordId,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.reason,
  });

  final String id;
  final String listingId;
  final String landlordId;
  final EditRequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final String? reason;

  factory ListingEditRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Edit request ${doc.id} has no data');
    return ListingEditRequest(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      landlordId: data['landlordId'] as String? ?? '',
      status: EditRequestStatus.fromString(data['status'] as String?),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'landlordId': landlordId,
        'status': status.value,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
        if (reason != null) 'reason': reason,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
