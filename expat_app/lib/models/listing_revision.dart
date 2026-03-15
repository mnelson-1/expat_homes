import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a listing revision (BACKEND_CHECKLIST §1.3).
enum RevisionStatus {
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected');

  const RevisionStatus(this.value);
  final String value;

  static RevisionStatus fromString(String? v) {
    if (v == null) return RevisionStatus.pendingReview;
    return RevisionStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => RevisionStatus.pendingReview,
    );
  }
}

/// Landlord's proposed changes after edit request is approved.
/// On Super Admin approve → fields are applied to the listing.
class ListingRevision {
  ListingRevision({
    required this.id,
    required this.editRequestId,
    required this.listingId,
    required this.landlordId,
    required this.status,
    required this.proposedFields,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  final String id;
  final String editRequestId;
  final String listingId;
  final String landlordId;
  final RevisionStatus status;
  /// Snapshot of the fields the landlord wants to change.
  final Map<String, dynamic> proposedFields;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  factory ListingRevision.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Revision ${doc.id} has no data');
    return ListingRevision(
      id: doc.id,
      editRequestId: data['editRequestId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      landlordId: data['landlordId'] as String? ?? '',
      status: RevisionStatus.fromString(data['status'] as String?),
      proposedFields:
          Map<String, dynamic>.from(data['proposedFields'] as Map? ?? {}),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'editRequestId': editRequestId,
        'listingId': listingId,
        'landlordId': landlordId,
        'status': status.value,
        'proposedFields': proposedFields,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
