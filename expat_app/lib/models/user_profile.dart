import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles as defined in BACKEND_CHECKLIST (users table).
enum UserRole {
  expat('expat'),
  landlord('landlord'),
  agent('agent'),
  superAdmin('super_admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? v) {
    if (v == null) return UserRole.expat;
    return UserRole.values.firstWhere(
      (r) => r.value == v,
      orElse: () => UserRole.expat,
    );
  }
}

/// User profile stored in Firestore `users` collection.
/// Mirrors BACKEND_CHECKLIST §1.1: id, email, role, email_verified_at,
/// preferred_language, created_at, updated_at; role-specific fields.
class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.emailVerifiedAt,
    this.preferredLanguage = 'English',
    this.createdAt,
    this.updatedAt,
    // Expat
    this.legalFirstName,
    this.legalLastName,
    this.dateOfBirth,
    this.countryOfCitizenship,
    this.demographic,
    // Agent (links to licensed_agents)
    this.agentId,
  });

  final String id;
  final String email;
  final UserRole role;
  final DateTime? emailVerifiedAt;
  final String preferredLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Expat: first name on ID
  final String? legalFirstName;
  /// Expat: last name on ID
  final String? legalLastName;
  final DateTime? dateOfBirth;
  final String? countryOfCitizenship;
  /// "What best describes you" (onboarding)
  final String? demographic;

  /// Agent: institution-issued ID (e.g. RWAREB); links to licensed_agents
  final String? agentId;

  String get legalName {
    if (legalFirstName != null || legalLastName != null) {
      return [legalFirstName, legalLastName].whereType<String>().join(' ').trim();
    }
    return email;
  }

  /// Create from Firestore document snapshot
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User document ${doc.id} has no data');
    }
    return UserProfile(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      emailVerifiedAt: (data['emailVerifiedAt'] as Timestamp?)?.toDate(),
      preferredLanguage: data['preferredLanguage'] as String? ?? 'English',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      legalFirstName: data['legalFirstName'] as String?,
      legalLastName: data['legalLastName'] as String?,
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      countryOfCitizenship: data['countryOfCitizenship'] as String?,
      demographic: data['demographic'] as String?,
      agentId: data['agentId'] as String?,
    );
  }

  /// Map for Firestore set/update (no id; id is document id)
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'email': email,
      'role': role.value,
      'preferredLanguage': preferredLanguage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (emailVerifiedAt != null) {
      map['emailVerifiedAt'] = Timestamp.fromDate(emailVerifiedAt!);
    }
    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }
    if (legalFirstName != null) map['legalFirstName'] = legalFirstName;
    if (legalLastName != null) map['legalLastName'] = legalLastName;
    if (dateOfBirth != null) {
      map['dateOfBirth'] = Timestamp.fromDate(dateOfBirth!);
    }
    if (countryOfCitizenship != null) {
      map['countryOfCitizenship'] = countryOfCitizenship;
    }
    if (demographic != null) map['demographic'] = demographic;
    if (agentId != null) map['agentId'] = agentId;
    return map;
  }

  /// For initial user creation (includes createdAt)
  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
