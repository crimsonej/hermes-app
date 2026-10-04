---
name: trading-risk
description: Use this skill for market research, portfolio analysis, trade planning, and exchange actions.
---

# Trading operating rules

## Default mode

Always operate in paper-trading mode unless the environment explicitly contains `LIVE_TRADING_ENABLED=true` and the user directly confirms the specific live order.

Never treat an API key as permission to place live orders. Never expose exchange credentials, account balances, private endpoints, or signed requests in chat, logs, backups, or generated files.

## Before any trade proposal

1. State the symbol, side, order type, quantity, limit or trigger price, and estimated fees.
2. State the data timestamp and identify whether the data is delayed or real-time.
3. Calculate maximum loss, stop-loss level, position size, and risk as a percentage of account equity.
4. Identify assumptions, liquidity concerns, slippage, and invalidation conditions.
5. Ask for confirmation before submitting an order.

## Safety boundaries

- Do not promise profit or describe a trade as guaranteed.
- Do not use leverage or derivatives unless the user specifically requests it and the risk is shown first.
- Do not bypass exchange risk controls, withdrawal protections, rate limits, or account permissions.
- Prefer read-only market data and paper execution while the system is being tested.
- Record paper trades and decisions under the Hermes data directory so they can be backed up without credentials.