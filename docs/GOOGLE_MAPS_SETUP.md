# Google Maps & Places (Expat app)

## Android

1. **API key** (do not commit keys to git)  
   Add to `expat_app/android/local.properties` (this file is gitignored):

   ```properties
   GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
   ```

   The Gradle build injects this into:

   - `AndroidManifest` → `com.google.android.geo.API_KEY` (Maps SDK)
   - `BuildConfig.MAPS_API_KEY` (read by Flutter via `MethodChannel` for Places + Directions REST)

2. **Google Cloud Console**

   - Enable **Maps SDK for Android**
   - Enable **Places API** (legacy Places used: Autocomplete + Place Details JSON)
   - Enable **Directions API** (Rides: driving routes / polylines)
   - Enable **Geocoding API** (Rides: “From: …” label from GPS)
   - Enable **billing** on the project (Google requirement for Maps/Places)
   - **Restrict** the key:
     - **API restrictions:** include **Geocoding API** as well (Rides uses forward/reverse geocode over HTTP).
     - **Application restrictions:** keys restricted to **Android apps** work for the **Maps SDK** in the manifest, but **REST** calls from Dart (`http`) to Directions / Places / Geocoding do **not** send the same app attestation. If you see `REQUEST_DENIED` on routes despite enabling APIs, either:
       - add a second key used only for REST (API-restricted, **no** Android app restriction) via `--dart-define=GOOGLE_MAPS_API_KEY=...`, or  
       - temporarily use **None** under application restrictions while testing, then tighten carefully.

3. **Rebuild** after changing the key:

   ```bash
   cd expat_app
   flutter clean
   flutter pub get
   flutter run
   ```

## iOS (optional)

Maps on iOS needs a separate Maps SDK key in `AppDelegate` / `Info.plist`. This project is wired for Android first; add iOS when you target the App Store.

## Places from Dart without Android channel

You can pass the key at compile time (e.g. CI):

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

If set, it overrides the Android channel for Places HTTP calls.

## Security

If a key was shared in chat or committed by mistake, **rotate it** in Google Cloud Console and update `local.properties` only on trusted machines.

## Troubleshooting

### Rides: `ZERO_RESULTS` with From showing `37.42…, -122.08…`

The Android emulator’s **default mock location** is near Google’s campus (California). If **To** is in Rwanda (or anywhere far away), the Directions API correctly returns **no driving route**. Fix: **Emulator → ⋮ → Location** (or Extended controls) and set a point near your test destination, or type a **From** address in the app instead of relying on GPS.

### Crash: `ClassNotFoundException: org.apache.http.ProtocolVersion` (Maps / MapsDynamite)

The manifest includes `<uses-library android:name="org.apache.http.legacy" android:required="false" />` so the Maps stack can resolve legacy Apache HTTP classes that are no longer on the default app classpath on newer Android APIs.

If you still see this after a clean build, run `flutter clean` then rebuild.
