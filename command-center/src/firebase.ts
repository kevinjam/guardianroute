import { initializeApp } from "firebase/app";
import {
  connectAuthEmulator,
  getAuth,
  GoogleAuthProvider,
  signInAnonymously,
  signInWithPopup,
  signOut,
  type User,
} from "firebase/auth";
import {
  connectFirestoreEmulator,
  doc,
  GeoPoint,
  getFirestore,
  serverTimestamp,
  writeBatch,
} from "firebase/firestore";
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from "firebase/functions";
import { firebaseConfig, useEmulators } from "./config";
import {
  kampalaDemoHazards,
  kampalaDemoPulses,
  kampalaDemoRoadSegments,
} from "./demoData";
import type { DashboardMetrics } from "./types";

const app = initializeApp(firebaseConfig());

export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app, "europe-west1");

if (useEmulators()) {
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  connectFirestoreEmulator(db, "127.0.0.1", 8080);
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
}

const googleProvider = new GoogleAuthProvider();

export async function signInWithGoogle(): Promise<User> {
  const result = await signInWithPopup(auth, googleProvider);
  return result.user;
}

export async function signInGuest(): Promise<User> {
  const result = await signInAnonymously(auth);
  return result.user;
}

export async function signOutUser(): Promise<void> {
  await signOut(auth);
}

export async function fetchDashboardMetrics(): Promise<DashboardMetrics> {
  const callable = httpsCallable<void, DashboardMetrics>(
    functions,
    "getCommandCentreMetrics",
  );
  const result = await callable();
  return result.data;
}

export async function seedFirestoreDemoData(): Promise<void> {
  const batch = writeBatch(db);
  const now = serverTimestamp();

  for (const h of kampalaDemoHazards()) {
    batch.set(doc(db, "hazards", h.id), {
      publicId: h.publicId,
      type: h.type,
      severity: h.severity,
      status: h.status,
      confidence: h.confidence,
      location: new GeoPoint(h.location.lat, h.location.lng),
      geohash: "s8p1x9",
      description: h.description,
      recommendedAction: "Slow down and keep left.",
      reportCount: 3,
      confirmationCount: 2,
      sensorEvidenceCount: 5,
      createdAt: now,
      updatedAt: now,
    });
  }

  for (const p of kampalaDemoPulses()) {
    batch.set(doc(db, "guardianPulseEvents", p.id), {
      status: p.status,
      confidence: p.confidence,
      eventCount: p.eventCount,
      dominantEventType: p.dominantEventType,
      geohashCell: "s8p1x9k",
      location: new GeoPoint(p.location.lat, p.location.lng),
      radiusMeters: p.radiusMeters,
      createdAt: now,
      updatedAt: now,
    });
  }

  for (const s of kampalaDemoRoadSegments()) {
    batch.set(doc(db, "roadSegments", s.id), {
      geohash: s.geohash,
      riskScore: s.riskScore,
      riskLevel: s.riskLevel,
      location: new GeoPoint(s.location.lat, s.location.lng),
      updatedAt: now,
    });
  }

  await batch.commit();
}
