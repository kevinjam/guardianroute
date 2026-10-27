import { useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  query,
  where,
  orderBy,
  limit,
  type GeoPoint,
  type Timestamp,
} from "firebase/firestore";
import { db } from "../firebase";
import { demoOverlayEnabled } from "../config";
import {
  kampalaDemoHazards,
  kampalaDemoPulses,
  kampalaDemoRoadSegments,
} from "../demoData";
import type {
  DashboardMetrics,
  HazardRecord,
  PulseRecord,
  RoadSegmentRecord,
} from "../types";

const ACTIVE_HAZARD_STATUSES = ["ACTIVE", "VERIFIED", "REPORTED", "DETECTED"];

function geoToLatLng(location: unknown): { lat: number; lng: number } | null {
  if (!location) return null;
  if (typeof location === "object" && "latitude" in location) {
    const gp = location as GeoPoint;
    return { lat: gp.latitude, lng: gp.longitude };
  }
  return null;
}

function tsToDate(value: unknown): Date | undefined {
  if (value && typeof value === "object" && "toDate" in value) {
    return (value as Timestamp).toDate();
  }
  return undefined;
}

export function useLiveHazards() {
  const [hazards, setHazards] = useState<HazardRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "hazards"),
      where("status", "in", ACTIVE_HAZARD_STATUSES),
      limit(150),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: HazardRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            publicId: (data.publicId as string) ?? doc.id,
            type: (data.type as string) ?? "OTHER",
            severity: (data.severity as string) ?? "MODERATE",
            status: (data.status as string) ?? "ACTIVE",
            confidence: (data.confidence as number) ?? 0.5,
            location,
            description: (data.description as string) ?? "Road hazard",
            updatedAt: tsToDate(data.updatedAt),
          });
        });
        if (rows.length === 0 && demoOverlayEnabled()) {
          setHazards(kampalaDemoHazards());
        } else {
          setHazards(rows);
        }
        setLoading(false);
        setError(null);
      },
      (err) => {
        setError(err.message);
        if (demoOverlayEnabled()) {
          setHazards(kampalaDemoHazards());
        }
        setLoading(false);
      },
    );

    return () => unsub();
  }, []);

  return { hazards, loading, error };
}

export function useLivePulses() {
  const [pulses, setPulses] = useState<PulseRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "guardianPulseEvents"),
      where("status", "in", ["EMERGING", "ACTIVE"]),
      orderBy("updatedAt", "desc"),
      limit(40),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: PulseRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            status: (data.status as string) ?? "ACTIVE",
            confidence: (data.confidence as number) ?? 0.5,
            eventCount: (data.eventCount as number) ?? 0,
            dominantEventType: (data.dominantEventType as string) ?? "UNKNOWN",
            location,
            radiusMeters: (data.radiusMeters as number) ?? 40,
          });
        });
        if (rows.length === 0 && demoOverlayEnabled()) {
          setPulses(kampalaDemoPulses());
        } else {
          setPulses(rows);
        }
      },
      () => {
        if (demoOverlayEnabled()) {
          setPulses(kampalaDemoPulses());
        }
      },
    );

    return () => unsub();
  }, []);

  return pulses;
}

export function useLiveRoadRisk() {
  const [segments, setSegments] = useState<RoadSegmentRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "roadSegments"),
      where("riskScore", ">=", 26),
      orderBy("riskScore", "desc"),
      limit(80),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: RoadSegmentRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            geohash: (data.geohash as string) ?? doc.id,
            riskScore: (data.riskScore as number) ?? 0,
            riskLevel: (data.riskLevel as string) ?? "LOW",
            location,
          });
        });
        if (rows.length === 0 && demoOverlayEnabled()) {
          setSegments(kampalaDemoRoadSegments());
        } else {
          setSegments(rows);
        }
      },
      () => {
        if (demoOverlayEnabled()) {
          setSegments(kampalaDemoRoadSegments());
        }
      },
    );

    return () => unsub();
  }, []);

  return segments;
}

export function useRecentResolvedHazards() {
  const [resolved, setResolved] = useState<HazardRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "hazards"),
      where("status", "in", ["RESOLVED", "STALE"]),
      orderBy("updatedAt", "desc"),
      limit(12),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: HazardRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            publicId: (data.publicId as string) ?? doc.id,
            type: (data.type as string) ?? "OTHER",
            severity: (data.severity as string) ?? "MODERATE",
            status: (data.status as string) ?? "RESOLVED",
            confidence: (data.confidence as number) ?? 0.5,
            location,
            description: (data.description as string) ?? "",
            updatedAt: tsToDate(data.updatedAt),
          });
        });
        setResolved(rows);
      },
      () => setResolved([]),
    );

    return () => unsub();
  }, []);

  return resolved;
}

export function computeClientMetrics(
  hazards: HazardRecord[],
  resolved: HazardRecord[],
  pulses: PulseRecord[],
  segments: RoadSegmentRecord[],
): DashboardMetrics {
  const dist = { low: 0, moderate: 0, high: 0, critical: 0 };
  for (const h of hazards) {
    const s = h.severity.toUpperCase();
    if (s === "CRITICAL") dist.critical += 1;
    else if (s === "HIGH") dist.high += 1;
    else if (s === "LOW") dist.low += 1;
    else dist.moderate += 1;
  }

  const sensorEvents = pulses.reduce((acc, p) => acc + p.eventCount, 0);
  const highRiskAreas = segments.filter((s) => s.riskScore >= 76).length;
  const elevatedRiskAreas = segments.filter((s) => s.riskScore >= 50).length;

  return {
    activeHazards: hazards.length,
    resolvedHazards: resolved.length,
    hazardsCreatedToday: hazards.length,
    reportsToday: hazards.length,
    guardianPulseActive: pulses.length,
    sensorEventsLast24h: sensorEvents,
    highRiskAreas,
    elevatedRiskAreas,
    roadSegmentsTracked: segments.length,
    hazardSeverityDistribution: dist,
    generatedAt: new Date().toISOString(),
  };
}
