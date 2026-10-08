# Hermes Signal Generator & Trade Analyzer (Railway Ready)

This repository runs the official [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) on Railway configured specifically as an automated **Signal Generator** and **Trade Analyzer**, featuring persistent GitHub state backup & restore.

---

## ⚡ Key Features

1. **Memory-safe Railway profile**:
   - Default runtime is a lean profile tuned for ~1GB memory limits.
   - This avoids starting the full browser/ML stack unless you explicitly opt in with `INSTALL_FULL_STACK=true`.
   - Hermes continues to run as a thin gateway, while MT5 execution is routed through a bridge or a CLI wrapper instead of a full local terminal.

2. **Signal Generation Skill (`signal-generator`)**:
   - Pre-installed skill for technical indicator confluence (RSI, MACD, Moving Averages), trend identification, entry target zones, stop loss, and multi-tier take-profit levels with risk/reward calculation (min 1.5:1).
   - Structured JSON output format for direct integration with external webhooks or APIs.

2. **Trade Analysis Skill (`trade-analyzer`)**:
   - Pre-installed skill to audit past trades, calculate win rates, profit factor, drawdown metrics, risk compliance score, and slippage evaluation.

3. **NVIDIA API Key & Multi-Provider Support**:
   - Out-of-the-box support for **NVIDIA NIM / AI Foundation Endpoints** (`NVIDIA_API_KEY`), as well as OpenAI, Anthropic, OpenRouter, and Nous Portal keys.

4. **Persistent GitHub Backup System**:
   - Automatic background backup of `/app/data` (including generated signals and trade reviews) and `/app/.hermes` state to your private GitHub repo every 24 hours.
   - Auto-restore on startup so state is preserved across Railway deployments or account migrations.

---

## 🔒 Safety & Secrets

Trading operates in **paper trading mode** by default:

```text
HERMES_TRADING_MODE=paper
LIVE_TRADING_ENABLED=false
```

* **Never commit secret API keys or `.env` files** to your git repository.
* Ensure your `BACKUP_REPO` is set to **PRIVATE**.
* Set all sensitive API keys through Railway's Environment Variables dashboard.

---

## 🚀 Railway Setup Guide

### MT5 Bridge contract
The live-trading path is a bridge service outside Railway.

The bot sends an order payload to the bridge, and the bridge performs the actual MT5 execution. This keeps Hermes lightweight and preserves the memory cap.

Required bridge order payload:

```json
{
  "symbol": "EURUSD",
  "action": "buy",
  "volume": 0.01,
  "price": 1.1000,
  "stopLoss": 1.0950,
  "takeProfit": 1.1100,
  "comment": "hermes",
  "source": "hermes"
}
```

The bridge should respond with a JSON object similar to:

```json
{
  "ok": true,
  "orderId": "mt5-1234567890",
  "status": "accepted",
  "symbol": "EURUSD",
  "action": "buy",
  "serverTime": "2026-10-08T00:00:00.000Z"
}
```

### Best MT5 strategy for Railway
The best fit for a ~1GB memory-constrained Railway app is not a full MT5 desktop installation inside the container.

Recommended default:
- Keep Hermes in lean mode (`HERMES_PROFILE=lean`)
- Keep MT5 execution disabled by default (`MT5_EXECUTION_ENABLED=false`)
- Use a remote MT5 bridge or your own gateway service for actual order execution
- Only enable a local CLI wrapper if you have a dedicated lightweight MT5 runtime with its own memory budget

This avoids the classic Railway failure mode where the Python stack, browser stack, Xvfb, and MT5 terminal all fight for the same RAM.

### 1. Deploy Repository
Create a new Railway project connected to this GitHub repository. Railway will detect the `Dockerfile` and build the container automatically.

### 2. Create a Private GitHub Backup Repository
Create a private repository on GitHub (e.g. `your-username/hermes-backup`).

### 3. Create a GitHub Personal Access Token (PAT)
* Go to **GitHub Settings -> Developer Settings -> Personal Access Tokens (Fine-grained)**.
* Select your private backup repo and grant **Read and Write** access for `Repository contents`.

### 4. Configure Railway Environment Variables
In Railway -> your service -> **Variables** tab, click **Raw Editor** and paste:

```text
HERMES_ENABLED=true
HERMES_PROFILE=lean
HERMES_TRADING_MODE=paper
RESTORE_ON_START=true
AUTO_BACKUP_HOURS=24
BACKUP_REPO=crimsonej/hermes-app-backup
BACKUP_BRANCH=main
OPENAI_API_BASE=https://integrate.api.nvidia.com/v1

# MT5 execution adapter
MT5_EXECUTION_ENABLED=false
MT5_MODE=bridge
MT5_BRIDGE_URL=https://your-mt5-bridge.example.com/api/order
# or if using a CLI shim:
# MT5_CLI_BIN=/usr/local/bin/mt5-cli

NVIDIA_API_KEY=nvapi-PASTE_YOUR_NVIDIA_API_KEY_HERE
GITHUB_TOKEN=github_pat_PASTE_YOUR_TOKEN_HERE
TELEGRAM_BOT_TOKEN=PASTE_TELEGRAM_BOT_TOKEN_FROM_BOTFATHER_HERE
TELEGRAM_CHAT_ID=PASTE_YOUR_TELEGRAM_CHAT_ID_HERE
TELEGRAM_ALLOWED_USERS="*"
```

##### Option A: NVIDIA API Key (NVIDIA NIM)
```text
NVIDIA_API_KEY=nvapi-your_nvidia_api_key_here
OPENAI_API_BASE=https://integrate.api.nvidia.com/v1
```

##### Option B: OpenAI / Anthropic / OpenRouter
```text
OPENAI_API_KEY=your_openai_api_key
# or
ANTHROPIC_API_KEY=your_anthropic_api_key
# or
OPENROUTER_API_KEY=your_openrouter_api_key
```

---

## 🌐 REST API Endpoints

* `GET /health` – Health status & system check.
* `GET /` – Overview and endpoint index.
* `GET /api/trade-config` – Returns MT5 execution mode and backend status.
* `POST /api/trade` – Submit a trade request to the configured MT5 adapter.
* `POST /api/signals` – Save a generated signal object.
* `GET /api/signals` – Retrieve saved trading signals.
* `POST /api/analyses` – Save a trade analysis report.
* `GET /api/analyses` – Retrieve saved trade analysis reports.
* `POST /api/trigger-backup` – Manually trigger a state backup to GitHub.
* `POST /api/write-data` – Write custom files to `/app/data`.
* `GET /api/read-data` – Read files from `/app/data`.

---

## 💻 Local Development

```bash
# Install dependencies
npm install

# Run Express web server locally
npm run dev

# Manual trigger scripts
npm run backup
npm run restore
```