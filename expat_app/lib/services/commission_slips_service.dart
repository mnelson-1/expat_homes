import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/commission_slip.dart';

class CommissionSlipsService {
  CommissionSlipsService._();
  static final CommissionSlipsService _instance = CommissionSlipsService._();
  factory CommissionSlipsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _slipsRef =>
      _firestore.collection('commission_slips');

  /// Auto-generate a reference like COM-A3F9K2.
  String _generateReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'COM-$code';
  }

  /// Agent creates a new commission slip.
  Future<CommissionSlip> createSlip({
    required String listingTitle,
    required String contractCode,
    required String landlordId,
    required String landlordName,
    required String agentId,
    required String agentUid,
    required String agentName,
    required String amount,
    required String recipientPhone,
    String homeOwnerId = '',
    String paymentMethod = 'MTN Momo',
  }) async {
    final slip = CommissionSlip(
      id: '',
      reference: _generateReference(),
      listingTitle: listingTitle,
      contractCode: contractCode,
      landlordId: landlordId,
      landlordName: landlordName,
      agentId: agentId,
      agentUid: agentUid,
      agentName: agentName,
      amount: amount,
      paymentMethod: paymentMethod,
      recipientPhone: recipientPhone,
      homeOwnerId: homeOwnerId,
      status: SlipStatus.pending,
    );

    final docRef = await _slipsRef.add(slip.toFirestoreCreate());
    final created = await docRef.get();
    return CommissionSlip.fromFirestore(created);
  }

  /// Real-time stream of slips for the agent (by Firebase UID).
  /// Client-side sort avoids composite index.
  Stream<List<CommissionSlip>> agentSlipsStream(String agentUid) {
    return _slipsRef
        .where('agentUid', isEqualTo: agentUid)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => CommissionSlip.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Real-time stream of slips for the landlord.
  /// Client-side sort avoids composite index.
  Stream<List<CommissionSlip>> landlordSlipsStream(String landlordId) {
    return _slipsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => CommissionSlip.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Landlord mock-pays: sets status to agent_confirmation_pending.
  Future<void> paySlip(String slipId) async {
    await _slipsRef.doc(slipId).update({
      'status': SlipStatus.agentConfirmationPending.value,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Agent confirms payment received.
  Future<void> confirmSlip(String slipId) async {
    await _slipsRef.doc(slipId).update({
      'status': SlipStatus.confirmed.value,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Agent reports an issue with a payment.
  Future<void> reportSlip(String slipId) async {
    await _slipsRef.doc(slipId).update({
      'status': SlipStatus.reported.value,
    });
  }

  /// Look up a slip by its reference code (e.g. COM-A3F9K2).
  Future<CommissionSlip?> getSlipByReference(String reference) async {
    final snap = await _slipsRef
        .where('reference', isEqualTo: reference)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CommissionSlip.fromFirestore(snap.docs.first);
  }
}
