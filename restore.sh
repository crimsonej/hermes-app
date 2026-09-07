#!/bin/sh
set -eu

: "${HERMES_DATA_DIR:=/data/hermes}"
: "${BACKUP_WORK_DIR:=/tmp/backup-work}"
: "${BACKUP_BRANCH:=main}"
: "${BACKUP_DIR:=hermes-data}"

for required in BACKUP_REPO BACKUP_PASSPHRASE GITHUB_TOKEN; do
  eval "value=\${$required:-}"
  if [ -z "$value" ]; then
    echo "$required is required" >&2
    exit 1
  fi
done

rm -rf "$BACKUP_WORK_DIR"
mkdir -p "$BACKUP_WORK_DIR"
git clone --quiet --depth 1 --branch "$BACKUP_BRANCH" "https://x-access-token:${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_WORK_DIR/repo"

archive="$BACKUP_WORK_DIR/repo/$BACKUP_DIR/latest.tar.gz.gpg"
[ -f "$archive" ] || { echo "No Hermes backup exists yet." >&2; exit 1; }

mkdir -p "$HERMES_DATA_DIR"
gpg --batch --yes --pinentry-mode loopback --passphrase "$BACKUP_PASSPHRASE" --decrypt "$archive" | tar -xzf - -C "$HERMES_DATA_DIR"
