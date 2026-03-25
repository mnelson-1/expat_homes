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

/// Landlord request to edit a listing. Includes the proposed field changes so
/// the admin can compare and approve/decline in one step.
class ListingEditRequest {
  ListingEditRequest({
    required this.id,
    required this.listingId,
    required this.landlordId,
    required this.status,
    this.proposedFields = const {},
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.reason,
    this.landlordAcknowledgedApprovalAt,
  });

  final String id;
  final String listingId;
  final String landlordId;
  final EditRequestStatus status;
  /// The fields the landlord wants to change (title, price, location, etc.).
  final Map<String, dynamic> proposedFields;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final String? reason;

  /// When set, the landlord has dismissed the “Edit Request Approved” banner.
  final DateTime? landlordAcknowledgedApprovalAt;

  /// Green approved banner until the landlord taps to acknowledge (then [Request Edit] returns).
  bool get showsLandlordApprovedBanner =>
      status == EditRequestStatus.approved &&
      landlordAcknowledgedApprovalAt == null;

  factory ListingEditRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Edit request ${doc.id} has no data');
    return ListingEditRequest(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      landlordId: data['landlordId'] as String? ?? '',
      status: EditRequestStatus.fromString(data['status'] as String?),
      proposedFields:
          Map<String, dynamic>.from(data['proposedFields'] as Map? ?? {}),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] as String?,
      landlordAcknowledgedApprovalAt:
          (data['landlordAcknowledgedApprovalAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'landlordId': landlordId,
        'status': status.value,
        'proposedFields': proposedFields,
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
