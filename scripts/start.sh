#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
export HERMES_HOME

if [ "${RESTORE_ON_START:-true}" = "true" ]; then
  echo "Restoring latest backup from GitHub if available..."
  bash scripts/restore.sh || echo "No backup found or restore failed; continuing with empty state."
fi

mkdir -p "$HERMES_HOME/skills"
if [ -d "$ROOT_DIR/hermes/skills" ]; then
  cp -R "$ROOT_DIR/hermes/skills/." "$HERMES_HOME/skills/"
else
  echo "No custom Hermes skills found; continuing with built-in skills."
fi

if [ -f server.js ]; then
  node server.js &
  WEB_PID=$!
else
  echo "No server.js found; cannot start app." >&2
  exit 1
fi

if [ "${HERMES_ENABLED:-true}" = "true" ]; then
  HERMES_BIN=""
  if [ -x /opt/hermes-venv/bin/hermes ]; then
    HERMES_BIN="/opt/hermes-venv/bin/hermes"
  elif command -v hermes >/dev/null 2>&1; then
    HERMES_BIN="$(command -v hermes)"
  elif [ -x "$HOME/.hermes/bin/hermes" ]; then
    HERMES_BIN="$HOME/.hermes/bin/hermes"
  fi

  if [ -z "$HERMES_BIN" ]; then
    echo "Hermes executable not found. Skipping daemon launch (or install with curl script locally)." >&2
    HERMES_PID=""
  else
    echo "Starting Hermes Gateway using $HERMES_BIN..."
    "$HERMES_BIN" gateway start &
    HERMES_PID=$!
  fi
else
  echo "HERMES_ENABLED is false; skipping Hermes daemon."
  HERMES_PID=""
fi


trap 'kill "$WEB_PID" ${HERMES_PID:-} 2>/dev/null || true' EXIT INT TERM
wait "$WEB_PID"

