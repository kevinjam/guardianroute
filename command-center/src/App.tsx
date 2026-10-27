import { useEffect, useState } from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import {
  auth,
  fetchDashboardMetrics,
  seedFirestoreDemoData,
  signOutUser,
} from "./firebase";
import { LoginScreen } from "./components/LoginScreen";
import { CommandMap } from "./components/CommandMap";
import { StatsPanel } from "./components/StatsPanel";
import { HazardLists } from "./components/HazardLists";
import {
  computeClientMetrics,
  useLiveHazards,
  useLivePulses,
  useLiveRoadRisk,
  useRecentResolvedHazards,
} from "./hooks/useLiveData";
import type { DashboardMetrics } from "./types";
import { demoOverlayEnabled } from "./config";

export default function App() {
  const [user, setUser] = useState<User | null | undefined>(undefined);
  const [demoOperator, setDemoOperator] = useState(false);
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(false);
  const [seeding, setSeeding] = useState(false);

  const { hazards, loading: hazardsLoading } = useLiveHazards();
  const pulses = useLivePulses();
  const segments = useLiveRoadRisk();
  const resolved = useRecentResolvedHazards();

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      if (u) setDemoOperator(false);
    });
  }, []);

  useEffect(() => {
    if (!user) {
      setMetrics(null);
      return;
    }

    let cancelled = false;

    async function load() {
      setMetricsLoading(true);
      try {
        const data = await fetchDashboardMetrics();
        if (!cancelled) setMetrics(data);
      } catch {
        if (!cancelled) setMetrics(null);
      } finally {
        if (!cancelled) setMetricsLoading(false);
      }
    }

    load();
    const interval = setInterval(load, 60_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [user]);

  if (user === undefined) {
    return <div className="app-loading">Loading…</div>;
  }

  if (!user && !demoOperator) {
    return <LoginScreen onDemoLogin={() => setDemoOperator(true)} />;
  }

  const effectiveMetrics =
    metrics ?? computeClientMetrics(hazards, resolved, pulses, segments);

  async function handleSeed() {
    if (!user) return;
    setSeeding(true);
    try {
      await seedFirestoreDemoData();
    } catch {
      // Ignore if rules/auth not ready
    } finally {
      setSeeding(false);
    }
  }

  return (
    <div className="app-shell">
      <header className="top-bar">
        <div>
          <p className="top-eyebrow">GuardianRoute</p>
          <h1>Road Safety Command Centre</h1>
        </div>
        <div className="top-actions">
          {demoOverlayEnabled() && hazards.some((h) => h.isDemo) && (
            <span className="demo-pill">Spark / Demo overlay</span>
          )}
          {user && hazards.some((h) => h.isDemo) && (
            <button
              type="button"
              className="btn-ghost"
              onClick={handleSeed}
              disabled={seeding}
            >
              {seeding ? "Seeding…" : "Seed Live Firestore"}
            </button>
          )}
          <span className="user-email">
            {user
              ? user.email ?? (user.isAnonymous ? "Guest Operator" : user.uid)
              : "Demo Operator"}
          </span>
          <button
            type="button"
            className="btn-ghost"
            onClick={() => {
              setDemoOperator(false);
              if (user) void signOutUser();
            }}
          >
            Sign out
          </button>
        </div>
      </header>

      <main className="dashboard">
        <div className="map-column">
          <CommandMap hazards={hazards} pulses={pulses} segments={segments} />
          {hazardsLoading && <p className="map-status">Syncing hazards…</p>}
        </div>
        <div className="side-column">
          <StatsPanel
            metrics={effectiveMetrics}
            metricsLoading={metricsLoading}
            liveActiveCount={hazards.length}
            pulseCount={pulses.length}
          />
          <HazardLists hazards={hazards} resolved={resolved} />
        </div>
      </main>

      <footer className="footer-note">
        Live map · hazards · Guardian Pulse™ · road risk · Firebase Spark
        (Firestore + Auth + Hosting).
      </footer>
    </div>
  );
}
