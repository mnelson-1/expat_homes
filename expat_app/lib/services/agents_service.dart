import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/licensed_agent.dart';
import '../models/listing_assignment.dart';

const String kLicensedAgentsCollection = 'licensed_agents';
const String _kUsersCollection = 'users';

String _licensedAgentDocId(String agentId) => agentId.trim().toUpperCase();
const String kAssignmentsCollection = 'listing_assignments';

/// Seed data for the licensed_agents collection. Called once to populate
/// Firestore with demo agents for development/testing.
final List<Map<String, dynamic>> _seedData = [
  {
    'agentId': 'KM-201903',
    'firstName': 'Jean',
    'lastName': 'Claude',
    'region': 'Kimironko',
    'bio': 'Experienced property agent in Kimironko. Fluent in English and French.',
    'phone': '+250 788 123 456',
    'rating': 4.5,
    'ratingCount': 18,
  },
  {
    'agentId': 'KM-202005',
    'firstName': 'Eric',
    'lastName': 'Niyonsenga',
    'region': 'Kimironko',
    'bio': 'Property specialist covering Kimironko and Kibagabaga areas.',
    'phone': '+250 788 234 567',
    'rating': 4.2,
    'ratingCount': 12,
  },
  {
    'agentId': 'KM-201940',
    'firstName': 'Jean',
    'lastName': 'Claude Habimana',
    'region': 'Kimironko',
    'bio': 'Real estate broker with 5 years of experience in Kigali.',
    'phone': '+250 788 345 678',
    'rating': 4.0,
    'ratingCount': 7,
  },
  {
    'agentId': 'RM-204112',
    'firstName': 'Aline',
    'lastName': 'Uwase',
    'region': 'Remera',
    'bio': 'Dedicated agent in Remera. Helping families find their perfect home.',
    'phone': '+250 788 456 789',
    'rating': 4.7,
    'ratingCount': 24,
  },
  {
    'agentId': 'KG-198745',
    'firstName': 'Eric',
    'lastName': 'Niyonzima',
    'region': 'Kacyiru',
    'bio': 'Kacyiru area specialist with deep knowledge of premium properties.',
    'phone': '+250 788 567 890',
    'rating': 4.3,
    'ratingCount': 9,
  },
  {
    'agentId': 'KG-205678',
    'firstName': 'Linda',
    'lastName': 'Mukamana',
    'region': 'Kisimenti',
    'bio': 'Top-rated agent in Kisimenti. Languages: English and French.',
    'phone': '+250 788 678 901',
    'rating': 4.9,
    'ratingCount': 31,
  },
];

/// Handles Firestore operations for licensed agents and listing assignments.
class AgentsService {
  AgentsService._();
  static final AgentsService _instance = AgentsService._();
  factory AgentsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _agentsRef =>
      _firestore.collection(kLicensedAgentsCollection);

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection(kAssignmentsCollection);

  // ---------------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------------

  /// Populate the `licensed_agents` collection with demo data.
  /// Skips documents that already exist.
  Future<void> seedLicensedAgents() async {
    for (final agent in _seedData) {
      final id = agent['agentId'] as String;
      final docRef = _agentsRef.doc(id);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          ...agent,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Agent ID validation (sign-up)
  // ---------------------------------------------------------------------------

  /// Validate an agent ID against the licensed_agents collection.
  /// Returns the [LicensedAgent] if found, null otherwise.
  Future<LicensedAgent?> validateAgentId(String agentId) async {
    final doc = await _agentsRef.doc(_licensedAgentDocId(agentId)).get();
    if (!doc.exists) return null;
    return LicensedAgent.fromFirestore(doc);
  }

  /// True when [registeredUid] points at a real agent profile that matches [agentId].
  Future<bool> _isRegisteredAgentLinkOk(
    String agentId,
    String registeredUid,
  ) async {
    final userDoc =
        await _firestore.collection(_kUsersCollection).doc(registeredUid).get();
    if (!userDoc.exists) return false;
    final data = userDoc.data();
    if (data == null) return false;
    if ((data['role'] as String?) != 'agent') return false;
    final userAgentId = data['agentId'] as String?;
    if (userAgentId == null ||
        userAgentId.trim().toUpperCase() != _licensedAgentDocId(agentId)) {
      return false;
    }
    return true;
  }

  Future<List<LicensedAgent>> _filterToVerifiedRegisteredAgents(
    List<LicensedAgent> agents,
  ) async {
    final withUid = agents
        .where((a) => a.registeredUid != null && a.registeredUid!.isNotEmpty)
        .toList();
    if (withUid.isEmpty) return [];

    final uids = withUid.map((a) => a.registeredUid!).toSet().toList();
    final userSnaps = await Future.wait(
      uids.map((uid) => _firestore.collection(_kUsersCollection).doc(uid).get()),
    );
    final uidToData = <String, Map<String, dynamic>>{};
    for (var i = 0; i < uids.length; i++) {
      final doc = userSnaps[i];
      final data = doc.data();
      if (doc.exists && data != null) {
        uidToData[uids[i]] = data;
      }
    }

    return withUid.where((a) {
      final uid = a.registeredUid!;
      final data = uidToData[uid];
      if (data == null) return false;
      if ((data['role'] as String?) != 'agent') return false;
      final userAgentId = data['agentId'] as String?;
      return userAgentId != null &&
          userAgentId.trim().toUpperCase() == _licensedAgentDocId(a.agentId);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // List agents (landlord "Find Agent")
  // ---------------------------------------------------------------------------

  /// Stream licensed agents for the Landlord "Find Agent" flow.
  ///
  /// Defaults to `registeredOnly: true` so landlords can only assign/search
  /// agents who have actually completed app registration (i.e. have
  /// `registeredUid` set).
  Stream<List<LicensedAgent>> agentsStream({
    String? region,
    bool registeredOnly = true,
  }) {
    Query<Map<String, dynamic>> q = _agentsRef;
    if (region != null && region.isNotEmpty) {
      q = q.where('region', isEqualTo: region);
    }
    return q.snapshots().asyncMap((snap) async {
      var list = snap.docs.map((d) => LicensedAgent.fromFirestore(d)).toList();
      if (registeredOnly) {
        list = await _filterToVerifiedRegisteredAgents(list);
      }
      return list;
    });
  }

  /// One-time fetch of all licensed agents.
  Future<List<LicensedAgent>> getAgents({
    String? region,
    bool registeredOnly = true,
  }) async {
    Query<Map<String, dynamic>> q = _agentsRef;
    if (region != null && region.isNotEmpty) {
      q = q.where('region', isEqualTo: region);
    }
    final snap = await q.get();
    var list = snap.docs.map((d) => LicensedAgent.fromFirestore(d)).toList();
    if (registeredOnly) {
      list = await _filterToVerifiedRegisteredAgents(list);
    }
    return list;
  }

  /// Get a single licensed agent by ID.
  Future<LicensedAgent?> getAgent(String agentId) async {
    final doc = await _agentsRef.doc(_licensedAgentDocId(agentId)).get();
    if (!doc.exists) return null;
    return LicensedAgent.fromFirestore(doc);
  }

  /// Update public agent fields on `licensed_agents` (bio-view / profile).
  Future<void> updateLicensedAgentProfile(
    String agentId, {
    String? firstName,
    String? lastName,
    String? bio,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    await _agentsRef.doc(_licensedAgentDocId(agentId)).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Agent UID resolution
  // ---------------------------------------------------------------------------

  /// Look up the Firebase UID of a registered agent by their institution ID.
  /// Returns null if the agent hasn't signed up or [users] profile doesn't match.
  Future<String?> getAgentUid(String agentId) async {
    final agent = await getAgent(agentId);
    if (agent == null) return null;
    final uid = agent.registeredUid;
    if (uid == null || uid.isEmpty) return null;
    final ok = await _isRegisteredAgentLinkOk(agent.agentId, uid);
    return ok ? uid : null;
  }

  // ---------------------------------------------------------------------------
  // Assignments
  // ---------------------------------------------------------------------------

  /// Create a new assignment (landlord assigns agent to listing).
  /// Enforces one active (pending/accepted) assignment per listing.
  Future<ListingAssignment> createAssignment({
    required String listingId,
    required String agentId,
    required String landlordId,
    String? agentUid,
    String? agentName,
    String? listingTitle,
  }) async {
    if (agentUid == null || agentUid.isEmpty) {
      throw StateError('Agent has not registered yet.');
    }

    // Check for existing active assignment on this listing.
    final existing = await _assignmentsRef
        .where('listingId', isEqualTo: listingId)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError(
          'Listing already has an active assignment. Decline the existing one first.');
    }

    final ref = _assignmentsRef.doc();
    final assignment = ListingAssignment(
      id: ref.id,
      listingId: listingId,
      agentId: agentId,
      landlordId: landlordId,
      status: AssignmentStatus.pending,
      agentUid: agentUid,
      agentName: agentName,
      listingTitle: listingTitle,
    );
    await ref.set(assignment.toFirestoreCreate());
    return assignment;
  }

  /// Stream assignments for an agent (by Firebase UID), filtered by status.
  Stream<List<ListingAssignment>> agentAssignmentsStream(
    String agentUid, {
    AssignmentStatus? status,
  }) {
    Query<Map<String, dynamic>> q =
        _assignmentsRef.where('agentUid', isEqualTo: agentUid);
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    return q.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => ListingAssignment.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aAt = a.assignedAt ?? DateTime(0);
        final bAt = b.assignedAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      return list;
    });
  }

  /// Listing IDs for this landlord that already have a **pending** or **accepted**
  /// assignment (negotiation or active representation — no new assignment until declined).
  Stream<Set<String>> landlordBusyAssignmentListingIdsStream(
    String landlordId,
  ) {
    return _assignmentsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snap) {
      final ids = <String>{};
      for (final doc in snap.docs) {
        final a = ListingAssignment.fromFirestore(doc);
        if (a.status == AssignmentStatus.pending ||
            a.status == AssignmentStatus.accepted) {
          ids.add(a.listingId);
        }
      }
      return ids;
    });
  }

  /// Get the active assignment for a listing (pending or accepted).
  Future<ListingAssignment?> getActiveAssignment(String listingId) async {
    final snap = await _assignmentsRef
        .where('listingId', isEqualTo: listingId)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();
    if (snap.docs.isEmpty) return null;
    return ListingAssignment.fromFirestore(snap.docs.first);
  }

  /// Stream the active assignment for a listing.
  Stream<ListingAssignment?> activeAssignmentStream(String listingId) {
    return _assignmentsRef
        .where('listingId', isEqualTo: listingId)
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ListingAssignment.fromFirestore(snap.docs.first);
    });
  }

  /// Agent accepts an assignment.
  Future<void> acceptAssignment(String assignmentId) async {
    await _assignmentsRef.doc(assignmentId).update({
      'status': AssignmentStatus.accepted.value,
    });
  }

  /// Agent declines an assignment.
  Future<void> declineAssignment(String assignmentId) async {
    await _assignmentsRef.doc(assignmentId).update({
      'status': AssignmentStatus.declined.value,
    });
  }
}
