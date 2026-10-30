# GuardianRoute

**Navigate safer. Arrive safer.**

AI-powered road-safety intelligence for boda boda riders and motorists in Uganda — mobile app, cloud backend, and a web **Command Centre** for live ops during demos.

Built for **Pre-DevFest Hackathon Kampala 2026** with **Flutter**, **Firebase**, **Gemini**, and **Google Maps**.

| | |
|---|---|
| **Team** | HashTags |
| **Repository** | [github.com/kevinjam/guardianroute](https://github.com/kevinjam/guardianroute) |
| **Firebase project** | `guardianangel-30dd6` (shared dev; each teammate can clone configs locally — see setup doc) |

---

## What the app does (for judges & teammates)

1. **Map & hazards** — See community hazard reports on Google Maps; report new hazards with photo and location.
2. **Gemini analysis** — New reports are analyzed server-side; structured severity and guidance land in Firestore.
3. **Guardian Pulse™** — Lightweight “pulse” signals from the rider’s device to surface attention-worthy moments.
4. **Road risk** — Segments get risk scores from hazards, pulses, and heuristics.
5. **Safe routing & navigation** — Plan a safer route, start turn-by-turn-style guidance with voice prompts and proximity alerts.
6. **Command Centre (web)** — Operators sign in with Google, watch hazards, pulses, risk, and aggregated metrics on a live map (Firebase Hosting + callable metrics).

**Primary demo path:** sign in on mobile → map → report or view hazard → plan route → start navigation → open Command Centre in a browser to show the same data at scale.

---

## Repository layout

```text
guardianroute/
├── mobile/           # Flutter app (Android & iOS, flavor: development | demo | production)
├── functions/        # Cloud Functions (TypeScript) — Gemini, routing, metrics
├── firebase/         # Firestore rules, indexes, emulator seed data
├── command-center/   # Vite + React dashboard for demos
├── docs/             # Architecture, Maps, emulators, deployment
└── scripts/          # Helpers (e.g. stop stuck iOS builds)
```

---

## Quick start (new teammate)

**Goal:** run everything locally without paying for Cloud Functions deploy (Spark plan OK).

### 1. Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable 3.x)
- [Node.js](https://nodejs.org/) 20+
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools` then `firebase login`
- Android Studio and/or Xcode for simulators

### 2. Clone and install

```bash
git clone https://github.com/kevinjam/guardianroute.git
cd guardianroute

cd mobile && flutter pub get && cd ..
cd functions && npm install && cd ..
cd command-center && npm install && cd ..
```

### 3. Secrets (not in git)

Follow the checklist once per machine:

**[docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](docs/setup/ACCOUNTS_AND_DEPLOYMENT.md)**

Minimum for local demo:

| Secret | Where |
|--------|--------|
| FlutterFire / Firebase | `flutterfire configure` in `mobile/` (project `guardianangel-30dd6`) |
| Maps (Android) | `mobile/android/local.properties` → `MAPS_API_KEY=...` |
| Maps (iOS) | Copy `mobile/ios/Flutter/MapsKeys.xcconfig.example` → `MapsKeys.xcconfig` |
| Functions | `functions/.env` from `.env.example` (`GEMINI_API_KEY`, `GOOGLE_MAPS_API_KEY`) |
| Command Centre | `command-center/.env` from `.env.example` |

**No Blaze / no card?** Use emulators only: **[docs/firebase/SPARK_PLAN_AND_EMULATORS.md](docs/firebase/SPARK_PLAN_AND_EMULATORS.md)**

### 4. Terminal A — Firebase emulators (repo root)

```bash
firebase emulators:start --import=./firebase/emulator-data --export-on-exit
```

Default ports: Auth `9099`, Firestore `8080`, Functions `5001`, Storage `9199`.

### 5. Terminal B — Flutter app

```bash
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key
```

On **iOS simulator**, emulators use `127.0.0.1` by default. After changing iOS Maps xcconfig, run `flutter clean` then a full rebuild.

Details: **[mobile/README.md](mobile/README.md)**

### 6. Terminal C — Command Centre (optional)

```bash
cd command-center
cp .env.example .env   # if you have not already
VITE_USE_FIREBASE_EMULATORS=true npm run dev
```

Details: **[command-center/README.md](command-center/README.md)**

---

## Deploy (when you have Blaze)

```bash
# Rules, indexes, hosting (Spark OK for rules/hosting)
firebase deploy --only firestore,hosting

# Functions need Blaze + functions/.env or secrets
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Full steps: [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](docs/setup/ACCOUNTS_AND_DEPLOYMENT.md)

---

## Documentation

| Doc | Who it’s for |
|-----|----------------|
| [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](docs/setup/ACCOUNTS_AND_DEPLOYMENT.md) | First-time setup, keys, deploy |
| [docs/firebase/SPARK_PLAN_AND_EMULATORS.md](docs/firebase/SPARK_PLAN_AND_EMULATORS.md) | Hackathon / no-card workflow |
| [docs/mobile/FIREBASE_PROJECT.md](docs/mobile/FIREBASE_PROJECT.md) | FlutterFire, iOS pods, flavors |
| [docs/COMMAND_CENTRE.md](docs/COMMAND_CENTRE.md) | Dashboard architecture & Hosting |
| [docs/architecture/SYSTEM_ARCHITECTURE.md](docs/architecture/SYSTEM_ARCHITECTURE.md) | System diagram & modules |
| [docs/architecture/GOOGLE_MAPS.md](docs/architecture/GOOGLE_MAPS.md) | Maps / Places / Directions keys |
| [docs/firebase/EMULATORS.md](docs/firebase/EMULATORS.md) | Emulator ports & import/export |

---

## Tech stack

- **Mobile:** Flutter, Riverpod, go_router, Google Maps Flutter, geolocation, TTS
- **Backend:** Firebase Auth, Firestore, Storage, Cloud Functions (TypeScript), App Check, Analytics, Crashlytics, Remote Config
- **AI:** Gemini (hazard analysis in Functions)
- **Web:** Vite, React, Firebase Web SDK, `@vis.gl/react-google-maps`

---

## Quality checks

```bash
cd mobile && flutter analyze && flutter test
cd ../functions && npm test
```

---

## License & submission

Use this repo as the single source of truth for the hackathon submission. Keep API keys and `google-services.json` out of git (already gitignored). Update team name or links in this README if your DevFest registration differs.
