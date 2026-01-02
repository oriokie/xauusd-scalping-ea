# Simba Sniper EA - Quick Reference Guide

## Quick Start Checklist

- [ ] Copy `SimbaSniperEA.mq5` to `MQL5/Experts` folder
- [ ] Compile in MetaEditor (F7) - verify 0 errors
- [ ] Attach to XAUUSD chart (any timeframe, EA uses multi-TF)
- [ ] Enable AutoTrading button
- [ ] Verify dashboard appears on chart
- [ ] Check Experts log for "initialized successfully"
- [ ] Set correct `SessionGMTOffset` for your broker
- [ ] Test on demo account for 2-4 weeks minimum

## Architecture Flow

```
H4 Timeframe → Trend Bias (Bullish/Bearish/Neutral)
    ↓
H1 Timeframe → Zones Detection (S/R, OBs, FVGs)
    ↓
M5 Timeframe → Entry Confirmation (BOS, Sweeps)
    ↓
M1 Timeframe → Precision Entry (Optional)
    ↓
9-Point Validation System
    ↓
Trade Execution (if validation passes)
```

## 9-Point Validation System

| # | Validation Check | Default | Description |
|---|-----------------|---------|-------------|
| 1 | H4 Trend | Required | H4 must show clear trend |
| 2 | H1 Zone | Required | Price at S/R zone |
| 3 | BOS | Required | Break of structure on M5 |
| 4 | Liquidity Sweep | Optional | Stop hunt reversal |
| 5 | FVG | Optional | Fair value gap present |
| 6 | Order Block | Required | Valid order block |
| 7 | ATR Zone | Required | Within ATR distance |
| 8 | Valid R:R | Required | Meets min RR ratio |
| 9 | Session Filter | Required | Active trading session |

**Minimum Points**: 6/9 required by default

## Key Parameters Quick Reference

### Must Configure
- `SessionGMTOffset`: Set based on your broker (usually 0, +2, or +3)
- `RiskPercentage`: Start with 0.5-1.0% for safety
- `MaxDailyLossPercent`: Recommended 2-3%

### Fine-Tuning
- `MinValidationPoints`: Higher = more conservative (5-8)
- `ATR_StopLossMultiplier`: Increase if getting stopped out (1.0-2.0)
- `ATR_TakeProfitMultiplier`: Increase for bigger targets (2.0-4.0)
- `MinRiskRewardRatio`: Minimum 1.5, recommended 2.0+

### Structure Detection
- `SwingLookback`: 15-25 bars (20 default)
- `MinDisplacementPercent`: 0.2-0.5 (0.3 default)
- `OrderBlockBars`: 3-7 bars (5 default)
- `FVG_MinGapPoints`: 10-30 points (20 default)

## Dashboard Quick Read

### Color Coding
- 🟢 **GREEN**: Bullish/Active/Positive/Good
- 🔴 **RED**: Bearish/Paused/Negative/Alert
- 🟡 **YELLOW**: Neutral/Warning/Attention
- 🟠 **ORANGE**: Inactive/Closed
- 🥇 **GOLD**: Title/Headers
- ⚪ **SILVER**: Subtitles

### Key Metrics
- **H4 Trend**: Must be GREEN (bullish) or RED (bearish) to trade
- **Validation**: Shows X/9 - needs minimum 6 by default
- **Points**: Shows which specific checks passed
- **Session**: Must be GREEN (ACTIVE) to trade
- **Status**: GREEN = trading, RED = paused (daily loss hit)

## Common Validation Point Abbreviations

- **H4** = H4 Trend aligned
- **Zone** = H1 Zone present
- **BOS** = Break of Structure detected
- **Sweep** = Liquidity Sweep detected
- **FVG** = Fair Value Gap present
- **OB** = Order Block valid
- **ATR** = ATR Zone validated
- **Session** = Trading session active

## Strategy Concepts

### H4 Trend Detection
- **Bullish**: Higher Highs + Higher Lows + Upward Displacement
- **Bearish**: Lower Highs + Lower Lows + Downward Displacement
- **Neutral**: Choppy, no clear structure

### H1 Zones
- **Support**: 3+ touches on lows, price bounces up
- **Resistance**: 3+ touches on highs, price bounces down
- **Strength**: More touches = stronger zone

### Order Blocks
- **Bullish OB**: Last down candle before strong up move
- **Bearish OB**: Last up candle before strong down move
- **Logic**: Institutions filled orders there, expect support/resistance

### Fair Value Gaps (FVG)
- **Bullish FVG**: Gap between bar[i-1].low and bar[i+1].high (upward)
- **Bearish FVG**: Gap between bar[i-1].high and bar[i+1].low (downward)
- **Logic**: Price moved too fast, may return to fill gap

### Break of Structure (BOS)
- **Bullish BOS**: Price breaks above recent swing high
- **Bearish BOS**: Price breaks below recent swing low
- **Confirmation**: Trend continuation signal

### Liquidity Sweep
- **Bullish Sweep**: Breaks below low, then reverses up (stop hunt)
- **Bearish Sweep**: Breaks above high, then reverses down (stop hunt)
- **Entry**: After reversal, in trend direction

## Risk Management Quick Tips

### Conservative Setup
```
RiskPercentage = 0.5%
MaxDailyLossPercent = 2.0%
MinValidationPoints = 7 or 8
MaxPositions = 1
ATR_StopLossMultiplier = 2.0
Require most validations = true
```

### Moderate Setup (Default)
```
RiskPercentage = 1.0%
MaxDailyLossPercent = 3.0%
MinValidationPoints = 6
MaxPositions = 1
ATR_StopLossMultiplier = 1.5
Required: H4, Zone, BOS, OB, ATR, RR, Session
```

### Aggressive Setup (Advanced Only)
```
RiskPercentage = 1.5-2.0%
MaxDailyLossPercent = 5.0%
MinValidationPoints = 5
MaxPositions = 2
ATR_StopLossMultiplier = 1.0
Optional: Sweep, FVG
```

## Session Times by Broker

### Common GMT Offsets
- **GMT+0**: Pure GMT time (ICMarkets, Pepperstone)
- **GMT+2**: Most European brokers (winter)
- **GMT+3**: European brokers (summer DST)
- **Check**: Your broker's server time vs GMT

### Setting Offset
If broker time is GMT+2, set `SessionGMTOffset = -2`
If broker time is GMT+3, set `SessionGMTOffset = -3`

## Troubleshooting Flowchart

```
No Trades?
├─ Dashboard showing?
│  ├─ No → Check ShowDashboard = true
│  └─ Yes → Continue
├─ H4 Trend = NEUTRAL?
│  ├─ Yes → Wait for trend to form
│  └─ No → Continue
├─ Validation < 6?
│  ├─ Yes → Lower MinValidationPoints or wait
│  └─ No → Continue
├─ Session CLOSED?
│  ├─ Yes → Check SessionGMTOffset
│  └─ No → Continue
├─ Status PAUSED?
│  ├─ Yes → Daily loss hit, wait for new day
│  └─ No → Check error message
└─ Check required validations met
```

## Performance Expectations

### Realistic Targets
- **Trade Frequency**: 1-5 trades per week
- **Win Rate**: 50-65% (institutional setups)
- **Risk/Reward**: 1:2 minimum (default 1.5:3.0)
- **Monthly Return**: 5-15% (conservative)
- **Max Drawdown**: <10%

### Red Flags
- Win rate < 40% → Review parameters
- Too many trades → Increase validation points
- Too few trades → Decrease validation points
- High drawdown → Reduce risk percentage

## Testing Protocol

1. **Visual Test** (1 hour):
   - Attach to chart
   - Watch dashboard update
   - Verify trend detection
   - Check validation scoring

2. **Strategy Tester** (1-2 days):
   - Test 6+ months historical data
   - Use M5 or M1 chart in tester
   - Enable visualization to watch
   - Review trade journal

3. **Demo Account** (2-4 weeks):
   - Real-time market conditions
   - Monitor daily statistics
   - Track validation accuracy
   - Adjust parameters as needed

4. **Live Micro Lots** (4+ weeks):
   - Start with 0.01 lots
   - Gradual increase if profitable
   - Continue monitoring closely

## Emergency Actions

### If Daily Loss Limit Hit
- EA automatically pauses
- Status shows PAUSED (red)
- Resumes next day automatically
- Review what went wrong

### If Multiple Losses
- Check H4 trend still valid
- Verify ATR not too low (choppy market)
- Review validation points
- Consider increasing MinValidationPoints

### If Unexpected Behavior
- Check Experts log for errors
- Verify all required indicators loading
- Check symbol is correct
- Restart MT5 if needed

## Support Checklist

Before asking for help, verify:
- [ ] Compiled without errors
- [ ] Attached to correct symbol (XAUUSD recommended)
- [ ] AutoTrading enabled
- [ ] Dashboard visible
- [ ] Checked Experts log
- [ ] Tested on demo first
- [ ] SessionGMTOffset set correctly
- [ ] Minimum balance for lot size calculation
- [ ] Broker allows EAs
- [ ] Screenshot of issue

## Resources

- **Full Documentation**: `SIMBA_SNIPER_README.md`
- **EA File**: `SimbaSniperEA.mq5`
- **Test Environment**: MT5 Strategy Tester
- **Recommended Symbol**: XAUUSD (Gold vs USD)
- **Recommended Chart**: Any (EA uses H4/H1/M5/M1 internally)

## Critical Reminders

⚠️ **ALWAYS test on demo first**
⚠️ **NEVER risk more than you can afford to lose**
⚠️ **SET correct SessionGMTOffset**
⚠️ **START with low risk percentage**
⚠️ **MONITOR first week closely**
⚠️ **USE VPS for 24/7 operation**
⚠️ **BACKTEST before live trading**
⚠️ **UNDERSTAND the strategy**

---

**Quick Reference v1.0 - Simba Sniper EA**
