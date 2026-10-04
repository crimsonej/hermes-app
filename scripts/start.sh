#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
export HERMES_HOME

# Start Xvfb for headless browser automation
if command -v Xvfb >/dev/null 2>&1; then
  echo "Starting Xvfb on display :99..."
  Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset > /dev/null 2>&1 &
  XVFB_PID=$!
  sleep 2
  export DISPLAY=:99
  echo "Xvfb started with PID $XVFB_PID"
fi

if [ "${RESTORE_ON_START:-true}" = "true" ]; then
  echo "Restoring latest backup from GitHub if available..."
  bash scripts/restore.sh || echo "No backup found or restore failed; continuing with empty state."
fi

mkdir -p "$HERMES_HOME/skills"
if [ -d "$ROOT_DIR/hermes/skills" ]; then
  cp -R "$ROOT_DIR/hermes/skills/." "$HERMES_HOME/skills/"
fi
if [ -f "$ROOT_DIR/hermes/SOUL.md" ]; then
  cp "$ROOT_DIR/hermes/SOUL.md" "$HERMES_HOME/SOUL.md"
fi
if [ -f "$ROOT_DIR/hermes/AGENTS.md" ]; then
  cp "$ROOT_DIR/hermes/AGENTS.md" "$HERMES_HOME/AGENTS.md"
fi

# Populate Hermes environment secrets file
mkdir -p "$HERMES_HOME"
ENV_FILE="$HERMES_HOME/.env"
touch "$ENV_FILE"

if [ -n "${NVIDIA_API_KEY:-}" ]; then
  grep -q "^NVIDIA_API_KEY=" "$ENV_FILE" 2>/dev/null || echo "NVIDIA_API_KEY=${NVIDIA_API_KEY}" >> "$ENV_FILE"
  grep -q "^OPENAI_API_BASE=" "$ENV_FILE" 2>/dev/null || echo "OPENAI_API_BASE=${OPENAI_API_BASE:-https://integrate.api.nvidia.com/v1}" >> "$ENV_FILE"
fi

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  grep -q "^TELEGRAM_BOT_TOKEN=" "$ENV_FILE" 2>/dev/null || echo "TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}" >> "$ENV_FILE"
fi

if [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  grep -q "^TELEGRAM_CHAT_ID=" "$ENV_FILE" 2>/dev/null || echo "TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}" >> "$ENV_FILE"
fi

# Auto-configure Telegram Bot if TELEGRAM_BOT_TOKEN is set AND config.yaml doesn't already exist or lack telegram
CONFIG_FILE="$HERMES_HOME/config.yaml"
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ ! -s "$CONFIG_FILE" ]; then
  echo "Telegram Bot Token detected. Creating initial Telegram configuration..."

  if [ -n "${TELEGRAM_ALLOWED_USERS:-}" ]; then
    ALLOWED_STR="[\"${TELEGRAM_ALLOWED_USERS}\"]"
  else
    ALLOWED_STR="[\"\*\"]"
  fi

  CHAT_ID_LINE=""
  if [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    CHAT_ID_LINE="  chat_id: \"${TELEGRAM_CHAT_ID}\""
  fi

  cat <<EOF > "$CONFIG_FILE"
telegram:
  enabled: true
  bot_token: "${TELEGRAM_BOT_TOKEN}"
  allowed_users: ${ALLOWED_STR}
${CHAT_ID_LINE}
EOF
  echo "Telegram configuration written to $CONFIG_FILE"
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
    echo "Hermes executable not found. Skipping daemon launch." >&2
    HERMES_PID=""
  else
    echo "Starting Hermes Gateway daemon using $HERMES_BIN (with full auto-approval hooks enabled)..."
    export HERMES_ACCEPT_HOOKS=1
    nohup "$HERMES_BIN" gateway run --accept-hooks >> "$DATA_DIR/hermes-gateway.log" 2>&1 &
    HERMES_PID=$!
    echo "Hermes Gateway started with PID $HERMES_PID (logging to $DATA_DIR/hermes-gateway.log)"
  fi
else
  echo "HERMES_ENABLED is false; skipping Hermes daemon."
  HERMES_PID=""
fi


trap 'kill "$WEB_PID" ${HERMES_PID:-} ${XVFB_PID:-} 2>/dev/null || true' EXIT INT TERM
wait "$WEB_PID"

