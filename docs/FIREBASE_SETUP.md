# Firebase setup for ExpatHomes

This app uses **Firebase Authentication** and **Cloud Firestore**. Follow these steps to run the app with a real backend.

---

## 1. Create a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a new project (or use an existing one).
3. Enable **Authentication** → sign-in method **Email/Password**.
4. Create a **Firestore Database** (start in test mode for development; lock down with rules before production).

---

## 2. Register the app with Firebase

### Android

1. In Firebase Console, add an Android app. Use the package name from `expat_app/android/app/build.gradle` (e.g. `com.example.expat_app`).
2. Download `google-services.json` and place it in `expat_app/android/app/`.

### iOS

1. In Firebase Console, add an iOS app. Use the bundle ID from `expat_app/ios/Runner/Info.plist` or Xcode.
2. Download `GoogleService-Info.plist` and add it to `expat_app/ios/Runner/` in Xcode (drag into Runner, check “Copy items if needed”).

### Optional: FlutterFire CLI

From the project root:

```bash
cd expat_app
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates `lib/firebase_options.dart` and configures all platforms. Then in `main.dart` use:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ExpatApp());
}
```

If you do **not** use FlutterFire CLI, `Firebase.initializeApp()` with no arguments is enough once `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place.

---

## 3. Firestore structure (auth phase)

The app expects at least this collection:

| Collection | Document ID | Purpose |
|------------|-------------|--------|
| `users` | Firebase Auth UID | User profile: `email`, `role` (expat \| landlord \| agent \| super_admin), `preferredLanguage`, `createdAt`, `updatedAt`, and role-specific fields (see `UserProfile` in `lib/models/user_profile.dart`). |

Documents are created automatically on sign-up by `AuthService.register()`.

---

## 4. Firestore security rules (starter)

Use these as a starting point. Tighten for production (e.g. restrict `role` to allowed values, validate fields).

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: only the signed-in user can read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Deploy from Firebase Console → Firestore → Rules, or using Firebase CLI.

---

## 5. Run the app

```bash
cd expat_app
flutter pub get
flutter run
```

- **Sign up**: Choose role on Get Started, enter email (and language), then complete the role-specific sign-up form. A Firebase user and a `users/{uid}` document are created.
- **Sign in**: Email + password; you are routed to Expat / Landlord / Agent home based on your profile `role`.

---

## 6. Next steps (from BACKEND_CHECKLIST)

After auth is working:

1. **Listings & media** — Firestore collections for listings, listing_media; Storage for images.
2. **Super Admin** — Admin APIs and (optionally) web panel.
3. **Agents & assignments** — `licensed_agents` (or seed), `listing_assignments`.
4. **Conversations & messages** — `conversations`, `conversation_participants`, `messages`.
5. **Community** — posts, comments, bowls.
6. **Payments** — commission_slips.

See `docs/BACKEND_CHECKLIST.md` and `docs/BACKEND_IMPLEMENTATION_PLAN.md` for the full plan.
