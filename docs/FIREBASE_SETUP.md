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

## 3. Firestore structure (auth + listings)

The app uses these collections:

| Collection | Document ID | Purpose |
|------------|-------------|--------|
| `users` | Firebase Auth UID | User profile: `email`, `role`, `preferredLanguage`, etc. (see `UserProfile` in `lib/models/user_profile.dart`). Created on sign-up. |
| `listings` | Auto ID | Property listing: `landlordId`, `type` (apartment \| house \| short_stay), `title`, `description`, `location`, `price`, `upi`, `mediaUrls` (array of Storage URLs), `status` (draft \| pending_verification \| **published** \| archived), `createdAt`, `updatedAt`. Created when a landlord taps "Verify Listing" in Make a Listing. |

**To see listings as an Expat:** In Firestore Console, set a listing’s `status` to `published` (landlord-created listings start as `pending_verification` until Super Admin approval exists).

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

## 6. Firebase Storage (listings + profile images)

Enable **Storage** in Firebase Console (Build → Storage → Get started). The app uses:

- **Listings:** `listings/{listingId}/{index}` → stored in each listing’s `mediaUrls`.
- **Profile photos:** `users/{uid}/profile` (and similar under that user folder) → URL saved on the user’s Firestore `users/{uid}` document as `profileImageUrl`.

If uploads fail with **`firebase_storage/unauthorized`**, your **Storage rules** do not allow that path. Copy the rules below into **Storage → Rules** → **Publish** (or deploy the repo’s `storage.rules` with Firebase CLI).

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /listings/{listingId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    // Required for profile picture upload from the app
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 7. Troubleshooting: “Verify Listing” fails or times out

If the Make a Listing screen shows **TimeoutException** or **permission denied** when you tap “Verify Listing”, work through this checklist in **Firebase Console** ([console.firebase.google.com](https://console.firebase.google.com)):

### Step 1: Confirm Firebase Storage is enabled

1. Open your project → **Build** → **Storage**.
2. If you see **Get started**, click it and choose a location (e.g. `us-central1`). This creates the default bucket. If Storage is already set up, you’ll see the **Files** and **Rules** tabs.

### Step 2: Set Storage rules

1. In **Storage**, open the **Rules** tab.
2. Replace the rules with the snippet from **Section 6** above (covers both `listings/` and `users/{uid}/…` for profile photos).
3. Click **Publish**.  
   If rules are too strict (e.g. `allow read, write: if false`), uploads will fail or hang.  
   **Profile picture errors** (`unauthorized` on `uploadProfileImage`) almost always mean the `users/{userId}/…` block is missing from Storage rules.

### Step 3: Confirm Firestore allows creates

1. Go to **Build** → **Firestore Database** → **Rules**.
2. Ensure the `listings` rule allows **create** when `request.resource.data.landlordId == request.auth.uid` (see **Section 4** and your repo’s `firestore.rules`).

### Step 4: Test without photos

1. In the app, fill the listing form but **do not add any images** (leave the image area empty).
2. Tap **Verify Listing**.  
   - If it **succeeds**, the problem is likely image upload (Storage rules, bucket, or network).  
   - If it **still times out**, the issue may be Firestore write or general network/connectivity.

### Step 5: Network and device

- Use **Wi‑Fi** or a stable connection; avoid very slow or restricted networks.
- On **emulator**: ensure it can reach the internet; try on a real device if possible.
- **Firewall/VPN**: ensure Firebase (e.g. `*.googleapis.com`, `*.firebaseio.com`) is not blocked.

### Step 6: Retry with one small photo

After Storage is enabled and rules are published, try again with **one small photo** (e.g. &lt; 1 MB). Large images take longer to upload and can hit timeouts.

---

## 8. Firestore index (published + pending listings)

For the Expat app’s published listings stream **and** the Super Admin dashboard’s pending‑verification table, create a composite index in Firestore:

- Collection: `listings`
- Fields: `status` (Ascending), `createdAt` (Descending)

Firebase Console will prompt with a link when either query runs if the index is missing; you can click the link to create it.

## 9. Super Admin web dashboard (`admin-web/`)

The `admin-web/` directory contains a Vite + React dashboard used by the **Super Admin** to approve/reject listings and (later) manage edit requests.

### 9.1 Install dependencies

From the project root:

```bash
cd admin-web
npm install
```

Firebase is already added as a dependency in `admin-web/package.json`.

### 9.2 Configure Firebase for the dashboard

1. In Firebase Console, go to **Project settings → Your apps** and either reuse your existing Web app or create a new one.
2. Copy the Web app config (`apiKey`, `authDomain`, etc.).
3. In `admin-web/`, create a file named `.env.local` (not committed to git) with:

```bash
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
```

The React app reads these values in `src/firebase.ts` when initializing Firebase.

### 9.3 Super Admin user and role

1. In **Authentication → Users**, create a user for the admin dashboard (email/password).
2. In **Firestore → Data**, add (or update) `users/{uid}` for that user with:

```json
{
  "email": "admin@example.com",
  "role": "super_admin"
}
```

The admin login page (`LoginPage.tsx`) signs in with Firebase Auth and checks that `role == "super_admin"` before allowing access.

### 9.4 Firestore access and rules

- The dashboard reads listings from the `listings` collection where `status == "pending_verification"` and writes updates to change `status` to `published` (approve) or `archived` (reject).
- Firestore rules (see `firestore.rules`) define:
  - `isSuperAdmin()`: checks that the signed‑in user’s profile has `role == "super_admin"`.
  - Listings read/write permissions that allow Super Admins to read and update any listing, while keeping landlords restricted to their own documents.

After editing rules, deploy them from the repo root:

```bash
firebase deploy --only firestore:rules
```

## 10. Next steps (from BACKEND_CHECKLIST)

After auth and listings are working:

1. **Super Admin** — Approve/reject listings (set `status` to `published`), edit requests, revisions.
2. **Agents & assignments** — `licensed_agents` (or seed), `listing_assignments`.
3. **Conversations & messages** — `conversations`, `conversation_participants`, `messages`.
4. **Community** — posts, comments, bowls.
5. **Payments** — commission_slips.

See `docs/BACKEND_CHECKLIST.md` and `docs/BACKEND_IMPLEMENTATION_PLAN.md` for the full plan.
