#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATA_DIR="${DATA_DIR:-$ROOT_DIR/data}"
HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
BACKUP_REPO="${BACKUP_REPO:-}"
BACKUP_BRANCH="${BACKUP_BRANCH:-main}"
BACKUP_PASSPHRASE="${BACKUP_PASSPHRASE:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$BACKUP_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Missing BACKUP_REPO or GITHUB_TOKEN. Backup skipped."
  exit 0
fi

if [ -z "$BACKUP_PASSPHRASE" ]; then
  echo "BACKUP_PASSPHRASE is required. Backup skipped."
  exit 0
fi

mkdir -p "$ROOT_DIR/backups"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
ARCHIVE="$ROOT_DIR/backups/hermes-data-$STAMP.tar.gz"
TEMP_DIR="$ROOT_DIR/backups/temp-$STAMP"
mkdir -p "$TEMP_DIR"

if [ -d "$DATA_DIR" ]; then
  cp -R "$DATA_DIR" "$TEMP_DIR/data"
fi

if [ -d "$HERMES_HOME" ]; then
  cp -R "$HERMES_HOME" "$TEMP_DIR/hermes"
fi

find "$TEMP_DIR" -type f \( -name '*.key' -o -name '*.pem' -o -name '*.secret' -o -name '.env' \) -delete

tar -czf "$ARCHIVE" -C "$TEMP_DIR" .
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSPHRASE" -in "$ARCHIVE" -out "$ARCHIVE.enc"
rm -f "$ARCHIVE"
rm -rf "$TEMP_DIR"

REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git"
CLONE_DIR="$ROOT_DIR/backup-tmp"

rm -rf "$CLONE_DIR"
if git ls-remote --exit-code "$REMOTE_URL" >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BACKUP_BRANCH" "$REMOTE_URL" "$CLONE_DIR" || git clone "$REMOTE_URL" "$CLONE_DIR"
else
  git clone "$REMOTE_URL" "$CLONE_DIR"
fi

cp "$ARCHIVE.enc" "$CLONE_DIR/"
cd "$CLONE_DIR"

git config user.name "Railway Backup"
git config user.email "backup@railway.local"

git add .
git commit -m "backup: $STAMP" || true

git push origin "$BACKUP_BRANCH" || git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_BRANCH"

rm -rf "$CLONE_DIR"
rm -f "$ARCHIVE.enc"

echo "Backup uploaded to GitHub for $STAMP"
