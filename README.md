# Hermes trading service

This repository runs the official [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) with a small web health/data service. The container pins Hermes Agent `v2026.8.31` so deployments are repeatable.

## Trading safety

Trading starts in paper mode:

```text
HERMES_TRADING_MODE=paper
```

The included `trading-risk` skill requires explicit confirmation before an order and does not treat an exchange API key as permission to trade live. Do not put exchange keys, cookies, wallet secrets, or passwords in either GitHub repository or in Hermes data backups.

## Railway setup

1. Deploy this repository as a Railway service.
2. Add a persistent volume mounted at `/app/.hermes` and another at `/app/data`, or use one volume mounted at `/app`.
3. Set `HERMES_ENABLED=true`, `HERMES_TRADING_MODE=paper`, and the model provider variables required by Hermes.
4. Add the backup variables from `.env.example` as Railway secrets.
5. Use a Railway cron service to run `npm run backup` once per day.

The service exposes `/health` on Railway's `$PORT`. Hermes itself is started by `scripts/start.sh`.

## Local checks

```bash
npm install
npm run dev
```

The official Hermes installation and provider configuration are documented in the upstream repository. Start with paper trading and test market-data access before connecting any exchange account.