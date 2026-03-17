import 'package:cloud_firestore/cloud_firestore.dart';

/// A licensed agent from the RWAREB registry. Stored in the
/// `licensed_agents` Firestore collection and used for ID validation
/// at sign-up and for populating the landlord "Find Agent" list.
class LicensedAgent {
  LicensedAgent({
    required this.agentId,
    required this.firstName,
    required this.lastName,
    required this.region,
    this.bio,
    this.phone,
    this.profileImageUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.registeredUid,
    this.createdAt,
  });

  /// Institution-issued ID (e.g. KM-201903). Also the Firestore document ID.
  final String agentId;
  final String firstName;
  final String lastName;
  final String region;
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final double rating;
  final int ratingCount;
  /// Firebase Auth UID of the agent user who registered with this ID.
  final String? registeredUid;
  final DateTime? createdAt;

  String get fullName => '$firstName $lastName';

  factory LicensedAgent.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) throw StateError('Licensed agent ${doc.id} has no data');
    return LicensedAgent(
      agentId: doc.id,
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      region: d['region'] as String? ?? '',
      bio: d['bio'] as String?,
      phone: d['phone'] as String?,
      profileImageUrl: d['profileImageUrl'] as String?,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      registeredUid: d['registeredUid'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'firstName': firstName,
        'lastName': lastName,
        'region': region,
        if (bio != null) 'bio': bio,
        if (phone != null) 'phone': phone,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'rating': rating,
        'ratingCount': ratingCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
