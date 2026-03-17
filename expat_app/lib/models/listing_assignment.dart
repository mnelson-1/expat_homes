import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  const AssignmentStatus(this.value);
  final String value;

  static AssignmentStatus fromString(String? v) {
    if (v == null) return AssignmentStatus.pending;
    return AssignmentStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => AssignmentStatus.pending,
    );
  }
}

/// Links an agent to a listing. One active assignment per listing.
/// When the agent accepts, the listing's representative switches to the agent.
class ListingAssignment {
  ListingAssignment({
    required this.id,
    required this.listingId,
    required this.agentId,
    required this.landlordId,
    required this.status,
    this.agentUid,
    this.agentName,
    this.listingTitle,
    this.assignedAt,
  });

  final String id;
  final String listingId;
  /// The institution-issued agent ID (e.g. KM-201903), same as LicensedAgent.agentId.
  final String agentId;
  final String landlordId;
  final AssignmentStatus status;
  /// The agent's Firebase Auth UID (for Firestore rules matching).
  final String? agentUid;
  /// Denormalized for display convenience.
  final String? agentName;
  final String? listingTitle;
  final DateTime? assignedAt;

  factory ListingAssignment.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) throw StateError('Assignment ${doc.id} has no data');
    return ListingAssignment(
      id: doc.id,
      listingId: d['listingId'] as String? ?? '',
      agentId: d['agentId'] as String? ?? '',
      landlordId: d['landlordId'] as String? ?? '',
      status: AssignmentStatus.fromString(d['status'] as String?),
      agentUid: d['agentUid'] as String?,
      agentName: d['agentName'] as String?,
      listingTitle: d['listingTitle'] as String?,
      assignedAt: (d['assignedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'agentId': agentId,
        'landlordId': landlordId,
        'status': status.value,
        if (agentUid != null) 'agentUid': agentUid,
        if (agentName != null) 'agentName': agentName,
        if (listingTitle != null) 'listingTitle': listingTitle,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['assignedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
