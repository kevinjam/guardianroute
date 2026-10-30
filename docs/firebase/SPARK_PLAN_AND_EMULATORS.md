# No Blaze / no payment card

Project example: `guardianangel-30dd6`.

## What Firebase allows on Spark (no billing)

| Service | Deploy to cloud? | Notes |
|---------|----------------|--------|
| **Firestore** (rules, indexes, data) | Often yes | Spark quotas apply; rules/index deploy usually works |
| **Hosting** | Yes | Static Command Centre build; generous free tier |
| **Authentication** | Yes | Google + anonymous in console |
| **Cloud Functions** | **No** | Requires **Blaze**; enables Cloud Build, Artifact Registry, etc. |
| **Cloud Storage** | Often blocked or limited | Many teams hit “upgrade” when enabling Storage without billing |

Error you may see for Functions:

```text
Your project must be on the Blaze (pay-as-you-go) plan ...
Required API cloudbuild.googleapis.com can't be enabled until the upgrade is complete.
```

There is **no supported way** to host this repo’s Cloud Functions on Firebase without attaching a billing account. Blaze still has a **free tier** for Functions/Firestore, but Google requires a card on file.

Upgrade (when you have a card): [Firebase usage / billing](https://console.firebase.google.com/project/guardianangel-30dd6/usage/details).

## What still works without deploying Functions

The **mobile app** can use:

- **Firestore + Auth + Hosting** in the cloud (if you deployed rules/indexes/hosting)
- **Demo hazards** on the map when Firestore is empty (development/demo flavors)
- Features that **only** need client + Firestore: map, markers, reporting UI (reports stay `PENDING` without `analyzeHazardReport`)

These **need Functions** (deployed or emulated):

- Gemini hazard analysis (`analyzeHazardReport`)
- `planSafeRoutes`, sensor upload, Guardian Pulse jobs, road risk schedulers, Command Centre metrics

## Recommended path: Emulator Suite (no card)

Run the full backend on your laptop:

```bash



```

Flutter (Android emulator → host):

```bash
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

Command Centre:

```bash
cd command-center
# .env: Firebase web config; VITE_USE_FIREBASE_EMULATORS=true
npm run dev
```

Emulator UI: http://localhost:4000

Hazard photos in emulators use the **Storage emulator** (no cloud Storage billing).

## Deploy commands that match “no Storage, no Functions”

```bash
firebase use guardianangel-30dd6
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only hosting
```

Skip `storage` and `functions` until Blaze + Storage are enabled.

## When you can add billing later

1. [Upgrade to Blaze](https://console.firebase.google.com/project/guardianangel-30dd6/usage/details)
2. Enable **Storage** in console if you need cloud photo uploads
3. `firebase deploy --only storage`
4. `cd functions && cp .env.example .env` → fill keys → `firebase deploy --only functions`
5. Re-link mobile (`flutterfire configure`) and Command Centre `.env` to `guardianangel-30dd6`

## Hackathon demo tip

Judges often accept **one laptop** running emulators + a phone/emulator on the same Wi‑Fi (`FIREBASE_EMULATOR_HOST`). You get Gemini, routing, and pulses without cloud Functions deploy.
