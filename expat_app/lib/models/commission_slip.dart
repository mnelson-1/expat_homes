import 'package:cloud_firestore/cloud_firestore.dart';

enum SlipStatus {
  pending('pending'),
  agentConfirmationPending('agent_confirmation_pending'),
  confirmed('confirmed'),
  reported('reported');

  const SlipStatus(this.value);
  final String value;

  static SlipStatus fromString(String? v) {
    if (v == null) return SlipStatus.pending;
    return SlipStatus.values.firstWhere(
      (s) => s.value == v,
      orElse: () => SlipStatus.pending,
    );
  }

  String get displayLabel {
    switch (this) {
      case SlipStatus.pending:
        return 'Payment Pending';
      case SlipStatus.agentConfirmationPending:
        return 'Awaiting Confirmation';
      case SlipStatus.confirmed:
        return 'Payment Confirmed';
      case SlipStatus.reported:
        return 'Reported';
    }
  }
}

class CommissionSlip {
  CommissionSlip({
    required this.id,
    required this.reference,
    this.listingId = '',
    required this.listingTitle,
    required this.contractCode,
    required this.landlordId,
    required this.landlordName,
    required this.agentId,
    required this.agentUid,
    required this.agentName,
    required this.amount,
    required this.paymentMethod,
    required this.recipientPhone,
    this.homeOwnerId = '',
    this.status = SlipStatus.pending,
    this.createdAt,
    this.paidAt,
    this.confirmedAt,
  });

  final String id;
  final String reference;
  /// Firestore `listings` document id; used for one slip per listing per agent.
  final String listingId;
  final String listingTitle;
  final String contractCode;
  final String landlordId;
  final String landlordName;
  final String agentId;
  final String agentUid;
  final String agentName;
  final String amount;
  final String paymentMethod;
  final String recipientPhone;
  final String homeOwnerId;
  final SlipStatus status;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? confirmedAt;

  bool get isConfirmed => status == SlipStatus.confirmed;

  factory CommissionSlip.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('CommissionSlip document ${doc.id} has no data');
    }
    return CommissionSlip(
      id: doc.id,
      reference: data['reference'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? '',
      contractCode: data['contractCode'] as String? ?? '',
      landlordId: data['landlordId'] as String? ?? '',
      landlordName: data['landlordName'] as String? ?? '',
      agentId: data['agentId'] as String? ?? '',
      agentUid: data['agentUid'] as String? ?? '',
      agentName: data['agentName'] as String? ?? '',
      amount: data['amount'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? 'MTN Momo',
      recipientPhone: data['recipientPhone'] as String? ?? '',
      homeOwnerId: data['homeOwnerId'] as String? ?? '',
      status: SlipStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reference': reference,
        'listingId': listingId,
        'listingTitle': listingTitle,
        'contractCode': contractCode,
        'landlordId': landlordId,
        'landlordName': landlordName,
        'agentId': agentId,
        'agentUid': agentUid,
        'agentName': agentName,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'recipientPhone': recipientPhone,
        'homeOwnerId': homeOwnerId,
        'status': status.value,
      };

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestore();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
