---
name: github-backup-sync
description: Inspect backup status, trigger manual GitHub backup & sync, verify state restore, and audit persistent backup repository settings.
---

# GitHub Backup & Sync Skill Guidelines

Use this skill whenever Aether needs to verify state backup status, execute a manual state sync to GitHub, or verify data persistence.

## 🔄 Backup Operations & Tools

1. **Trigger Immediate Backup to GitHub**:
   - Run shell command: `bash scripts/backup.sh`
   - Or trigger via HTTP API: `curl -X POST http://localhost:3000/api/trigger-backup`

2. **Check Backup Status & History**:
   - Read backup status JSON: `cat /app/data/backup-status.json` or `curl http://localhost:3000/health`
   - List local backup archives: `ls -la /app/backups/`

3. **Verify State Restore**:
   - Test restore script: `bash scripts/restore.sh`

4. **Required Environment Variables**:
   - `BACKUP_REPO` (e.g. `crimsonej/hermes-app-backup`)
   - `BACKUP_BRANCH` (default `main`)
   - `GITHUB_TOKEN` (GitHub Fine-grained PAT with repo contents write access)
   - `AUTO_BACKUP_HOURS` (default 24h)
