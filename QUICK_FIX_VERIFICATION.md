# Quick Fix Verification Guide

## ⚡ Quick Check: Is It Fixed?

### SimbaSniperEA - 30 Second Test

1. **Open EA Properties**
   - Look for: `UseIndependentStrategies` - Should be **checked/true** ✅
   - Look for: `EnableAllStrategies` - Should be **checked/true** ✅

2. **Check Dashboard** (top-left of chart)
   - H4 Trend: Should show BULLISH, BEARISH, or NEUTRAL (not stuck on one value)
   - Session: Should show LONDON, NEW YORK, ASIAN, or CLOSED
   - Validation: Should show strategy type like `[FVG]`, `[BOS]`, etc.
   - Status: Should show "ACTIVE" (green) not "PAUSED" (red)

3. **Check Expert Tab** (look for these messages)
   ```
   ========== INDEPENDENT STRATEGIES MODE ACTIVE ==========
   >>> Checking FVG Strategy...
   >>> Checking BOS Strategy...
   ```

### XAUUSDScalpingEA - 30 Second Test

1. **Check Dashboard** (top-left of chart)
   - Session: Should show "Open" during London (8-17 GMT) or NY (13-22 GMT) hours
   - Signal: Should occasionally show BUY or SELL (not always "None")
   - Spread: Should be < 50 points (check your broker's typical XAUUSD spread)
   - Status: Should show "Active" (green)

2. **Check Expert Tab** (look for these messages every hour)
   ```
   No signal: HTF(B:1,b:0,S:0,s:0) MACD(B:0,S:1) BB(BelowL:0,AboveU:1) RSI(OS:0,OB:0)
   ```

3. **When Signal Triggers** (look for)
   ```
   BUY SIGNAL: Condition1=1 Condition2=0 Condition3=0
   BUY order #12345 executed at 2050.50
   ```

## 🚨 Common Issues

### "Still No Trades After 24 Hours"

**SimbaSniperEA**:
- Check session enabled: `TradeLondonSession = true` OR `TradeNewYorkSession = true`
- Check H4 trend not stuck: Should alternate between BULLISH/BEARISH/NEUTRAL
- Try: Set `AllowWeakTrend = true` (more permissive)

**XAUUSDScalpingEA**:
- Check you're testing during London (8-17 GMT) or NY (13-22 GMT) hours
- Check spread not blocking: If broker spread > 50 points, increase `MaxSpreadPoints`
- Review hourly logs to see which conditions are failing

### "Dashboard Not Showing"

Both EAs:
- Check: `ShowPanel = true` (XAUUSDScalpingEA) or `ShowDashboard = true` (SimbaSniperEA)
- Try: Remove EA and re-add to chart (recreates dashboard)
- Check: Panel position on screen (PanelX=20, PanelY=50 should be top-left)

### "Too Many Trades"

**SimbaSniperEA**:
- Disable some strategies: Set `EnableAllStrategies = false`
- Enable only HTF Zone: `Enable_HTFZone_Strategy = true`, others = false
- Increase R:R requirements: `HTFZone_MinRR = 3.0`

**XAUUSDScalpingEA**:
- Already balanced with current settings
- Increase `MinRiskRewardRatio = 2.0` (from 1.5)
- Disable one session: Set `TradeNewYorkSession = false` (keep London only)

## ✅ Success Indicators

You'll know it's working when:

1. **Dashboard Updates** every few seconds with current market data
2. **Expert Tab** shows periodic analysis messages
3. **Trades Execute** within first 24-48 hours (during active sessions)
4. **Signal Generation**: See "BUY SIGNAL" or "SELL SIGNAL" messages in logs

## 📊 Expected Performance

| EA | Trades/Day | Win Rate Target | R:R Ratio |
|----|------------|----------------|-----------|
| SimbaSniperEA | 2-10+ | 45-55% | 2.5:1 |
| XAUUSDScalpingEA | 2-5 | 45-55% | 1.5:1 |

## 🔧 Quick Fixes

### If H4 Trend Always NEUTRAL (SimbaSniperEA)
```
H4TrendMode = TREND_SIMPLE  // Not STRICT
AllowWeakTrend = true
```

### If Spread Too High
```
MaxSpreadPoints = 100  // Increase from default 30-50
// OR
UseSpreadFilter = false  // Disable temporarily to test
```

### If Session Times Wrong
```
SessionGMTOffset = [YOUR_BROKER_GMT_OFFSET]
// Example: If broker is GMT+2, set = 2
// Example: If broker is GMT-5, set = -5
```

## 📞 Still Having Issues?

1. Read full documentation: `STRATEGY_FIX_SUMMARY.md`
2. Check troubleshooting guides in repo
3. Enable detailed logging:
   ```
   EnableDetailedLogging = true  // SimbaSniperEA
   LogAllStrategies = true       // SimbaSniperEA
   ```
4. Share Expert tab logs for diagnosis

## 🎯 Bottom Line

**Before Fix**:
- ❌ 0 trades per day (strategies disabled/too strict)
- ❌ Dashboard showing but no activity
- ❌ "No signal" every check

**After Fix**:
- ✅ 2-10 trades per day (strategies enabled/balanced)
- ✅ Dashboard showing active analysis
- ✅ Regular signal generation and trade execution

---

**Last Updated**: 2026-01-05  
**Version**: Post-Strategy Fix  
**Status**: Production Ready ✅
