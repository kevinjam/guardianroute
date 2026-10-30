# Flutter app ↔ Firebase project

Current project: **`guardianangel-30dd6`** (aligned with root `.firebaserc`).

## Files that must match

| File | Purpose |
|------|---------|
| `mobile/lib/firebase_options.dart` | Dart `Firebase.initializeApp` options |
| `mobile/android/app/google-services.json` | Android Gradle / Google Services plugin |
| `mobile/ios/Runner/GoogleService-Info.plist` | iOS (after `flutterfire configure`) |
| `mobile/firebase.json` | FlutterFire CLI metadata (do not delete) |

## Switch to another Firebase project

From `mobile/`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios --yes
```

That regenerates `firebase_options.dart`, `google-services.json`, and iOS plist paths.

Then:

1. Root: `firebase use YOUR_PROJECT_ID` and update `.firebaserc`
2. Firebase console: enable **Authentication** (Google + Anonymous), **Firestore**
3. Add **SHA-1** debug key to the Android app (Google Sign-In + optional API restrictions)
4. **App Check**: register app; add debug token for debug builds
5. `command-center/.env` — same web config values as in console

## Run against cloud (no emulators)

**Android** (product flavors in Gradle):

```bash
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key
```

**iOS** uses Xcode schemes `development`, `demo`, and `production` (same names as `--flavor`). You still need `--dart-define=FLAVOR=...` for app logic:

```bash
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key
```

For Maps on iOS, set `MAPS_API_KEY` in `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`, or pass via Xcode build settings (see `Runner/Info.plist` → `GMSApiKey`).

### CocoaPods / Firebase iOS SDK

If `pod install` fails on `FirebaseAnalytics (= 12.19.3)`, the Flutter pin may be ahead of CocoaPods trunk. The repo **`ios/Podfile`** sets `$FirebaseSDKVersion = '12.19.0'` (latest published pod).

Use **`pod install` only** — avoid `pod install --repo-update` unless you must; a full repo update can take many minutes.

```bash
cd mobile && flutter pub get && cd ios && pod install
```

### “Xcode build failed due to concurrent builds”

Only **one** `flutter run` / `xcodebuild` should run at a time (including builds started from Cursor, Xcode, or another terminal).

```bash
# From repo root
./scripts/ios-stop-builds.sh
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

If it keeps happening: quit **Xcode**, close extra simulators, then run the script again. The first iOS build after `pod install` can take several minutes — that is normal; concurrent-build retries are not.

Do **not** pass `USE_FIREBASE_EMULATORS=true` when using production Firestore.

## Run against emulators

See [docs/firebase/EMULATORS.md](../firebase/EMULATORS.md).

## Storage note

Hazard photo upload needs **Firebase Storage** enabled on the project. Without billing/Storage, use emulators for the full report flow or test map/auth/Firestore-only features.
