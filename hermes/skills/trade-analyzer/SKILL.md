---
name: trade-analyzer
description: Analyze executed trades, evaluate portfolio performance, track win rates, assess risk management compliance, and audit trade journals.
---

# Trade Analyzer Operating Guidelines

Use this skill to perform post-trade analysis, audit closed/open position histories, and evaluate overall trading strategy performance.

## Trade Analysis Framework

1. **Trade Audit & Execution Assessment**:
   - Compare planned Entry, SL, and TP against actual execution fill prices.
   - Measure slippage, fee impact, and execution delay.
   - Verify whether risk management rules (position sizing, maximum portfolio drawdown limit) were respected.

2. **Performance Metrics Calculation**:
   - **Win Rate**: Percentage of profitable trades vs losing trades.
   - **Profit Factor**: Gross Profits / Gross Losses.
   - **Average Win vs Average Loss**: Risk/Reward realization ratio.
   - **Max Drawdown**: Peak-to-trough decline percentage during the evaluated trading session.
   - **Expectancy**: `(Win Rate % * Avg Win) - (Loss Rate % * Avg Loss)`.

3. **Behavioral & Strategy Feedback**:
   - Identify recurring failure modes (e.g. premature exits, revenge trading, moving stop losses, trading against dominant high-timeframe trends).
   - Identify top-performing assets, timeframes, or setup patterns.

4. **Trade Analysis Structured Report**:
   Generate trade analysis output using structured JSON and executive markdown breakdown:

```json
{
  "analysisId": "TA-20260908-01",
  "timestamp": "2026-09-08T00:00:00Z",
  "period": "2026-09-01 to 2026-09-07",
  "summary": {
    "totalTrades": 15,
    "winningTrades": 10,
    "losingTrades": 5,
    "winRate": "66.7%",
    "profitFactor": 2.14,
    "netPnLPercent": "+8.4%",
    "maxDrawdown": "-2.1%",
    "avgRiskReward": "1.85:1"
  },
  "riskComplianceScore": 92,
  "keyObservations": [
    "High win rate on 1H trend continuation setups",
    "Increased slippage noticed during volatile US market open",
    "Strict adherence to stop loss saved 1.5% equity on invalid breakout"
  ],
  "recommendations": [
    "Reduce position sizing by 25% during high-impact news windows",
    "Trailing stop-loss strategy recommended after TP1 hit to secure profits faster"
  ]
}
```

5. **Safety & Journaling**:
   - Ensure sanitized outputs containing zero private credentials or private exchange API keys.
   - Save analysis logs into `$DATA_DIR/analyses/` for automatic backup.
