#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
export HERMES_HOME

if [ "${RESTORE_ON_START:-true}" = "true" ]; then
  echo "Restoring latest backup if available..."
  bash scripts/restore.sh || echo "No backup found or restore failed; continuing with empty state."
fi

mkdir -p "$HERMES_HOME/skills"
if [ -d "$ROOT_DIR/hermes/skills" ]; then
  cp -R "$ROOT_DIR/hermes/skills/." "$HERMES_HOME/skills/"
else
  echo "No custom Hermes skills found; continuing with built-in skills."
fi

if [ -f package.json ]; then
  npm run dev &
  WEB_PID=$!
else
  echo "No package.json found; cannot start app." >&2
  exit 1
fi

if [ "${HERMES_ENABLED:-true}" = "true" ]; then
  if [ ! -x /opt/hermes-venv/bin/hermes ]; then
    echo "Hermes executable was not installed." >&2
    exit 1
  fi

  /opt/hermes-venv/bin/hermes gateway start &
  HERMES_PID=$!
else
  HERMES_PID=""
fi

trap 'kill "$WEB_PID" ${HERMES_PID:-} 2>/dev/null || true' EXIT INT TERM
wait "$WEB_PID"
