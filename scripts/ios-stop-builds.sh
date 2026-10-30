#!/usr/bin/env bash
# Stop stuck Xcode builds that cause "concurrent builds" in flutter run.
set -euo pipefail
killall xcodebuild 2>/dev/null || true
echo "Stopped xcodebuild (if any was running). Wait 5s, then run flutter again from mobile/."
sleep 1
if pgrep -x xcodebuild >/dev/null 2>&1; then
  echo "Warning: xcodebuild still running. Quit Xcode or kill PID: $(pgrep -x xcodebuild)"
else
  echo "OK: no xcodebuild process."
fi
