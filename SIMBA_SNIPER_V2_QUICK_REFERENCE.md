# SimbaSniperEA V2.0 - Quick Reference Guide

## Quick Start

### 1. Installation
1. Copy `SimbaSniperEA.mq5` to `MQL5/Experts/`
2. Copy `Include/` folder to `MQL5/Experts/Include/`
3. Compile in MetaEditor (F7)
4. Attach to XAUUSD M5 chart

### 2. Essential Settings (Recommended)
```
// Risk Management
RiskPercentage = 1.0
MaxDailyLossPercent = 3.0
MaxDrawdownPercent = 10.0
MinRiskRewardRatio = 2.5

// Entry Validation
MinValidationPoints = 6
UseWeightedScoring = true
H4TrendWeight = 3.0
RiskRewardWeight = 2.0
SessionWeight = 1.5

// Entry Quality
UseEntryGrading = true
SkipGradeD = true

// Exit Strategy
UsePartialExits = true
Partial1_Percent = 50.0
Partial1_RR = 1.5
UseSmartTrailing = true
```

## Key Features Overview

### Risk Management
| Feature | Purpose | Setting |
|---------|---------|---------|
| Dynamic Position Sizing | Adjusts lot size based on performance | Automatic |
| Streak Adjustment | Reduces risk after losses | UseStreakAdjustment = true |
| Drawdown Protection | Scales down at high DD | UseDrawdownAdjustment = true |
| Volatility Adaptation | Adjusts for market conditions | UseVolatilityRiskAdjustment = true |
| Hourly Limits | Prevents overtrading | MaxTradesPerHour = 3 |

### Entry Quality
| Feature | Grade | Action |
|---------|-------|--------|
| Excellent Setup | A (≥8.0) | 120% position size |
| Good Setup | B (6.0-8.0) | 100% position size |
| Acceptable | C (4.0-6.0) | 70% position size |
| Poor Setup | D (<4.0) | Skip if SkipGradeD = true |

### Exit Strategy
| Phase | Action | Default Setting |
|-------|--------|-----------------|
| Initial | Wait for first TP | - |
| Partial 1 | Close 50% at 1.5R | Partial1_Percent/RR |
| Partial 2 | Close 30% at 2.5R | Partial2_Percent/RR |
| Trailing | Smart trailing on remainder | SmartTrailingATRMult = 1.0 |

## Dashboard Quick Reference

### Top Section (Market Structure)
- **H4 Trend**: Current higher timeframe bias
- **H1 Zones**: Number of support/resistance zones detected
- **Order Blocks**: Valid order blocks found
- **FVGs**: Fair value gaps present
- **Asian H/L**: Asian session range levels

### Middle Section (Validation)
- **Validation**: Points achieved / Minimum required
- **Weighted Score**: If UseWeightedScoring = true
- **Points Met**: Which validation criteria passed
- **Session**: Current trading session

### Bottom Section (Performance)
- **Balance**: Current account balance
- **Daily P/L**: Profit/loss for today
- **Trades**: Number of trades today
- **Risk Info**: Adjusted risk %, drawdown %, streak
- **Perf Info**: Expectancy, MAE, MFE metrics
- **Session Stats**: London/NY performance (if enabled)

## Common Adjustments

### Too Many Trades
✅ Increase MinValidationPoints (try 7)
✅ Enable PreferStrongTrend = true
✅ Enable AvoidHighVolatilityRegime = true

### Too Few Trades
✅ Decrease MinValidationPoints (try 5)
✅ Disable PreferStrongTrend
✅ Set UseEssentialOnly = true

### Frequent Stop-Outs
✅ Increase ATR_StopLossMultiplier (try 2.8-3.0)
✅ Enable UseSwingPointSL = true
✅ Check gold volatility levels

### Missing Profits
✅ Increase Partial2_RR (try 3.0)
✅ Increase SmartTrailingATRMult (try 1.2)
✅ Increase TrailingPauseBars (try 5)

### High Drawdown
✅ Reduce RiskPercentage (try 0.75)
✅ Ensure UseDrawdownAdjustment = true
✅ Increase MinValidationPoints
✅ Enable SkipGradeD = true

## Validation Points Explained

| # | Point | Weight | Purpose |
|---|-------|--------|---------|
| 1 | H4 Trend | 3.0x | Higher timeframe bias (CRITICAL) |
| 2 | H1 Zone | 1.0x | At support/resistance level |
| 3 | Break of Structure | 1.0x | M5 BOS confirmation |
| 4 | Liquidity Sweep | 1.0x | Stop hunt reversal |
| 5 | Fair Value Gap | 1.0x | Price imbalance zone |
| 6 | Order Block | 1.0x | Institutional level |
| 7 | ATR Zone | 1.0x | Within acceptable distance |
| 8 | Breakout | 1.0x | Volatility expansion |
| 9 | Asian Level | 1.0x | Near Asian H/L |
| 10 | Valid R:R | 2.0x | Meets minimum ratio (IMPORTANT) |
| 11 | Session | 1.5x | Active trading session |

## Market Regimes

| Regime | Condition | EA Behavior |
|--------|-----------|-------------|
| Strong Trend | Strength > 70% | Normal/increased confidence |
| Weak Trend | Strength 40-70% | Normal trading |
| Ranging | Low directional bias | Reduced confidence |
| High Volatility | ATR > 140% avg | Reduce risk or avoid |
| Consolidation | ATR < 60% avg | Caution on breakouts |

## Confluence Patterns (Bonus Points)

1. **H4Trend + Zone + RR** - Major institutional setup
2. **BOS + Order Block** - Strong structure confirmation
3. **FVG + OB + Zone** - Triple zone confluence
4. **Asian + BOS** - Range breakout setup
5. **H4 + Zone + BOS** - Triple confirmation

## Risk Multipliers

### Streak-Based
- 3+ losses: 50% risk
- 2 losses: 75% risk
- Normal: 100% risk
- 2 wins: 110% risk
- 3+ wins: 120% risk

### Drawdown-Based
- 0-3% DD: 100% risk
- 3-5% DD: 85% risk
- 5-7% DD: 70% risk
- 7%+ DD: 50% risk

### Volatility-Based
- Low vol: 110% risk
- Medium vol: 100% risk
- High vol: 75% risk

## Optimal Trading Hours (GMT)

| Session | Hours | Quality |
|---------|-------|---------|
| Asian | 00:00-08:00 | Low-Medium |
| London | 08:00-17:00 | High |
| New York | 13:00-22:00 | High |
| Overlap | 13:00-16:00 | Very High |

**Avoid**: 22:00-01:00 (dead hours), 07:00-08:00 (choppy)

## Troubleshooting Checklist

### EA Not Opening Trades
- [ ] Check if tradingPaused = true (daily loss limit)
- [ ] Verify MinValidationPoints achievable
- [ ] Check market regime filters
- [ ] Verify spread within limits
- [ ] Confirm active trading session
- [ ] Check entry grade not all D

### Unexpected Behavior
- [ ] Check dashboard for error messages
- [ ] Verify all modules initialized (OnInit)
- [ ] Confirm correct symbol (XAUUSD)
- [ ] Check timeframe (should be M5)
- [ ] Review recent log entries

### Performance Issues
- [ ] Review session statistics
- [ ] Check MAE/MFE metrics
- [ ] Analyze entry grades distribution
- [ ] Verify risk adjustments working
- [ ] Monitor drawdown levels

## Support & Resources

### Files Included
- `SimbaSniperEA.mq5` - Main EA file
- `Include/RiskManager.mqh` - Risk management module
- `Include/PerformanceTracker.mqh` - Analytics module
- `Include/MarketAnalysis.mqh` - Market analysis module
- `Include/TradeExecutor.mqh` - Exit strategy module

### Documentation
- `SIMBA_SNIPER_V2_IMPLEMENTATION.md` - Full implementation guide
- `SIMBA_SNIPER_README.md` - Original README
- This file - Quick reference

## Version Information

**Version**: 2.0
**Release Date**: January 2026
**Compatibility**: MetaTrader 5
**Recommended Symbol**: XAUUSD (Gold)
**Recommended Timeframe**: M5
**Minimum Account**: $1,000 (for 0.01 lot min)

---

For detailed information on architecture, testing procedures, and advanced configuration, refer to `SIMBA_SNIPER_V2_IMPLEMENTATION.md`.
