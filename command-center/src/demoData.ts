import type { HazardRecord, PulseRecord, RoadSegmentRecord } from "./types";
import { KAMPALA_CENTER } from "./config";

export function kampalaDemoHazards(): HazardRecord[] {
  const { lat, lng } = KAMPALA_CENTER;
  return [
    {
      id: "demo-1",
      publicId: "GR-D01",
      type: "POTHOLE",
      severity: "HIGH",
      status: "ACTIVE",
      confidence: 0.94,
      location: { lat: lat + 0.008, lng: lng + 0.012 },
      description: "Large pothole affecting the motorcycle travel path.",
      isDemo: true,
    },
    {
      id: "demo-2",
      publicId: "GR-D02",
      type: "ROAD_DAMAGE",
      severity: "MODERATE",
      status: "ACTIVE",
      confidence: 0.78,
      location: { lat: lat - 0.006, lng: lng - 0.009 },
      description: "Uneven road surface near junction.",
      isDemo: true,
    },
    {
      id: "demo-3",
      publicId: "GR-D03",
      type: "DANGEROUS_INTERSECTION",
      severity: "CRITICAL",
      status: "VERIFIED",
      confidence: 0.88,
      location: { lat: lat + 0.004, lng: lng - 0.015 },
      description: "Poor visibility and heavy merging traffic.",
      isDemo: true,
    },
  ];
}

export function kampalaDemoPulses(): PulseRecord[] {
  const { lat, lng } = KAMPALA_CENTER;
  return [
    {
      id: "demo-pulse-1",
      status: "EMERGING",
      confidence: 0.86,
      eventCount: 38,
      dominantEventType: "VERTICAL_SHOCK",
      location: { lat: lat + 0.007, lng: lng + 0.01 },
      radiusMeters: 140,
    },
  ];
}

export function kampalaDemoRoadSegments(): RoadSegmentRecord[] {
  const { lat, lng } = KAMPALA_CENTER;
  return [
    {
      id: "demo-seg-high",
      geohash: "s8p1x9k",
      riskScore: 78,
      riskLevel: "HIGH",
      location: { lat: lat + 0.008, lng: lng + 0.012 },
    },
    {
      id: "demo-seg-mod",
      geohash: "s8p1x2m",
      riskScore: 44,
      riskLevel: "MODERATE",
      location: { lat: lat - 0.005, lng: lng - 0.008 },
    },
  ];
}
