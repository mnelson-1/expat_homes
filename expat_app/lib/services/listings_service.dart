import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing.dart';

const String kListingsCollection = 'listings';
const String kStorageListingsPath = 'listings';

/// Listings and listing media (Firestore + Storage).
/// BACKEND_CHECKLIST §1.2, §2.3, §2.4.
class ListingsService {
  ListingsService._();
  static final ListingsService _instance = ListingsService._();
  factory ListingsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _listingsRef =>
      _firestore.collection(kListingsCollection);

  /// Optional progress message callback, e.g. "Uploading image 1 of 2...".
  void Function(String message)? onProgress;

  /// Create a new listing (landlord). Uploads images to Storage, then creates
  /// Firestore doc with status pending_verification.
  /// [onProgress] can be set before calling to show status (e.g. "Uploading image 1 of 2...").
  /// Each image upload has a 45s timeout; total operation has no extra timeout (caller can wrap).
  Future<Listing> createListing({
    required String landlordId,
    required ListingType type,
    required String title,
    required String description,
    required String location,
    required String price,
    String? upi,
    required List<XFile> imageFiles,
  }) async {
    final ref = _listingsRef.doc();
    final listingId = ref.id;

    final mediaUrls = <String>[];
    const perImageTimeout = Duration(seconds: 45);

    if (imageFiles.isNotEmpty) {
      for (var i = 0; i < imageFiles.length; i++) {
        onProgress?.call('Uploading image ${i + 1} of ${imageFiles.length}...');
        final path = '$kStorageListingsPath/$listingId/$i';
        final bytes = await imageFiles[i].readAsBytes();
        final task = _storage
            .ref(path)
            .putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        final snapshot = await task.timeout(
          perImageTimeout,
          onTimeout:
              () =>
                  throw TimeoutException(
                    'Image ${i + 1} upload timed out. Try a smaller photo, fewer photos, or check your connection.',
                  ),
        );
        final url = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout:
              () => throw TimeoutException('Getting image URL timed out.'),
        );
        mediaUrls.add(url);
      }
    }

    onProgress?.call('Saving listing...');

    // Resolve landlord display name once so Super Admin and other clients
    // can show it directly from the listing document.
    String? representativeName;
    try {
      final userSnap =
          await _firestore.collection('users').doc(landlordId).get();
      final data = userSnap.data();
      if (data != null) {
        final first = (data['legalFirstName'] as String?) ?? '';
        final last = (data['legalLastName'] as String?) ?? '';
        final combined = '$first $last'.trim();
        if (combined.isNotEmpty) {
          representativeName = combined;
        } else {
          representativeName = data['email'] as String?;
        }
      }
    } catch (_) {
      // If this lookup fails for any reason, we still proceed; the
      // listing will just omit representativeName.
    }

    final listing = Listing(
      id: listingId,
      landlordId: landlordId,
      type: type,
      title: title,
      description: description,
      location: location,
      price: price,
      upi: upi?.isNotEmpty == true ? upi : null,
      mediaUrls: mediaUrls,
      status: ListingStatus.pendingVerification,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      representativeName: representativeName,
      representativeRole: 'Landlord',
    );

    await ref.set(listing.toFirestoreCreate());
    return listing;
  }

  /// Update an existing listing's fields directly (landlord editing their own listing).
  Future<void> updateListing({
    required String listingId,
    required Map<String, dynamic> fields,
  }) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _listingsRef.doc(listingId).update(fields);
  }

  /// Get a single listing by id. Returns null if not found.
  Future<Listing?> getListingById(String id) async {
    final doc = await _listingsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Listing.fromFirestore(doc);
  }

  /// Resolve representative name from listing doc (or users when allowed).
  /// Listings store representativeName/representativeRole at create time. If present, use them
  /// so expats (who cannot read other users' profiles) still see the name. Otherwise try
  /// users collection; on permission denied (e.g. expat viewing) keep listing's values or 'Landlord'.
  Future<Listing?> getListingByIdWithRepresentative(String id) async {
    final listing = await getListingById(id);
    if (listing == null) return null;
    String? name = listing.representativeName;
    String role = listing.representativeRole ?? 'Landlord';
    try {
      final userDoc =
          await _firestore.collection('users').doc(listing.landlordId).get();
      final data = userDoc.data();
      if (data != null) {
        final firstName = data['legalFirstName'] as String? ?? '';
        final lastName = data['legalLastName'] as String? ?? '';
        final combined = [firstName, lastName].join(' ').trim();
        if (combined.isNotEmpty) {
          name = combined;
          role = 'Landlord';
        }
      }
    } catch (_) {
      // Expat (or other non-landlord) cannot read users/{landlordId}. Use stored or default.
      if (name == null || name.isEmpty) name = 'Landlord';
    }
    return Listing(
      id: listing.id,
      landlordId: listing.landlordId,
      agentId: listing.agentId,
      type: listing.type,
      title: listing.title,
      description: listing.description,
      location: listing.location,
      price: listing.price,
      upi: listing.upi,
      mediaUrls: listing.mediaUrls,
      status: listing.status,
      createdAt: listing.createdAt,
      updatedAt: listing.updatedAt,
      publishedAt: listing.publishedAt,
      verifiedBy: listing.verifiedBy,
      representativeName: name,
      representativeRole: role,
    );
  }

  /// Stream of published listings (for Expat Estates). Sorted by createdAt in memory to avoid composite index.
  Stream<List<Listing>> publishedListingsStream({
    ListingType? type,
    String searchQuery = '',
  }) {
    final query = _listingsRef.where(
      'status',
      isEqualTo: ListingStatus.published.value,
    );

    return query.snapshots().map((snap) {
      var list = snap.docs.map((d) => Listing.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aAt = a.createdAt ?? DateTime(0);
        final bAt = b.createdAt ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
      if (type != null) {
        list = list.where((l) => l.type == type).toList();
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list =
            list.where((l) {
              return l.title.toLowerCase().contains(q) ||
                  l.location.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q);
            }).toList();
      }
      return list;
    });
  }

  /// Stream of listings for a landlord (My Listings). Sorted by createdAt in memory to avoid composite index.
  Stream<List<Listing>> landlordListingsStream(String landlordId) {
    return _listingsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Listing.fromFirestore(d)).toList();
          list.sort((a, b) {
            final aAt = a.createdAt ?? DateTime(0);
            final bAt = b.createdAt ?? DateTime(0);
            return bAt.compareTo(aAt);
          });
          return list;
        });
  }

  /// One-time fetch published listings (e.g. for initial load without stream).
  Future<List<Listing>> getPublishedListings({
    ListingType? type,
    String searchQuery = '',
  }) async {
    var query = _listingsRef.where(
      'status',
      isEqualTo: ListingStatus.published.value,
    );
    if (type != null) {
      query = query.where('type', isEqualTo: type.value);
    }
    final snap = await query.get();
    var list = snap.docs.map((d) => Listing.fromFirestore(d)).toList();
    list.sort((a, b) {
      final aAt = a.createdAt ?? DateTime(0);
      final bAt = b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list =
          list.where((l) {
            return l.title.toLowerCase().contains(q) ||
                l.location.toLowerCase().contains(q) ||
                l.description.toLowerCase().contains(q);
          }).toList();
    }
    return list;
  }

  /// One-time fetch landlord listings. Sorted by createdAt in memory.
  Future<List<Listing>> getLandlordListings(String landlordId) async {
    final snap =
        await _listingsRef.where('landlordId', isEqualTo: landlordId).get();
    final list = snap.docs.map((d) => Listing.fromFirestore(d)).toList();
    list.sort((a, b) {
      final aAt = a.createdAt ?? DateTime(0);
      final bAt = b.createdAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    return list;
  }
}
