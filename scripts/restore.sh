#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATA_DIR="${DATA_DIR:-$ROOT_DIR/data}"
HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
BACKUP_REPO="${BACKUP_REPO:-}"
BACKUP_BRANCH="${BACKUP_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$BACKUP_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Restore skipped: missing backup config."
  exit 0
fi

mkdir -p "$ROOT_DIR/backup-tmp"
REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git"
CLONE_DIR="$ROOT_DIR/backup-tmp/repo"
rm -rf "$CLONE_DIR"

if git ls-remote --exit-code "$REMOTE_URL" >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BACKUP_BRANCH" "$REMOTE_URL" "$CLONE_DIR" || git clone "$REMOTE_URL" "$CLONE_DIR"
else
  echo "No remote backup repo found; skipping restore."
  exit 0
fi

LATEST_FILE="$(find "$CLONE_DIR" -type f -name 'hermes-data-*.tar.gz' | sort | tail -n 1 || true)"

if [ -z "$LATEST_FILE" ]; then
  echo "No backup archive found."
  rm -rf "$CLONE_DIR"
  exit 0
fi

TMP_ARCHIVE="$ROOT_DIR/backup-tmp/latest-backup.tar.gz"
cp "$LATEST_FILE" "$TMP_ARCHIVE"

mkdir -p "$DATA_DIR"
TMP_EXTRACT="$ROOT_DIR/backup-tmp/extract"
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"

tar -xzf "$TMP_ARCHIVE" -C "$TMP_EXTRACT"

if [ -d "$TMP_EXTRACT/data" ]; then
  cp -R "$TMP_EXTRACT/data/." "$DATA_DIR/"
fi

if [ -d "$TMP_EXTRACT/hermes" ]; then
  mkdir -p "$HERMES_HOME"
  cp -R "$TMP_EXTRACT/hermes/." "$HERMES_HOME/"
fi

rm -rf "$CLONE_DIR" "$TMP_ARCHIVE" "$TMP_EXTRACT"

echo "Restore complete from GitHub backup"
