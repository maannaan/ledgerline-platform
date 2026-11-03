#!/usr/bin/env bash
# Founder demo: dry-run Autopilot decisions (no live cloud mutations).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PYTHONPATH="$ROOT"

echo "== 1) Status (kill switch off) =="
python3 -m autopilot.cli kill --off >/dev/null || true
python3 -m autopilot.cli status

echo
echo "== 2) Dry-run: deploy health failed → rollback proposal =="
python3 -m autopilot.cli eval --signal autopilot/fixtures/deploy_health_failed.json

echo
echo "== 3) Dry-run: CPU high → scale within cap =="
python3 -m autopilot.cli eval --signal autopilot/fixtures/cpu_high.json

echo
echo "== 4) Dry-run: data corruption → restore BLOCKED without approval =="
python3 -m autopilot.cli eval --signal autopilot/fixtures/data_corruption.json --execute || true

echo
echo "== 5) Kill switch blocks everything =="
python3 -m autopilot.cli kill --reason "demo"
python3 -m autopilot.cli eval --signal autopilot/fixtures/cpu_high.json || true
python3 -m autopilot.cli kill --off

echo
echo "== 6) Recent audit events =="
python3 -m autopilot.cli audit --limit 8

echo
echo "Demo complete. Live actions require APPROVE_AUTOPILOT=1 (not used here)."
