import { useState } from "react";
import { signInGuest, signInWithGoogle } from "../firebase";

interface LoginScreenProps {
  onDemoLogin: () => void;
}

export function LoginScreen({ onDemoLogin }: LoginScreenProps) {
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleGoogleSignIn() {
    setBusy(true);
    setError(null);
    try {
      await signInWithGoogle();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Google Sign-In failed");
    } finally {
      setBusy(false);
    }
  }

  async function handleGuestSignIn() {
    setBusy(true);
    setError(null);
    try {
      await signInGuest();
    } catch {
      onDemoLogin();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-screen">
      <div className="login-card">
        <p className="login-eyebrow">GuardianRoute</p>
        <h1>Road Safety Command Centre</h1>
        <p className="login-sub">
          Live hazards, Guardian Pulse™, and road risk — connected to your
          Firebase Spark backend.
        </p>
        <div style={{ display: "flex", flexDirection: "column", gap: "0.65rem" }}>
          <button
            type="button"
            className="btn-primary"
            onClick={handleGoogleSignIn}
            disabled={busy}
          >
            {busy ? "Signing in…" : "Sign in with Google"}
          </button>
          <button
            type="button"
            className="btn-ghost"
            style={{ width: "100%", padding: "0.75rem 1rem" }}
            onClick={handleGuestSignIn}
            disabled={busy}
          >
            Continue as Guest / Demo Operator
          </button>
        </div>
        {error && <p className="login-error">{error}</p>}
      </div>
    </div>
  );
}
