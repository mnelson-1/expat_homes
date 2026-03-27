import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expat_app/models/commission_slip.dart';
import 'package:expat_app/models/listing.dart';
import 'package:expat_app/models/user_profile.dart';

void main() {
  group('Listing model', () {
    test('status parsing supports pending and published', () {
      expect(
        ListingStatus.fromString('pending_verification'),
        ListingStatus.pendingVerification,
      );
      expect(ListingStatus.fromString('published'), ListingStatus.published);
      expect(ListingStatus.fromString('unknown'), ListingStatus.draft);
    });
  });

  group('UserProfile serialization', () {
    test('toFirestore includes optional phone when present', () {
      final profile = UserProfile(
        id: 'u1',
        email: 'u1@test.dev',
        role: UserRole.landlord,
        legalFirstName: 'Jane',
        legalLastName: 'Doe',
        phone: '+250700000000',
      );
      final map = profile.toFirestore();
      expect(map['phone'], '+250700000000');
    });
  });

  group('Commission slip status', () {
    test('status fromString maps known values', () {
      expect(
        SlipStatus.fromString('agent_confirmation_pending'),
        SlipStatus.agentConfirmationPending,
      );
      expect(SlipStatus.fromString('confirmed'), SlipStatus.confirmed);
      expect(SlipStatus.fromString('reported'), SlipStatus.reported);
      expect(SlipStatus.fromString('???'), SlipStatus.pending);
    });

    test('isConfirmed true only for confirmed status', () {
      final slip = CommissionSlip(
        id: 's1',
        listingId: 'l1',
        listingTitle: 'Benchmark Listing',
        contractCode: 'CTR-1',
        landlordId: 'landlord',
        landlordName: 'Landlord One',
        agentId: 'AG-1',
        agentUid: 'agent',
        agentName: 'Agent One',
        amount: '1000',
        reference: 'COM-123456',
        paymentMethod: 'MTN Momo',
        recipientPhone: '+250700000000',
        status: SlipStatus.confirmed,
        createdAt: DateTime.now(),
      );
      expect(slip.isConfirmed, isTrue);

      final pending = CommissionSlip(
        id: 's2',
        listingId: 'l1',
        listingTitle: 'Benchmark Listing',
        contractCode: 'CTR-2',
        landlordId: 'landlord',
        landlordName: 'Landlord One',
        agentId: 'AG-1',
        agentUid: 'agent',
        agentName: 'Agent One',
        amount: '1000',
        reference: 'COM-654321',
        paymentMethod: 'MTN Momo',
        recipientPhone: '+250700000000',
        status: SlipStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(pending.isConfirmed, isFalse);
    });
  });

  group('Timestamp interoperability', () {
    test('cloud_firestore Timestamp works for model dates', () {
      final now = DateTime.now();
      final ts = Timestamp.fromDate(now);
      expect(ts.toDate().millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });
}

