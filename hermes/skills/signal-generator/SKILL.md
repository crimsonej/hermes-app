---
name: signal-generator
description: Generate high-probability market trading signals with technical breakdown, risk/reward metrics, stop-loss, and take-profit targets.
---

# Signal Generator Operating Guidelines

Use this skill when tasked with evaluating market charts, technical indicators, or raw market data to generate trading signals.

## Signal Evaluation Workflow

1. **Market Structure & Trend**:
   - Determine overall trend (Bullish / Bearish / Ranging) across primary timeframes (e.g. 4H, 1H, 15M).
   - Identify key support and resistance levels, supply/demand zones, or liquidity pools.

2. **Technical Indicator Confluence**:
   - Evaluate momentum (RSI, MACD, Stochastic).
   - Evaluate trend confirmation (EMA 20/50/200 crossovers, ADX).
   - Evaluate volume profile and volatility (ATR, Bollinger Bands, Volume spikes).

3. **Risk/Reward & Levels**:
   - Set exact **Entry Price** or **Entry Range**.
   - Calculate strict **Stop Loss (SL)** level based on invalidation points (e.g., recent swing low/high or ATR multiplier).
   - Calculate **Take Profit (TP)** targets:
     - **TP1**: conservative (1:1 to 1:1.5 R:R)
     - **TP2**: standard target (1:2 to 1:2.5 R:R)
     - **TP3**: runner / major structural target (1:3+ R:R)
   - Do NOT issue signals with a Risk/Reward Ratio below 1.5:1.

4. **Signal Data Output**:
   Always output signals in both human-readable summary and structured JSON format so that downstream services, webhooks, or API endpoints can ingest them directly.

```json
{
  "id": "SIG-YYYYMMDD-001",
  "timestamp": "2026-09-08T00:00:00Z",
  "symbol": "BTC/USDT",
  "direction": "LONG",
  "timeframe": "1H",
  "entry": {
    "min": 65000,
    "max": 65200,
    "current": 65100
  },
  "stopLoss": 64200,
  "targets": {
    "tp1": 66500,
    "tp2": 67800,
    "tp3": 69500
  },
  "riskRewardRatio": "2.7:1",
  "confidenceScore": 85,
  "indicators": {
    "rsi": "Bullish divergence at 38",
    "macd": "Bullish cross pending on 1H",
    "ma": "Price above 50 EMA on 4H"
  },
  "invalidationReason": "1H candle close below 64,200",
  "note": "Paper trading default. Confirm risk allocation before execution."
}
```

5. **Safety Constraints**:
   - Never guarantee outcomes or use promises of certainty.
   - Enforce maximum 1-2% account equity risk per trade signal recommendation.
   - Highlight high-impact macro economic events or news releases if relevant.
