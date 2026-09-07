#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATA_DIR="${DATA_DIR:-$ROOT_DIR/data}"
HERMES_HOME="${HERMES_HOME:-$ROOT_DIR/.hermes}"
RAW_REPO="${BACKUP_REPO:-}"
BACKUP_BRANCH="${BACKUP_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$RAW_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Missing BACKUP_REPO or GITHUB_TOKEN. Backup skipped."
  exit 0
fi

CLEAN_REPO="${RAW_REPO#https://github.com/}"
CLEAN_REPO="${CLEAN_REPO#.git}"

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
rm -rf "$TEMP_DIR"

REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${CLEAN_REPO}.git"
CLONE_DIR="$ROOT_DIR/backup-tmp"

rm -rf "$CLONE_DIR"
mkdir -p "$CLONE_DIR"

if git ls-remote --exit-code "$REMOTE_URL" >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BACKUP_BRANCH" "$REMOTE_URL" "$CLONE_DIR" || git clone "$REMOTE_URL" "$CLONE_DIR"
else
  git clone "$REMOTE_URL" "$CLONE_DIR" || (cd "$CLONE_DIR" && git init && git remote add origin "$REMOTE_URL")
fi

cp "$ARCHIVE" "$CLONE_DIR/"
cd "$CLONE_DIR"

git config user.name "Railway Backup"
git config user.email "backup@railway.local"

# Keep latest 10 backup files to avoid huge git repository sizes
MAX_BACKUPS=10
BACKUP_FILES=($(ls -t hermes-data-*.tar.gz 2>/dev/null || true))
if [ "${#BACKUP_FILES[@]}" -gt "$MAX_BACKUPS" ]; then
  for old_file in "${BACKUP_FILES[@]:$MAX_BACKUPS}"; do
    rm -f "$old_file"
    git rm -f "$old_file" 2>/dev/null || true
  done
fi

git checkout -b "$BACKUP_BRANCH" 2>/dev/null || git checkout "$BACKUP_BRANCH" 2>/dev/null || true
git add .
git commit -m "backup: $STAMP" || true

git push origin "$BACKUP_BRANCH" --force || git push "$REMOTE_URL" "$BACKUP_BRANCH" --force

cd "$ROOT_DIR"
rm -rf "$CLONE_DIR"
rm -f "$ARCHIVE"

echo "Backup uploaded successfully to GitHub ($CLEAN_REPO) for $STAMP"

