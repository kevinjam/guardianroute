# Firebase Emulator Suite

## Start emulators

From the repository root:

```bash
firebase emulators:start
```

Default ports (see `firebase.json`):

| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Storage | 9199 |
| Emulator UI | 4000 |

## Flutter app

**Android emulator** uses `10.0.2.2` as the host loopback (automatic when `USE_FIREBASE_EMULATORS=true`).

**iOS Simulator** uses `127.0.0.1` automatically. Do not use `10.0.2.2` on iOS.

**Physical device** (Android or iPhone on Wi‑Fi): use your Mac’s LAN IP:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=FIREBASE_EMULATOR_HOST=192.168.x.x
```

**iOS Maps:** copy `ios/Flutter/MapsKeys.xcconfig.example` → `MapsKeys.xcconfig` and set `MAPS_API_KEY` (Maps SDK for iOS). An empty key often crashes the app when the map loads.

## Functions

```bash
cd functions
npm install
npm run build
```

Deploy is not required for emulator testing when the Functions emulator loads compiled `lib/`.
