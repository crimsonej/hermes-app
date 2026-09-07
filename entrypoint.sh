#!/bin/sh
set -eu

: "${HERMES_DATA_DIR:=/data/hermes}"
export HERMES_DATA_DIR
mkdir -p "$HERMES_DATA_DIR"

if [ -n "${BACKUP_REPO:-}" ] && [ -n "${BACKUP_PASSPHRASE:-}" ]; then
  /app/restore.sh || echo "No backup restored; continuing with existing data."
fi

if [ -z "${HERMES_START_COMMAND:-}" ]; then
  echo "HERMES_START_COMMAND is required to launch Hermes Agent." >&2
  exit 1
fi

exec sh -c "$HERMES_START_COMMAND"
