import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/bowl_cover_defaults.dart';
import '../constants/bowl_ids.dart';
import '../models/bowl.dart';

export '../constants/bowl_ids.dart'
    show kBowlExpatLife, kBowlJobHunting, kBowlNigeria;

class BowlsService {
  BowlsService._();
  static final BowlsService _instance = BowlsService._();
  factory BowlsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bowlsRef =>
      _firestore.collection('bowls');

  CollectionReference<Map<String, dynamic>> get _membersRef =>
      _firestore.collection('bowl_members');

  // ---------------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------------

  /// Idempotent seed of default bowls using fixed document IDs.
  /// New docs get default cover URLs; existing docs with missing [imageUrl] are backfilled.
  Future<void> seedDefaultBowls() async {
    final defaults = <String, Map<String, dynamic>>{
      kBowlExpatLife: {
        'name': 'Expatriate Life in Rwanda',
        'description':
            'A community recommended for all Expats, to share and review experiences in Rwanda. Connect, plan and have fun together.',
        'type': 'topic',
        'imageUrl': kDefaultBowlCoverImageUrls[kBowlExpatLife],
        'countryCode': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
      kBowlJobHunting: {
        'name': 'Job Hunting',
        'description':
            'A community to discuss the job market, as well as finding, applying for, posting, and interviewing for roles within and, if possible, outside the Rwandan job market.',
        'type': 'topic',
        'imageUrl': kDefaultBowlCoverImageUrls[kBowlJobHunting],
        'countryCode': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
      kBowlNigeria: {
        'name': 'Nigeria',
        'description':
            'A community for all Nigerian Expats in Rwanda. Bi-weekly Nigerian-themed events and many more.',
        'type': 'country',
        'imageUrl': kDefaultBowlCoverImageUrls[kBowlNigeria],
        'countryCode': 'Nigeria',
        'createdAt': FieldValue.serverTimestamp(),
      },
    };

    for (final entry in defaults.entries) {
      final ref = _bowlsRef.doc(entry.key);
      final doc = await ref.get();
      final coverUrl = entry.value['imageUrl'] as String?;

      if (!doc.exists) {
        await ref.set(entry.value);
        continue;
      }

      final existing = doc.data();
      final existingUrl = existing?['imageUrl'] as String?;
      if (existingUrl == null || existingUrl.trim().isEmpty) {
        await ref.update({'imageUrl': coverUrl});
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Fetch a single bowl by ID.
  Future<Bowl?> getBowl(String bowlId) async {
    final doc = await _bowlsRef.doc(bowlId).get();
    if (!doc.exists) return null;
    return Bowl.fromFirestore(doc);
  }

  /// Stream of all bowls.
  Stream<List<Bowl>> allBowlsStream() {
    return _bowlsRef.snapshots().map(
      (snap) => snap.docs.map((d) => Bowl.fromFirestore(d)).toList(),
    );
  }

  /// Get bowls the user has joined.
  Future<List<Bowl>> getUserBowls(String userId) async {
    final memberSnap =
        await _membersRef.where('userId', isEqualTo: userId).get();
    if (memberSnap.docs.isEmpty) return [];

    final bowlIds =
        memberSnap.docs.map((d) => d.data()['bowlId'] as String).toList();

    final List<Bowl> bowls = [];
    for (final bowlId in bowlIds) {
      final doc = await _bowlsRef.doc(bowlId).get();
      if (doc.exists) bowls.add(Bowl.fromFirestore(doc));
    }
    return bowls;
  }

  /// Stream of bowl IDs that a user has joined (for reactive UI).
  Stream<Set<String>> userBowlIdsStream(String userId) {
    return _membersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['bowlId'] as String).toSet());
  }

  // ---------------------------------------------------------------------------
  // Membership
  // ---------------------------------------------------------------------------

  Future<void> joinBowl(String bowlId, String userId) async {
    final existing = await _membersRef
        .where('bowlId', isEqualTo: bowlId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _membersRef.add({
      'bowlId': bowlId,
      'userId': userId,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveBowl(String bowlId, String userId) async {
    final snap = await _membersRef
        .where('bowlId', isEqualTo: bowlId)
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-join on sign-up
  // ---------------------------------------------------------------------------

  /// Auto-joins an expat to default bowls + their country bowl if available.
  Future<void> autoJoinOnSignUp(
    String userId,
    String? countryOfCitizenship,
  ) async {
    await seedDefaultBowls();

    await joinBowl(kBowlExpatLife, userId);
    await joinBowl(kBowlJobHunting, userId);

    if (countryOfCitizenship != null && countryOfCitizenship.isNotEmpty) {
      final countrySnap = await _bowlsRef
          .where('countryCode', isEqualTo: countryOfCitizenship)
          .limit(1)
          .get();
      if (countrySnap.docs.isNotEmpty) {
        await joinBowl(countrySnap.docs.first.id, userId);
      }
    }
  }
}
