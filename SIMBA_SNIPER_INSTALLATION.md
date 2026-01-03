# Simba Sniper EA - Installation & Testing Guide

## Prerequisites

### Software Requirements
- MetaTrader 5 (latest build recommended)
- Active trading account (demo or live)
- Minimum 1GB RAM
- Stable internet connection
- VPS recommended for 24/7 operation (optional)

### Account Requirements
- Minimum balance: $100 (demo), $500+ (live recommended)
- Broker must allow automated trading (Expert Advisors)
- Broker must support XAUUSD (Gold) trading
- Low spread broker recommended (<30 points average)

## Installation Steps

### Step 1: Locate MT5 Data Folder
1. Open MetaTrader 5
2. Click **File** → **Open Data Folder**
3. A Windows Explorer window opens
4. Navigate to **MQL5** → **Experts** folder

### Step 2: Copy EA File
1. Copy `SimbaSniperEA.mq5` from repository
2. Paste into the **Experts** folder from Step 1
3. Keep the file name as `SimbaSniperEA.mq5`

### Step 3: Compile the EA
1. In MT5, press **F4** to open MetaEditor
2. In Navigator (left panel), expand **Experts**
3. Double-click **SimbaSniperEA** to open
4. Press **F7** or click **Compile** button
5. Check compilation results:
   - **Success**: "0 error(s), 0 warning(s)"
   - **Failure**: Review errors, ensure all dependencies available

### Step 4: Attach to Chart
1. In MT5, open a chart (any timeframe - EA uses its own)
2. Recommended: **XAUUSD** (Gold)
3. In Navigator (Ctrl+N), expand **Expert Advisors**
4. Drag **SimbaSniperEA** onto the chart
5. Input parameters dialog appears

### Step 5: Configure Initial Parameters
**Critical Settings to Review:**

```
=== Multi-Timeframe Analysis ===
H4_Timeframe = PERIOD_H4  ✓ Keep default
H1_Timeframe = PERIOD_H1  ✓ Keep default
M5_Timeframe = PERIOD_M5  ✓ Keep default
M1_Timeframe = PERIOD_M1  ✓ Keep default
UseM1Precision = false     ✓ Keep false initially

=== Risk Management ===
RiskPercentage = 1.0       ✓ Start with 0.5-1.0%
MaxDailyLossPercent = 3.0  ✓ Safe default
MinRiskRewardRatio = 2.0   ✓ Good default
MaxPositions = 1           ✓ Keep at 1 initially

=== Trading Sessions ===
SessionGMTOffset = 0       ⚠️ SET THIS FOR YOUR BROKER!
```

**How to Find Your Broker's GMT Offset:**
- Most brokers: GMT+2 (winter) or GMT+3 (summer)
- Set `SessionGMTOffset = -2` if broker is GMT+2
- Set `SessionGMTOffset = -3` if broker is GMT+3
- Set `SessionGMTOffset = 0` if broker is pure GMT

### Step 6: Enable AutoTrading
1. Click **AutoTrading** button in toolbar (or press **Ctrl+E**)
2. Button should be **GREEN** and **pressed in**
3. If disabled, EA cannot place trades

### Step 7: Verify Initialization
1. Open **Experts** tab (View → Toolbox → Experts)
2. Look for message: `"Simba Sniper EA initialized successfully"`
3. Check for: `"Multi-Timeframe Analysis: H4->H1->M5"`
4. If errors appear, review error messages

### Step 8: Confirm Dashboard Display
1. Dashboard should appear on chart (top-left by default)
2. Title: **SIMBA SNIPER EA**
3. Subtitle: **Multi-Timeframe Institutional**
4. All fields should populate with data
5. If not visible, check `ShowDashboard = true`

## Testing Protocol

### Phase 1: Visual Inspection (1-2 Hours)

**Objective**: Verify EA is running and updating correctly

1. **Dashboard Check**:
   - H4 Trend updates (Bullish/Bearish/Neutral)
   - Zone counters update
   - ATR values populate
   - Session status changes with time

2. **Console Messages**:
   - Open Experts tab
   - Should see periodic updates
   - No error messages

3. **Validation Tracking**:
   - Watch "Entry Validation" score
   - See which points are met
   - Understand scoring logic

**Expected Behavior**:
- Dashboard updates every M5 bar
- H4 Trend changes gradually (not every bar)
- Validation score varies 0-9
- Session status matches real time

### Phase 2: Strategy Tester (1-2 Days)

**Objective**: Backtest historical performance

**Setup**:
1. Open Strategy Tester (View → Strategy Tester)
2. Expert Advisor: **SimbaSniperEA**
3. Symbol: **XAUUSD**
4. Period: **M5** (EA will access H4/H1 internally)
5. Date: Last 6 months minimum
6. Execution: **Every tick** (most accurate)
7. Optimization: **Disabled** (for initial test)

**Parameters for Testing**:
```
Conservative Test:
- RiskPercentage = 0.5
- MinValidationPoints = 7
- All required validations = true

Moderate Test:
- RiskPercentage = 1.0
- MinValidationPoints = 6
- Default settings

Aggressive Test:
- RiskPercentage = 1.5
- MinValidationPoints = 5
- Optional validations = false
```

**What to Analyze**:
1. **Total Trades**: Should have some trades (not zero, not excessive)
2. **Win Rate**: Target 50-65%
3. **Profit Factor**: Target > 1.5
4. **Max Drawdown**: Should be < 15%
5. **Risk/Reward**: Average win should be > 2× average loss

**Red Flags**:
- Zero trades → Too strict validation
- Excessive trades → Too loose validation
- Win rate < 40% → Review parameters
- Drawdown > 20% → Reduce risk

### Phase 3: Demo Account (2-4 Weeks)

**Objective**: Real-time market validation

**Setup**:
1. Open demo account with broker
2. Fund with realistic amount ($1,000-$10,000)
3. Attach EA to XAUUSD chart
4. Configure as tested in Strategy Tester
5. Let run continuously

**Daily Monitoring**:
- Check dashboard statistics
- Review trade journal
- Verify validation scoring
- Monitor for errors

**Weekly Review**:
- Win rate tracking
- Risk/Reward analysis
- Drawdown monitoring
- Parameter adjustments if needed

**Success Criteria**:
- Positive net profit over 2-4 weeks
- Win rate 50%+
- Max drawdown <10%
- No critical errors
- Validation system working as expected

### Phase 4: Live Micro Lots (4+ Weeks) - OPTIONAL

**Objective**: Live market validation with minimal risk

**Only proceed if**:
- Demo testing successful
- Understand strategy completely
- Prepared for losses
- Have risk capital available

**Setup**:
1. Fund live account (minimum $500, recommended $1000+)
2. Start with 0.01 lot sizes
3. Use conservative parameters:
   ```
   RiskPercentage = 0.5
   MaxDailyLossPercent = 2.0
   MinValidationPoints = 7
   ```
4. Monitor DAILY

**Gradual Scaling**:
- Week 1-2: 0.01 lots
- Week 3-4: 0.02 lots (if profitable)
- Week 5-8: 0.03 lots (if profitable)
- Continue gradual increase

## Verification Checklist

Before going live, verify:

- [ ] EA compiled without errors
- [ ] Dashboard displays correctly
- [ ] H4 trend detection working
- [ ] H1 zones being identified
- [ ] Order blocks being detected
- [ ] Fair value gaps being found
- [ ] Validation scoring updating
- [ ] Session filter working (time-based)
- [ ] Risk management calculations correct
- [ ] Stop loss placement appropriate
- [ ] Take profit placement appropriate
- [ ] Lot size calculation accurate
- [ ] Daily loss limit functional
- [ ] Backtest results acceptable
- [ ] Demo test results positive
- [ ] No persistent error messages
- [ ] Understand all parameters
- [ ] Know how to adjust if needed
- [ ] VPS setup (if using 24/7)
- [ ] Broker confirmed EA-friendly

## Common Issues & Solutions

### Issue 1: EA Not Trading
**Symptoms**: Dashboard shows data but no trades execute

**Checks**:
1. H4 Trend showing NEUTRAL?
   - **Solution**: Wait for trend to develop
2. Validation score below minimum?
   - **Solution**: Lower MinValidationPoints or wait
3. Session status CLOSED?
   - **Solution**: Check SessionGMTOffset setting
4. Status showing PAUSED?
   - **Solution**: Daily loss limit hit, wait for new day
5. Required validations not met?
   - **Solution**: Review which required checks failing

### Issue 2: Too Many Trades
**Symptoms**: EA trading excessively, poor results

**Solutions**:
- Increase `MinValidationPoints` to 7 or 8
- Enable more required validations
- Increase `MinDisplacementPercent`
- Increase `SwingLookback` period
- Disable optional validations (Sweep, FVG)

### Issue 3: Constant Stop Losses
**Symptoms**: Trades executing but hitting SL frequently

**Solutions**:
- Increase `ATR_StopLossMultiplier` to 2.0 or 2.5
- Check broker spread isn't too wide
- Verify ATR values are reasonable
- Consider trading only London/NY overlap
- Review if H4 trend changes mid-trade

### Issue 4: Dashboard Not Showing
**Symptoms**: EA running but no dashboard visible

**Solutions**:
- Set `ShowDashboard = true`
- Adjust `DashboardX` and `DashboardY` (try 50, 50)
- Check for object creation errors in log
- Restart MT5 and reattach EA
- Remove other EAs/indicators that might conflict

### Issue 5: Compilation Errors
**Symptoms**: F7 in MetaEditor shows errors

**Common Fixes**:
- Ensure using MT5 (not MT4)
- Update MT5 to latest build
- Check Trade library available
- Verify file saved as `.mq5` not `.mq4`
- Copy code again from source

### Issue 6: No H4 Trend Detected
**Symptoms**: H4 Trend always shows NEUTRAL

**Checks**:
- Enough H4 bars in history? (Need 25+)
- `SwingLookback` appropriate? (Try 15-25)
- Market truly choppy/ranging?
- `MinDisplacementPercent` too high? (Try 0.2-0.3)

### Issue 7: Validation Always Low
**Symptoms**: Validation score stuck at 2-3/9

**Solutions**:
- Reduce `ATR_ZoneMultiplier` to allow wider zone matching
- Decrease `FVG_MinGapPoints` to detect more FVGs
- Adjust `OrderBlockBars` for different detection
- Check if H1 zones being detected (count should be > 0)

## Parameter Optimization Guide

### Optimization Process
1. **Baseline Test**: Run with default parameters
2. **Single Variable**: Change one parameter at a time
3. **Measure Impact**: Compare results to baseline
4. **Document**: Keep notes on what works
5. **Combine**: Integrate successful changes

### Key Parameters to Optimize

**Risk Parameters**:
- `RiskPercentage`: 0.5% → 1.0% → 1.5% → 2.0%
- `MaxDailyLossPercent`: 2% → 3% → 5%
- `ATR_StopLossMultiplier`: 1.0 → 1.5 → 2.0 → 2.5

**Validation Parameters**:
- `MinValidationPoints`: 5 → 6 → 7 → 8
- Toggle required validations on/off
- Test with/without optional validations

**Structure Detection**:
- `SwingLookback`: 15 → 20 → 25 → 30
- `MinDisplacementPercent`: 0.2 → 0.3 → 0.4 → 0.5
- `OrderBlockBars`: 3 → 5 → 7
- `FVG_MinGapPoints`: 10 → 20 → 30

### Optimization Best Practices
- Use 6+ months of data
- Test different market conditions (trending, ranging)
- Validate on out-of-sample data
- Don't over-optimize (curve fitting)
- Keep results realistic

## Performance Monitoring

### Daily Checks
- [ ] Dashboard displaying correctly
- [ ] No error messages
- [ ] Trades executing as expected
- [ ] Risk management working
- [ ] Daily P/L reasonable

### Weekly Review
- [ ] Calculate win rate
- [ ] Review trade journal
- [ ] Check average R:R ratio
- [ ] Monitor drawdown
- [ ] Adjust parameters if needed

### Monthly Analysis
- [ ] Total profit/loss
- [ ] Compare to backtest expectations
- [ ] Review major losing trades
- [ ] Identify improvement areas
- [ ] Update trading journal

## Risk Management Reminders

⚠️ **Critical Rules**:
1. **Never** risk more than you can afford to lose
2. **Always** test on demo first (minimum 2 weeks)
3. **Start** with minimum risk percentage (0.5%)
4. **Monitor** daily for first month
5. **Use** VPS for 24/7 operation
6. **Set** correct SessionGMTOffset
7. **Understand** the strategy before trading
8. **Keep** trading journal
9. **Review** performance regularly
10. **Stop** if consistent losses occur

## Support & Resources

### Getting Help
1. Review full documentation: `SIMBA_SNIPER_README.md`
2. Check quick reference: `SIMBA_SNIPER_QUICK_REFERENCE.md`
3. Read Experts log for errors
4. Take screenshots of issues
5. Document problem thoroughly

### Additional Learning
- Study Order Block concepts
- Research Fair Value Gaps
- Learn ICT (Inner Circle Trader) concepts
- Understand institutional trading
- Practice on demo extensively

## Final Checklist

Before considering EA "ready":

- [ ] ✅ Installation complete
- [ ] ✅ Compilation successful (0 errors)
- [ ] ✅ Dashboard functioning
- [ ] ✅ SessionGMTOffset configured
- [ ] ✅ Visual inspection passed
- [ ] ✅ Backtest completed (6+ months)
- [ ] ✅ Backtest results acceptable
- [ ] ✅ Demo test running (2-4 weeks)
- [ ] ✅ Demo results positive
- [ ] ✅ All parameters understood
- [ ] ✅ Risk management in place
- [ ] ✅ Monitoring system established
- [ ] ✅ Trading journal ready
- [ ] ✅ Emergency plan defined

**Only then consider live trading with micro lots!**

---

**Good luck with your testing!** 🦁🎯

Remember: Patience and discipline are key to successful automated trading.
