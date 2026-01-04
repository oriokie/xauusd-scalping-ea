# Independent Strategies - Quick Troubleshooting Guide

## Quick Setup Checklist

- [ ] Set `UseIndependentStrategies = true`
- [ ] Enable at least one strategy (`Enable_XXX_Strategy = true`)
- [ ] Ensure trading session is active
- [ ] Check H4 trend is not NEUTRAL
- [ ] Verify spread is acceptable
- [ ] Enable logging to diagnose issues

## Common Error Messages

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Not in active trading session" | Current time outside session hours | Check session settings (London/NY/Asian) |
| "H4 Trend is NEUTRAL" | No clear trend direction | Wait for trending market or enable `AllowWeakTrend` |
| "Spread too high" | Market spread exceeds limit | Adjust `MaxSpreadPoints` or disable spread filter |
| "No valid signal from enabled strategies" | All strategies failed criteria | Enable logging to see which criteria failed |
| "Independent strategies: No valid signal" | No strategy is enabled | Enable at least one strategy |

## Strategy Requirements at a Glance

### FVG Strategy
**Must Have:**
- H4 trend (Bullish or Bearish)
- FVG detected on H1
- Price within FVG bounds
- Minimum R:R (default: 2.0)

**Optional:**
- Fresh FVG (< 20 bars old)
- Rejection candle pattern

### BOS Strategy
**Must Have:**
- H4 trend (Bullish or Bearish)
- Break of Structure on M5
- Minimum R:R (default: 2.0)

**Optional:**
- Volume expansion (1.5x average)
- Proximity to H1 zone

### HTF Zone Strategy
**Must Have:**
- H4 trend (Bullish or Bearish)
- H1 zone present
- Minimum touches (default: 3)
- Minimum strength (default: 1.0)
- Minimum R:R (default: 2.5)

**Optional:**
- Rejection candle (wick > 2x body)

### Order Block Strategy
**Must Have:**
- H4 trend (Bullish or Bearish)
- Order Block on H1
- Price within OB range
- Minimum R:R (default: 2.0)

**Optional:**
- Untested blocks only
- FVG within OB

### Breakout Strategy
**Must Have:**
- H4 trend (Bullish or Bearish)
- Asian session levels valid
- London or NY session active
- Break of Asian range
- Minimum R:R (default: 1.5)

**Optional:**
- Volume expansion (1.5x average)
- ATR expansion (1.5x average)

## Log Analysis Patterns

### No Signal (All Strategies)
**Pattern in Logs:**
```
>>> Checking FVG Strategy...
========== FVG STRATEGY: NO FVGs FOUND ==========
>>> Checking BOS Strategy...
========== BOS STRATEGY: NO BOS DETECTED ==========
...
========== NO STRATEGY SIGNAL FOUND ==========
```

**Action:** Market conditions don't match any strategy. This is normal. Wait for better setup.

### Failing Early Checks
**Pattern in Logs:**
```
========== FVG STRATEGY ANALYSIS START ==========
[FVG] FAIL - H4 Trend is NEUTRAL | Required: Bullish or Bearish trend
```

**Action:** Check early filters:
- H4 trend direction
- Market structure
- Volatility conditions

### Failing Final Check (R:R)
**Pattern in Logs:**
```
[FVG] PASS - Trend Alignment | Bullish FVG with Bullish Trend
[FVG] FAIL - Risk/Reward Check | R:R 1.80 (Min: 2.00)
```

**Action:** 
- Reduce minimum R:R for that strategy, OR
- Accept that market doesn't offer good R:R currently

### Volume/ATR Expansion Failures
**Pattern in Logs:**
```
[BOS] FAIL - Volume Expansion | Required multiplier: 1.5x
[Breakout] FAIL - ATR Expansion | Current ATR: 15.20, Required: 22.50
```

**Action:**
- Disable volume/ATR requirements if too strict, OR
- Reduce multiplier values, OR
- Wait for higher volatility/volume

## Quick Fixes

### Not Getting Any Trades
1. **Enable All Strategies**
   ```
   EnableAllStrategies = true
   ```

2. **Reduce R:R Requirements**
   ```
   FVG_MinRR = 1.5
   BOS_MinRR = 1.5
   HTFZone_MinRR = 2.0
   OB_MinRR = 1.5
   Breakout_MinRR = 1.2
   ```

3. **Disable Optional Filters**
   ```
   FVG_RequireRejection = false
   FVG_RequireFresh = false
   BOS_RequireVolumeExpansion = false
   HTFZone_RequireRejection = false
   Breakout_RequireATRExpansion = false
   ```

### Getting Too Many Bad Trades
1. **Enable Fewer Strategies**
   ```
   EnableAllStrategies = false
   Enable_HTFZone_Strategy = true  // Most reliable
   ```

2. **Increase R:R Requirements**
   ```
   HTFZone_MinRR = 3.0
   ```

3. **Enable Stricter Filters**
   ```
   HTFZone_RequireRejection = true
   HTFZone_MinTouches = 4
   HTFZone_MinStrength = 1.5
   ```

### Trades Not Executing During Session
1. **Check Session Times Match Broker GMT**
   ```
   SessionGMTOffset = [YOUR_BROKER_OFFSET]
   ```

2. **Verify Session is Enabled**
   ```
   TradeLondonSession = true
   TradeNewYorkSession = true
   ```

3. **Check Session-Specific Requirements**
   - Breakout strategy requires London or NY session
   - If `AsianRangeBound = true`, no breakouts in Asian session

## Diagnostic Log Levels

**Minimal Logging** (Production):
```
EnableDetailedLogging = false
LogFVGStrategy = false
LogBOSStrategy = false
LogHTFZoneStrategy = false
LogOBStrategy = false
LogBreakoutStrategy = false
LogStrategyCriteria = false
```

**Moderate Logging** (Live Monitoring):
```
EnableDetailedLogging = true
LogFVGStrategy = false
LogBOSStrategy = false
LogHTFZoneStrategy = false
LogOBStrategy = false
LogBreakoutStrategy = false
LogStrategyCriteria = false  // Only log which strategy triggers
```

**Full Diagnostic** (Debugging):
```
EnableDetailedLogging = true
LogFVGStrategy = true
LogBOSStrategy = true
LogHTFZoneStrategy = true
LogOBStrategy = true
LogBreakoutStrategy = true
LogStrategyCriteria = true  // Log every check
```

## Performance Tips

1. **Disable logging in production** - Reduces overhead
2. **Enable only needed strategies** - Faster analysis
3. **Use appropriate R:R ratios** - Balance quantity vs quality
4. **Match strategies to market conditions**:
   - Trending: BOS, Breakout, HTF Zone
   - Ranging: HTF Zone, Order Block, FVG

## Contact & Support

For persistent issues:
1. Enable full diagnostic logging
2. Copy relevant log section from Expert tab
3. Note your configuration (input parameters)
4. Report issue with logs and configuration
