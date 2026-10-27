import { useEffect, useState } from "react";
import { APIProvider, Map, AdvancedMarker, Pin, Circle } from "@vis.gl/react-google-maps";
import type { HazardRecord, PulseRecord, RoadSegmentRecord } from "../types";
import { KAMPALA_CENTER, DEFAULT_MAP_ZOOM, mapsApiKey } from "../config";
import { riskScoreColor, severityColor } from "../utils/colors";

interface CommandMapProps {
  hazards: HazardRecord[];
  pulses: PulseRecord[];
  segments: RoadSegmentRecord[];
}

export function CommandMap({ hazards, pulses, segments }: CommandMapProps) {
  const apiKey = mapsApiKey();
  const [useFallbackMap, setUseFallbackMap] = useState(!apiKey);

  useEffect(() => {
    const win = window as Window & { gm_authFailure?: () => void };
    const prev = win.gm_authFailure;
    win.gm_authFailure = () => {
      setUseFallbackMap(true);
      prev?.();
    };
    return () => {
      win.gm_authFailure = prev;
    };
  }, []);

  if (!apiKey || useFallbackMap) {
    return (
      <FreeSparkMap hazards={hazards} pulses={pulses} segments={segments} />
    );
  }

  return (
    <APIProvider apiKey={apiKey} onError={() => setUseFallbackMap(true)}>
      <Map
        className="command-map"
        defaultCenter={KAMPALA_CENTER}
        defaultZoom={DEFAULT_MAP_ZOOM}
        gestureHandling="greedy"
        mapId="DEMO_MAP_ID"
        disableDefaultUI={false}
      >
        {segments.map((segment) => (
          <Circle
            key={segment.id}
            center={segment.location}
            radius={Math.max(35, 20 + segment.riskScore * 0.4)}
            strokeColor={riskScoreColor(segment.riskScore)}
            strokeOpacity={0.85}
            strokeWeight={2}
            fillColor={riskScoreColor(segment.riskScore)}
            fillOpacity={0.2}
          />
        ))}
        {pulses.map((pulse) => (
          <Circle
            key={pulse.id}
            center={pulse.location}
            radius={pulse.radiusMeters}
            strokeColor="#7c4dff"
            strokeOpacity={0.9}
            strokeWeight={2}
            fillColor="#7c4dff"
            fillOpacity={0.15}
          />
        ))}
        {hazards.map((hazard) => (
          <AdvancedMarker
            key={hazard.id}
            position={hazard.location}
            title={hazard.type}
          >
            <Pin
              background={severityColor(hazard.severity)}
              borderColor="#1a1a1a"
              glyphColor="#fff"
            />
          </AdvancedMarker>
        ))}
      </Map>
    </APIProvider>
  );
}

function FreeSparkMap({ hazards, pulses, segments }: CommandMapProps) {
  const [selectedHazard, setSelectedHazard] = useState<HazardRecord | null>(
    hazards[0] ?? null,
  );

  const minLat = KAMPALA_CENTER.lat - 0.02;
  const maxLat = KAMPALA_CENTER.lat + 0.02;
  const minLng = KAMPALA_CENTER.lng - 0.025;
  const maxLng = KAMPALA_CENTER.lng + 0.025;

  function toPercent(lat: number, lng: number) {
    const x = ((lng - minLng) / (maxLng - minLng)) * 100;
    const y = ((maxLat - lat) / (maxLat - minLat)) * 100;
    return {
      left: `${Math.min(92, Math.max(8, x))}%`,
      top: `${Math.min(92, Math.max(8, y))}%`,
    };
  }

  const bbox = `${minLng},${minLat},${maxLng},${maxLat}`;
  const osmUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${encodeURIComponent(bbox)}&layer=mapnik`;

  return (
    <div
      className="command-map"
      style={{
        position: "relative",
        overflow: "hidden",
        background: "#0f191d",
      }}
    >
      <iframe
        title="Kampala OpenStreetMap"
        src={osmUrl}
        style={{
          width: "100%",
          height: "100%",
          border: 0,
          filter: "invert(90%) hue-rotate(180deg) brightness(95%) contrast(90%)",
          pointerEvents: "auto",
        }}
      />

      <div
        style={{
          position: "absolute",
          inset: 0,
          pointerEvents: "none",
        }}
      >
        {segments.map((seg) => {
          const pos = toPercent(seg.location.lat, seg.location.lng);
          const color = riskScoreColor(seg.riskScore);
          return (
            <div
              key={seg.id}
              style={{
                position: "absolute",
                left: pos.left,
                top: pos.top,
                transform: "translate(-50%, -50%)",
                width: "84px",
                height: "84px",
                borderRadius: "50%",
                border: `2px solid ${color}`,
                background: `${color}33`,
              }}
            />
          );
        })}

        {pulses.map((pulse) => {
          const pos = toPercent(pulse.location.lat, pulse.location.lng);
          return (
            <div
              key={pulse.id}
              style={{
                position: "absolute",
                left: pos.left,
                top: pos.top,
                transform: "translate(-50%, -50%)",
                width: "110px",
                height: "110px",
                borderRadius: "50%",
                border: "2px dashed #7c4dff",
                background: "rgba(124, 77, 255, 0.18)",
              }}
            />
          );
        })}

        {hazards.map((hazard) => {
          const pos = toPercent(hazard.location.lat, hazard.location.lng);
          const color = severityColor(hazard.severity);
          return (
            <button
              key={hazard.id}
              type="button"
              onClick={() => setSelectedHazard(hazard)}
              style={{
                position: "absolute",
                left: pos.left,
                top: pos.top,
                transform: "translate(-50%, -50%)",
                pointerEvents: "auto",
                background: color,
                color: "#fff",
                border: "2px solid #0b1214",
                borderRadius: "999px",
                padding: "0.28rem 0.6rem",
                fontSize: "0.72rem",
                fontWeight: 700,
                cursor: "pointer",
                boxShadow: "0 4px 14px rgba(0,0,0,0.5)",
              }}
            >
              {hazard.publicId} · {hazard.type.replace(/_/g, " ")}
            </button>
          );
        })}
      </div>

      {selectedHazard && (
        <div
          style={{
            position: "absolute",
            top: "12px",
            left: "12px",
            maxWidth: "320px",
            background: "rgba(18, 28, 31, 0.94)",
            border: "1px solid rgba(255,255,255,0.12)",
            borderRadius: "12px",
            padding: "0.75rem 0.9rem",
            boxShadow: "0 8px 24px rgba(0,0,0,0.45)",
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              gap: "0.5rem",
            }}
          >
            <strong style={{ fontSize: "0.85rem" }}>
              {selectedHazard.publicId} —{" "}
              {selectedHazard.type.replace(/_/g, " ")}
            </strong>
            <button
              type="button"
              className="btn-ghost"
              style={{ padding: "0.15rem 0.45rem", fontSize: "0.7rem" }}
              onClick={() => setSelectedHazard(null)}
            >
              ✕
            </button>
          </div>
          <p
            style={{
              margin: "0.35rem 0",
              fontSize: "0.78rem",
              color: "#8aa3a8",
            }}
          >
            {selectedHazard.description}
          </p>
          <span
            style={{
              fontSize: "0.7rem",
              fontWeight: 700,
              color: severityColor(selectedHazard.severity),
            }}
          >
            {selectedHazard.severity} SEVERITY ·{" "}
            {Math.round(selectedHazard.confidence * 100)}% CONFIDENCE
          </span>
        </div>
      )}
    </div>
  );
}
