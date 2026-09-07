# Hermes Agent on Railway

This repository is the deployment wrapper for Hermes Agent. The application source and the private data backup are intentionally separate.

## Before deploying

1. Add the Hermes Agent source and its documented dependencies under `project/`, or adapt the `Dockerfile` to install the upstream release.
2. Set `HERMES_START_COMMAND` to Hermes' documented startup command.
3. Create a Railway volume mounted at `/data`.
4. Create a fine-grained GitHub token with `Contents: Read and write` access only to `crimsonej/hermes-app-backup`.
5. Add these Railway variables:

```text
BACKUP_REPO=crimsonej/hermes-app-backup
BACKUP_BRANCH=main
BACKUP_PASSPHRASE=<long unique secret>
GITHUB_TOKEN=<fine-grained token>
HERMES_START_COMMAND=<Hermes startup command>
```

The passphrase and token must never be committed to GitHub.

## Backups

Run `/app/backup.sh` from a Railway cron job or a separate worker once per day. It encrypts the contents of `/data/hermes` with AES-256 before pushing one rolling snapshot to the private backup repository. The container restores that snapshot before Hermes starts.

The GitHub repository should contain only encrypted backup files. Keep a second encrypted copy on a PC or an S3-compatible bucket for disaster recovery.

## Local checks

```sh
docker build -t hermes-railway .
```
