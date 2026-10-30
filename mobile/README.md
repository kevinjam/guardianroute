# GuardianRoute — Mobile app

Flutter client for **Pre-DevFest Hackathon Kampala 2026**. Product overview, demo script, and repo layout: **[../README.md](../README.md)**.

## Flavors

| Flavor | Use |
|--------|-----|
| `development` | Daily dev + Firebase emulators |
| `demo` | Stable demo builds |
| `production` | Release-style config |

```bash
flutter run --flavor development --dart-define=FLAVOR=development
```

iOS uses Xcode schemes `development`, `demo`, `production` (same names).

## Firebase emulators

From repo root, start emulators first (see root README). Then:

```bash
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key
```

Emulator host defaults: **Android emulator** → `10.0.2.2`; **iOS / macOS** → `127.0.0.1`. Override with `--dart-define=FIREBASE_EMULATOR_HOST=...`.

Firestore persistence is **off** when emulators are enabled (see `lib/app/bootstrap.dart`).

## Google Maps keys

| Platform | Config |
|----------|--------|
| Android | `android/local.properties` → `MAPS_API_KEY=` |
| iOS | `ios/Flutter/MapsKeys.xcconfig` (copy from `MapsKeys.xcconfig.example`; gitignored) |
| Dart (Places, etc.) | `--dart-define=GOOGLE_MAPS_API_KEY=...` on `flutter run` |

Enable **Maps SDK for Android**, **Maps SDK for iOS**, and **Places API** (and related) in Google Cloud for the same project as Firebase.

After editing **iOS** `MapsKeys.xcconfig` or `Debug.xcconfig` / `Release.xcconfig`:

```bash
flutter clean && flutter pub get
```

Then run again (not hot reload). More: [docs/architecture/GOOGLE_MAPS.md](../docs/architecture/GOOGLE_MAPS.md).

## Firebase project wiring

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # select guardianangel-30dd6 or your team project
```

CocoaPods / iOS notes: [docs/mobile/FIREBASE_PROJECT.md](../docs/mobile/FIREBASE_PROJECT.md).

## App icon

Source: `assets/branding/app_icon.png`. Regenerate platform icons:

```bash
dart run flutter_launcher_icons
```

## Tests

```bash
flutter analyze
flutter test
```

## Stuck iOS build?

```bash
../scripts/ios-stop-builds.sh
```
