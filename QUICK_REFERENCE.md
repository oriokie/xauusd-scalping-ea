# Quick Reference Guide - XAUUSD Scalping EA

## Installation (30 seconds)

1. Copy `XAUUSDScalpingEA.mq5` to MT5 `Experts` folder
2. Compile in MetaEditor (F7)
3. Drag onto XAUUSD chart
4. Enable "Auto Trading" button
5. Done! ✅

## Default Settings (Conservative)

```
Risk: 1% per trade
Daily Loss Limit: 5%
Max Spread: 50 points
Take Profit: 1.5 × ATR
Stop Loss: 1.0 × ATR
Trailing Stop: Enabled
Max Positions: 1
```

## Quick Start Checklist

- [ ] EA compiled successfully
- [ ] Attached to XAUUSD chart (M5 or M15)
- [ ] Auto Trading enabled (green button)
- [ ] Session times match your broker's GMT offset
- [ ] Risk percentage set (1% recommended)
- [ ] GUI panel visible and showing "Active"
- [ ] Demo tested for 2+ weeks before live

## GUI Panel - What Everything Means

| Display | Meaning |
|---------|---------|
| **Status: Active** 🟢 | EA is trading normally |
| **Status: Paused** 🔴 | Daily loss limit reached |
| **Balance** | Current account balance |
| **Daily P/L** | Today's profit/loss |
| **Trades Today** | Number of trades executed |
| **Win Rate** | % of winning trades |
| **Open Positions** | Currently active trades |
| **Spread** | Current market spread |
| **Session: Open** 🟢 | Within trading hours |
| **Session: Closed** 🟠 | Outside trading hours |
| **ATR** | Current volatility measure |
| **MACD: Bullish** 🟢 | Upward momentum |
| **MACD: Bearish** 🔴 | Downward momentum |
| **RSI: Oversold** 🟢 | Below 30 (buy opportunity) |
| **RSI: Overbought** 🔴 | Above 70 (sell opportunity) |
| **RSI: Neutral** ⚪ | Between 30-70 |
| **Signal: BUY** 🟢 | Buy conditions met |
| **Signal: SELL** 🔴 | Sell conditions met |
| **Signal: None** ⚪ | No clear signal |

## Common Adjustments

### More Conservative
```
RiskPercentage: 0.5%
SL_ATR_Multiplier: 1.5
MinStopLossPoints: 40
MaxPositions: 1
```

### More Aggressive
```
RiskPercentage: 1.5%
TP_ATR_Multiplier: 1.2
MaxPositions: 2
```

### Faster Signals
```
MACD_Fast: 8
MACD_Slow: 17
BB_Period: 15
RSI_Period: 9
```

### Slower, More Reliable
```
MACD_Fast: 16
MACD_Slow: 32
BB_Period: 25
RSI_Period: 21
```

## Trading Sessions (Adjust for Your Broker)

**If your broker is GMT+2:**
```
LondonStartHour: 10    (8 + 2)
LondonEndHour: 19      (17 + 2)
NewYorkStartHour: 15   (13 + 2)
NewYorkEndHour: 0      (22 + 2)
```

**If your broker is GMT-5 (EST):**
```
LondonStartHour: 3     (8 - 5)
LondonEndHour: 12      (17 - 5)
NewYorkStartHour: 8    (13 - 5)
NewYorkEndHour: 17     (22 - 5)
```

## Troubleshooting (Quick Fixes)

| Problem | Solution |
|---------|----------|
| **EA not trading** | ✓ Check Auto Trading is ON<br>✓ Verify session times<br>✓ Check spread < 50 |
| **Lot size too small** | ✓ Increase account balance<br>✓ Reduce risk %<br>✓ Widen stop loss |
| **Too many losses** | ✓ Increase SL multiplier<br>✓ Reduce trading during Asian session<br>✓ Check spread costs |
| **GUI not showing** | ✓ Set ShowPanel = true<br>✓ Reattach EA to chart<br>✓ Restart MT5 |
| **Compilation error** | ✓ Update to latest MT5<br>✓ Ensure using MT5 (not MT4) |

## Key Numbers to Know

### XAUUSD Specifics
- **Point Value:** 0.01
- **Typical Spread:** 20-40 points
- **Best Trading Hours:** 08:00-17:00 GMT (London)
- **High Volatility Events:** US NFP, FOMC, CPI
- **Average ATR:** 6-12 (normal), 15+ (high volatility)

### Risk Guidelines
- **Minimum Account:** $1,000 recommended
- **Maximum Risk:** Never exceed 2% per trade
- **Daily Loss Limit:** 5% is conservative, 3% very conservative
- **Maximum Drawdown:** Exit strategy if exceeds 10%

## Performance Expectations

### Realistic Goals (Conservative Settings)
- **Win Rate:** 55-65%
- **Profit Factor:** 1.4-2.0
- **Monthly Return:** 5-15%
- **Max Drawdown:** 5-10%
- **Trades per Day:** 3-8

### Warning Signs
- Win rate < 50% for 2+ weeks → Review settings
- Daily loss limit hit 3+ times in week → Reduce risk
- Drawdown > 10% → Stop and reassess

## News Events to Avoid

**High Impact (30-60 min buffer):**
- 📊 US Non-Farm Payrolls (First Friday)
- 📈 FOMC Interest Rate Decision
- 💰 US CPI (Inflation Data)
- 📉 US GDP Reports
- 💬 FOMC Meeting Minutes

**Medium Impact (15-30 min buffer):**
- US Unemployment Claims
- US Retail Sales
- PMI Manufacturing Data
- Central Bank Speeches

## Best Practices (5 Rules)

1. **Always Demo Test First**
   - Minimum 2 weeks on demo
   - Test different market conditions
   - Verify all features work

2. **Start Small**
   - Begin with 0.5% risk
   - Use 1 position max initially
   - Gradually increase as confident

3. **Monitor Daily**
   - Check GUI panel each day
   - Review trade logs
   - Watch for unusual behavior

4. **Use VPS for 24/7**
   - Low latency to broker
   - 99.9% uptime
   - Prevents missed opportunities

5. **Keep Records**
   - Daily P/L tracking
   - Win rate calculations
   - Parameter changes log
   - Market condition notes

## Support & Resources

- **Full Manual:** See README.md
- **User Guide:** See USER_GUIDE.md
- **Advanced Config:** See ADVANCED_GUIDE.md
- **Report Issues:** GitHub Issues
- **Economic Calendar:** forexfactory.com

## Quick Command Reference

### Check EA Status
- Look at chart (smile icon = running)
- Check GUI panel (Active/Paused)
- Review Experts log (Ctrl+T)

### Restart EA
1. Remove EA from chart
2. Reattach EA to chart
3. Verify settings
4. Enable Auto Trading

### Emergency Stop
1. Click Auto Trading button (turns red)
2. EA stops taking new positions
3. Existing positions remain open

### Daily Maintenance
- Review yesterday's trades
- Check daily P/L
- Verify session times still correct
- Update news events if using filter

## Version Check

**Current Version:** 1.2.0

Check for updates:
- Visit GitHub repository
- Review CHANGELOG.md
- Download latest version

---

## Contact & Support

- **Issues:** Open on GitHub
- **Questions:** Create Discussion
- **Contributions:** See CONTRIBUTING.md

---

**Remember:** This is a tool to assist trading, not a magic money machine. Always use proper risk management and never risk more than you can afford to lose.

**Good Trading! 📈**
