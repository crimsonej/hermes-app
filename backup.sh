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
git clone --quiet --branch "$BACKUP_BRANCH" "https://x-access-token:${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_WORK_DIR/repo"

archive="$BACKUP_WORK_DIR/hermes-data.tar.gz.gpg"
tar -czf - -C "$HERMES_DATA_DIR" . | gpg --batch --yes --pinentry-mode loopback --passphrase "$BACKUP_PASSPHRASE" --symmetric --cipher-algo AES256 -o "$archive"

mkdir -p "$BACKUP_WORK_DIR/repo/$BACKUP_DIR"
mv "$archive" "$BACKUP_WORK_DIR/repo/$BACKUP_DIR/latest.tar.gz.gpg"
printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$BACKUP_WORK_DIR/repo/$BACKUP_DIR/last-successful-backup.txt"

git -C "$BACKUP_WORK_DIR/repo" config user.name "Hermes Backup"
git -C "$BACKUP_WORK_DIR/repo" config user.email "hermes-backup@users.noreply.github.com"
git -C "$BACKUP_WORK_DIR/repo" add "$BACKUP_DIR"
git -C "$BACKUP_WORK_DIR/repo" commit -m "backup: update Hermes data" >/dev/null || exit 0
git -C "$BACKUP_WORK_DIR/repo" push --quiet origin "$BACKUP_BRANCH"
