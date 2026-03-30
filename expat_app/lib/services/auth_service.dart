import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import 'bowls_service.dart';

/// Firestore collection name for user profiles (BACKEND_CHECKLIST §1.1).
const String kUsersCollection = 'users';

/// Maps normalized email → Firebase UID for pre-sign-in “email taken” checks.
const String kRegisteredEmailsCollection = 'registered_emails';

/// Result of [AuthService.lookupEmailForRegistration] (Get Started / sign-up gating).
enum EmailLookupKind {
  empty,
  invalidFormat,

  /// Not taken in Firebase Auth or in [kRegisteredEmailsCollection].
  available,

  /// Email already used (Auth and/or Firestore registry).
  alreadyRegistered,
  error,
}

class EmailRegistrationLookupResult {
  const EmailRegistrationLookupResult({required this.kind, this.detail});

  final EmailLookupKind kind;
  final String? detail;

  bool get allowsNewRegistration => kind == EmailLookupKind.available;

  /// Short line under the email field (null when [kind] is [EmailLookupKind.empty]).
  String? get statusMessage {
    switch (kind) {
      case EmailLookupKind.empty:
        return null;
      case EmailLookupKind.invalidFormat:
        return 'Enter a valid email address.';
      case EmailLookupKind.available:
        return 'This email is available.';
      case EmailLookupKind.alreadyRegistered:
        return 'An account with this email already exists. Use Login below.';
      case EmailLookupKind.error:
        return detail?.trim().isNotEmpty == true
            ? detail!.trim()
            : 'Could not verify email. Try again.';
    }
  }
}

/// Handles Firebase Auth and Firestore user profiles.
/// Use for register, login, logout, auth state, and current user profile.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Basic shape check for sign-up flows (Get Started, etc.).
  static bool emailLooksValid(String email) =>
      _emailFormat.hasMatch(email.trim());

  /// Same key as [kRegisteredEmailsCollection] document ids (trim + lowercase).
  static String normalizeRegistrationEmail(String email) =>
      email.trim().toLowerCase();

  Future<void> _claimRegisteredEmail(String normalizedEmail, String uid) async {
    final ref = _firestore
        .collection(kRegisteredEmailsCollection)
        .doc(normalizedEmail);
    await ref.set({
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _swapRegisteredEmailClaim({
    required String? oldNormalized,
    required String newNormalized,
    required String uid,
  }) async {
    if (oldNormalized == newNormalized) return;
    await _firestore.runTransaction((txn) async {
      if (oldNormalized != null && oldNormalized.isNotEmpty) {
        final oldRef = _firestore
            .collection(kRegisteredEmailsCollection)
            .doc(oldNormalized);
        final oldSnap = await txn.get(oldRef);
        if (oldSnap.exists && oldSnap.data()?['uid'] == uid) {
          txn.delete(oldRef);
        }
      }
      final newRef = _firestore
          .collection(kRegisteredEmailsCollection)
          .doc(newNormalized);
      final newSnap = await txn.get(newRef);
      if (newSnap.exists) {
        final existing = newSnap.data()?['uid'] as String?;
        if (existing != null && existing != uid) {
          throw StateError('email_already_registered');
        }
      }
      txn.set(newRef, {'uid': uid, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  /// Returns [EmailLookupKind.alreadyRegistered] if Firebase Auth **or**
  /// [kRegisteredEmailsCollection] has this email.
  ///
  /// Signed-out users cannot query `users`, so we mirror claimed emails at registration
  /// and check that doc here. Legacy accounts may only exist in Auth until they sign in
  /// again (registry backfill is optional).
  ///
  /// Uses Auth sign-in-methods lookup plus Firestore. If **email enumeration
  /// protection** is enabled, Auth behaviour may differ—treat failures as
  /// [EmailLookupKind.error] and retry.
  Future<EmailRegistrationLookupResult> lookupEmailForRegistration(
    String rawEmail,
  ) async {
    final t = rawEmail.trim();
    if (t.isEmpty) {
      return const EmailRegistrationLookupResult(kind: EmailLookupKind.empty);
    }
    if (!emailLooksValid(t)) {
      return const EmailRegistrationLookupResult(
        kind: EmailLookupKind.invalidFormat,
      );
    }
    final normalized = normalizeRegistrationEmail(t);
    try {
      // Deprecated API; server Callable is the long-term hardening path.
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(t);
      if (methods.isNotEmpty) {
        return const EmailRegistrationLookupResult(
          kind: EmailLookupKind.alreadyRegistered,
        );
      }
      final regSnap =
          await _firestore
              .collection(kRegisteredEmailsCollection)
              .doc(normalized)
              .get();
      if (regSnap.exists) {
        return const EmailRegistrationLookupResult(
          kind: EmailLookupKind.alreadyRegistered,
        );
      }
      return const EmailRegistrationLookupResult(
        kind: EmailLookupKind.available,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return const EmailRegistrationLookupResult(
          kind: EmailLookupKind.invalidFormat,
        );
      }
      return EmailRegistrationLookupResult(
        kind: EmailLookupKind.error,
        detail: e.message ?? e.code,
      );
    } catch (e) {
      return EmailRegistrationLookupResult(
        kind: EmailLookupKind.error,
        detail: e.toString(),
      );
    }
  }

  /// Current Firebase user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state: emits User? (null = signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the current user's profile from Firestore. Returns null if not signed in
  /// or profile doc is missing.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection(kUsersCollection).doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// One-time read of any user's profile by Firebase UID.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(kUsersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// Real-time stream of a user's profile (e.g. message thread avatars).
  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore.collection(kUsersCollection).doc(uid).snapshots().map((
      snap,
    ) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap);
    });
  }

  /// Stream the current user's profile (updates when doc changes).
  Stream<UserProfile?> get currentUserProfileStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore
          .collection(kUsersCollection)
          .doc(user.uid)
          .snapshots()
          .map((snap) {
            if (!snap.exists || snap.data() == null) return null;
            return UserProfile.fromFirestore(snap);
          });
    });
  }

  /// Register with email and password, then create Firestore user profile.
  /// [role] must be set. [profile] should contain role-specific fields.
  /// Sends email verification if [sendEmailVerification] is true.
  Future<UserProfile> register({
    required String email,
    required String password,
    required UserRole role,
    required UserProfile profile,
    bool sendEmailVerification = true,
  }) async {
    if (profile.termsAndPrivacyConsentAt == null ||
        profile.acceptedLegalVersion == null ||
        profile.acceptedLegalVersion!.trim().isEmpty) {
      throw StateError(
        'You must accept the Terms of Service and Privacy Policy to create an account.',
      );
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Account could not be created',
      );
    }

    final createData =
        UserProfile(
          id: user.uid,
          email: user.email ?? email,
          role: role,
          preferredLanguage: profile.preferredLanguage,
          emailVerifiedAt: user.emailVerified ? DateTime.now() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          legalFirstName: profile.legalFirstName,
          legalLastName: profile.legalLastName,
          dateOfBirth: profile.dateOfBirth,
          countryOfCitizenship: profile.countryOfCitizenship,
          demographic: profile.demographic,
          agentId: profile.agentId,
          bio: profile.bio,
          termsAndPrivacyConsentAt: profile.termsAndPrivacyConsentAt,
          acceptedLegalVersion: profile.acceptedLegalVersion,
        ).toFirestoreCreate();

    await _firestore.collection(kUsersCollection).doc(user.uid).set(createData);

    try {
      await _claimRegisteredEmail(
        normalizeRegistrationEmail(user.email ?? email),
        user.uid,
      );
    } catch (_) {
      // Rare race or rules mismatch; Auth + users doc still own the account.
    }

    // Link the agent's Firebase UID to their licensed_agents record.
    // Doc IDs are uppercase (e.g. RM-204112); normalize so signup always hits the same doc.
    if (role == UserRole.agent && profile.agentId != null) {
      final aid = profile.agentId!.trim().toUpperCase();
      if (aid.isNotEmpty) {
        try {
          await _firestore.collection('licensed_agents').doc(aid).update({
            'registeredUid': user.uid,
          });
        } catch (_) {}
      }
    }

    if (role == UserRole.expat) {
      try {
        await BowlsService().autoJoinOnSignUp(
          user.uid,
          profile.countryOfCitizenship,
        );
      } catch (_) {}
    }

    if (sendEmailVerification && !user.emailVerified) {
      await user.sendEmailVerification();
    }

    return (await getCurrentUserProfile())!;
  }

  /// Sign in with email and password. Returns profile from Firestore.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await getCurrentUserProfile();
    if (profile == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'User profile not found. Please contact support.',
      );
    }
    return profile;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Reload Firebase user (e.g. after email verification) and return updated profile.
  Future<UserProfile?> reloadUserAndProfile() async {
    await _auth.currentUser?.reload();
    return getCurrentUserProfile();
  }

  /// Upload a profile image to Firebase Storage and update the Firestore
  /// user document with the download URL. Returns the URL.
  Future<String> uploadProfileImage(XFile image) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    final bytes = await image.readAsBytes();
    final ref = _storage.ref('users/${user.uid}/profile');
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await task.timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('Profile image upload timed out'),
    );
    final url = await snapshot.ref.getDownloadURL().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Getting image URL timed out'),
    );

    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'profileImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  /// Update legal name (expat / landlord). [legalLastName] may be empty.
  Future<void> updateLegalName({
    required String legalFirstName,
    required String legalLastName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'legalFirstName': legalFirstName.trim(),
      'legalLastName': legalLastName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update profile bio for the current user (`users` doc).
  Future<void> updateUserBio(String bio) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Optional contact phone on `users` (e.g. landlord; admins may use for listing review).
  Future<void> updateUserPhone(String phone) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final trimmed = phone.trim();
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (trimmed.isEmpty) {
      updates['phone'] = FieldValue.delete();
    } else {
      updates['phone'] = trimmed;
    }
    await _firestore.collection(kUsersCollection).doc(user.uid).update(updates);
  }

  /// Updates email in Firestore and attempts Firebase Auth email update.
  Future<void> updateUserEmail(String email) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final trimmed = email.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(email, 'email', 'empty');
    final oldNorm =
        user.email != null && user.email!.trim().isNotEmpty
            ? normalizeRegistrationEmail(user.email!)
            : null;
    final newNorm = normalizeRegistrationEmail(trimmed);
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'email': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await _swapRegisteredEmailClaim(
        oldNormalized: oldNorm,
        newNormalized: newNorm,
        uid: user.uid,
      );
    } catch (_) {
      // Registry out of sync with profile; Get Started may still see stale state.
    }
    try {
      await user.verifyBeforeUpdateEmail(trimmed);
    } on FirebaseAuthException {
      // Profile document already updated; user may need to fix email or re-auth.
      rethrow;
    }
  }

  /// Sync agent display name on the user document (optional; agent registry is source of truth).
  Future<void> updateAgentUserDocName({
    required String legalFirstName,
    required String legalLastName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'legalFirstName': legalFirstName.trim(),
      'legalLastName': legalLastName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Preferred language (same values as registration).
  Future<void> updatePreferredLanguage(String language) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'preferredLanguage': language.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Expat country of citizenship (same values as expat sign-up).
  Future<void> updateCountryOfCitizenship(String country) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _firestore.collection(kUsersCollection).doc(user.uid).update({
      'countryOfCitizenship': country.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
