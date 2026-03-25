import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing_edit_request.dart';
import '../models/listing_revision.dart';
import 'auth_service.dart';

const String kEditRequestsCollection = 'edit_requests';
const String kRevisionsCollection = 'listing_revisions';

/// Handles Firestore operations for listing_edit_requests and listing_revisions.
/// BACKEND_CHECKLIST §1.3, §2.5.
class EditRequestsService {
  EditRequestsService._();
  static final EditRequestsService _instance = EditRequestsService._();
  factory EditRequestsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection(kEditRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _revisionsRef =>
      _firestore.collection(kRevisionsCollection);

  // ---------------------------------------------------------------------------
  // Edit requests (Step 1: Landlord requests permission to edit)
  // ---------------------------------------------------------------------------

  /// Submit a new edit request for a listing. Status starts as [pending].
  /// Returns the created [ListingEditRequest].
  Future<ListingEditRequest> createEditRequest({
    required String listingId,
    required String landlordId,
    Map<String, dynamic> proposedFields = const {},
    String? reason,
  }) async {
    final ref = _requestsRef.doc();
    final req = ListingEditRequest(
      id: ref.id,
      listingId: listingId,
      landlordId: landlordId,
      status: EditRequestStatus.pending,
      proposedFields: proposedFields,
      reason: reason,
    );
    await ref.set(req.toFirestoreCreate());
    return req;
  }

  /// Stream of all edit requests for a landlord's listings.
  Stream<List<ListingEditRequest>> landlordEditRequestsStream(
      String landlordId) {
    return _requestsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ListingEditRequest.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aAt = a.createdAt ?? DateTime(0);
        final bAt = b.createdAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      return list;
    });
  }

  /// One-time fetch: the latest edit request for a specific listing.
  Future<ListingEditRequest?> getLatestEditRequest(String listingId) async {
    final snap = await _requestsRef
        .where('listingId', isEqualTo: listingId)
        .get();
    if (snap.docs.isEmpty) return null;
    final list =
        snap.docs.map((d) => ListingEditRequest.fromFirestore(d)).toList();
    list.sort((a, b) {
      final aAt = a.createdAt ?? DateTime(0);
      final bAt = b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    return list.first;
  }

  /// Landlord taps “Edit Request Approved” to clear the banner; does not change [status].
  Future<void> landlordAcknowledgeApprovedEdit(String editRequestId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to acknowledge.');
    }
    await _requestsRef.doc(editRequestId).update({
      'landlordAcknowledgedApprovalAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of the latest edit request for a specific listing.
  /// Includes a landlordId filter so the query satisfies Firestore rules.
  Stream<ListingEditRequest?> listingEditRequestStream(String listingId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _requestsRef
        .where('listingId', isEqualTo: listingId)
        .where('landlordId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final list =
          snap.docs.map((d) => ListingEditRequest.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aAt = a.createdAt ?? DateTime(0);
        final bAt = b.createdAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      return list.first;
    });
  }

  // ---------------------------------------------------------------------------
  // Revisions (Step 2: Landlord submits proposed changes)
  // ---------------------------------------------------------------------------

  /// Submit proposed listing changes after edit request approved.
  /// Creates a [ListingRevision] with status [pendingReview].
  Future<ListingRevision> submitRevision({
    required String editRequestId,
    required String listingId,
    required String landlordId,
    required Map<String, dynamic> proposedFields,
  }) async {
    final ref = _revisionsRef.doc();
    final uid = AuthService().currentUser?.uid ?? landlordId;
    final revision = ListingRevision(
      id: ref.id,
      editRequestId: editRequestId,
      listingId: listingId,
      landlordId: uid,
      status: RevisionStatus.pendingReview,
      proposedFields: proposedFields,
    );
    await ref.set(revision.toFirestoreCreate());
    return revision;
  }

  /// Stream of all revisions for a listing.
  Stream<List<ListingRevision>> listingRevisionsStream(String listingId) {
    return _revisionsRef
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ListingRevision.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aAt = a.createdAt ?? DateTime(0);
        final bAt = b.createdAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      return list;
    });
  }
}
