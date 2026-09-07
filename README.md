# Hermes Trading & Agent Service (Railway Ready)

This repository runs the official [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) along with an automated GitHub backup & restore system. The Docker container automatically compiles and pre-installs Hermes Agent during the build phase—**no manual installation commands required on Railway**.

---

## ⚡ How It Works

1. **Automatic Build**: When pushed to Railway, Docker installs Python 3.11, `uv`, and clones/builds `hermes-agent`.
2. **First Boot Restore**: Upon starting up on Railway, `scripts/start.sh` runs `scripts/restore.sh`, which automatically pulls your latest state archive from your private GitHub repository (`BACKUP_REPO`) and restores `/app/.hermes` and `/app/data`.
3. **Automated & On-Demand Backups**:
   - **Automatic**: The server runs an internal scheduler that backs up your state every 24 hours (`AUTO_BACKUP_HOURS=24`).
   - **On-Demand**: You can trigger a backup anytime via HTTP: `GET/POST /api/trigger-backup` or by running `npm run backup`.
4. **Monthly Railway Account Rotation**: When switching Railway accounts, simply deploy this repository to the new account and supply your `GITHUB_TOKEN` and `BACKUP_REPO`. The app will auto-restore your exact state on boot.

---

## 🔒 Trading Safety & Secrets

Trading defaults to **paper mode**:

```text
HERMES_TRADING_MODE=paper
LIVE_TRADING_ENABLED=false
```

* **Never commit real secrets or `.env` files** to GitHub.
* Keep your backup GitHub repository **PRIVATE** (`BACKUP_REPO`).
* Provide credentials only via Railway's Environment Variables panel.

---

## 🚀 Railway Setup Guide

1. **Deploy Repository**: Create a new Railway project connected to this GitHub repo.
2. **Create a Private Backup Repository**: Create a private GitHub repository (e.g. `your-github-username/hermes-app-backup`).
3. **Generate GitHub Personal Access Token (PAT)**:
   - Go to GitHub -> Settings -> Developer Settings -> Personal Access Tokens (Fine-grained).
   - Grant **Read and Write** access for `Repository contents` on your private backup repo.
4. **Configure Environment Variables in Railway**:

```text
HERMES_ENABLED=true
HERMES_TRADING_MODE=paper
RESTORE_ON_START=true
BACKUP_REPO=your-github-username/hermes-app-backup
BACKUP_BRANCH=main
GITHUB_TOKEN=your_github_personal_access_token
AUTO_BACKUP_HOURS=24
OPENAI_API_KEY=your_api_key_here (or ANTHROPIC_API_KEY / OPENROUTER_API_KEY)
```

---

## 🌐 Endpoints

* `GET /health` – Health status & last backup execution log.
* `GET /` – Overview and endpoint index.
* `POST /api/trigger-backup` – Manually trigger a backup to GitHub instantly.
* `POST /api/write-data` – Write JSON/text data to storage.
* `GET /api/read-data` – Read data files from storage.

---

## 💻 Local Development

```bash
npm install
npm run dev
```

To run a manual backup or restore locally:
```bash
npm run backup
npm run restore
```