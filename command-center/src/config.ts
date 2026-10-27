export const KAMPALA_CENTER = { lat: 0.3136, lng: 32.5811 };
export const DEFAULT_MAP_ZOOM = 12;

export function demoOverlayEnabled(): boolean {
  return import.meta.env.VITE_DEMO_OVERLAY !== "false";
}

export function useEmulators(): boolean {
  return import.meta.env.VITE_USE_FIREBASE_EMULATORS === "true";
}

export function mapsApiKey(): string {
  const raw = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY ?? "").trim();
  return !raw || raw.startsWith("PASTE_YOUR_") || raw.startsWith("YOUR_") ? "" : raw;
}

export function firebaseConfig() {
  return {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
  };
}
