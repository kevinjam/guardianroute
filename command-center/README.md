# GuardianRoute — Command Centre

Web dashboard for **Pre-DevFest Hackathon Kampala 2026** demos: **live map**, **hazards**, **Guardian Pulse™**, **road risk**, and **server-side analytics** (including sensor events not exposed in Firestore client rules).

Project overview and emulator workflow: **[../README.md](../README.md)**.

## Stack

- Vite + React + TypeScript
- Firebase Auth (Google) + Firestore listeners
- Callable `getCommandCentreMetrics` (Cloud Functions)
- Google Maps (`@vis.gl/react-google-maps`)

## Setup

1. Copy env file:

   ```bash
   cd command-center
   cp .env.example .env
   ```

2. Fill `.env` from Firebase console → Project settings → **Your apps** → Web app config (create a web app if needed). Use the same Firebase project as the Flutter app (`guardianangel-30dd6` for team dev).

3. Set `VITE_GOOGLE_MAPS_API_KEY` with **Maps JavaScript API** enabled.

4. Install and run:

   ```bash
   npm install
   npm run dev
   ```

5. Sign in with Google (same Firebase Auth as mobile). Firestore rules require authentication to read hazards, pulses, and road segments.

### Emulators (recommended for hackathon prep)

```bash
# Terminal 1 (repo root)
firebase emulators:start --import=./firebase/emulator-data --export-on-exit

# Terminal 2
cd command-center
VITE_USE_FIREBASE_EMULATORS=true npm run dev
```

## Build & deploy (Firebase Hosting)

```bash
cd command-center
npm run build
cd ..
firebase deploy --only hosting
```

Deploy **Functions** first so `getCommandCentreMetrics` is available (requires Blaze):

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Full runbook: [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](../docs/setup/ACCOUNTS_AND_DEPLOYMENT.md) and [docs/COMMAND_CENTRE.md](../docs/COMMAND_CENTRE.md).
