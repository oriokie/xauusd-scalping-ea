# XAUUSD Scalping EA - User Guide

## Table of Contents
1. [Quick Start Guide](#quick-start-guide)
2. [Understanding the Strategy](#understanding-the-strategy)
3. [Parameter Configuration](#parameter-configuration)
4. [GUI Panel Guide](#gui-panel-guide)
5. [Risk Management](#risk-management)
6. [Trading Sessions](#trading-sessions)
7. [News Filter Setup](#news-filter-setup)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Quick Start Guide

### Step 1: Installation
1. Open MetaTrader 5
2. Press `F4` to open MetaEditor
3. Navigate to `File > Open Data Folder`
4. Go to `MQL5 > Experts`
5. Copy `XAUUSDScalpingEA.mq5` to this folder
6. Return to MetaEditor and compile the file (F7)

### Step 2: Initial Setup
1. Open a XAUUSD chart (M5 or M15 recommended)
2. Drag the EA from Navigator window onto the chart
3. In the settings dialog:
   - Set `RiskPercentage` to 1.0% (conservative) or 0.5% (very conservative)
   - Verify session times match your broker's server time
   - Enable `ShowPanel` to see the information display
   - Click OK

### Step 3: Enable Auto Trading
1. Click the "Auto Trading" button in MT5 toolbar (should turn green)
2. Verify EA is running (smile icon in top-right of chart)
3. Monitor the GUI panel for status updates

## Understanding the Strategy

### Core Concept
This EA is designed for **scalping** - taking small, frequent profits from XAUUSD price movements. It focuses on:
- Quick entries at optimal price points
- Small but consistent profit targets
- Strict risk management
- High win rate through selective entries

### Entry Conditions
The EA enters a trade when **multiple conditions align**:

#### Buy Signal Requirements:
1. **Liquidity Sweep Detection**: Price breaks below previous low, then reverses up sharply
   - OR MACD crosses above signal line while price is below lower Bollinger Band
2. **Price Position**: Price is near or below lower Bollinger Band
3. **Session Active**: Within London or New York session hours
4. **Spread Check**: Current spread is below maximum threshold
5. **No News**: Not within news buffer time window

#### Sell Signal Requirements:
1. **Liquidity Sweep Detection**: Price breaks above previous high, then reverses down sharply
   - OR MACD crosses below signal line while price is above upper Bollinger Band
2. **Price Position**: Price is near or above upper Bollinger Band
3. **Session Active**: Within London or New York session hours
4. **Spread Check**: Current spread is below maximum threshold
5. **No News**: Not within news buffer time window

### Exit Strategy
The EA can exit positions through multiple methods:

1. **Take Profit Hit**: Price reaches TP level (ATR × TP_Multiplier)
2. **Stop Loss Hit**: Price reaches SL level (ATR × SL_Multiplier)
3. **Trailing Stop**: SL adjusts as price moves favorably
4. **Mean Reversion**: Price returns to Bollinger Bands middle line (when enabled)
5. **Daily Loss Limit**: All positions closed if daily loss limit reached

## Parameter Configuration

### Basic Settings (Recommended for Beginners)

```
Risk Management:
- RiskPercentage: 1.0%
- MaxDailyLossPercent: 5.0%
- MaxSpreadPoints: 50

Indicator Settings:
- Keep defaults (MACD: 12/26/9, BB: 20/2.0, ATR: 14)

Trade Settings:
- TP_ATR_Multiplier: 1.5
- SL_ATR_Multiplier: 1.0
- MinStopLossPoints: 30 (prevents too-tight stops)
- MinRiskRewardRatio: 1.5 (ensures favorable risk/reward)
- UseTrailingStop: true
- TrailingStopATR: 1.0

Trading Sessions:
- TradeLondonSession: true
- TradeNewYorkSession: true
(Adjust hours based on your broker's GMT offset)

Scalping Settings:
- MinProfitPoints: 20
- UseMeanReversion: true
- MaxPositions: 1
```

### Advanced Settings (For Experienced Traders)

#### More Aggressive Approach:
- RiskPercentage: 1.5-2.0%
- TP_ATR_Multiplier: 1.2 (quicker profits)
- MaxPositions: 2-3
- MinProfitPoints: 15

#### More Conservative Approach:
- RiskPercentage: 0.5%
- SL_ATR_Multiplier: 1.5 (wider stops)
- MinStopLossPoints: 40 (larger minimum)
- TP_ATR_Multiplier: 2.0 (larger targets)
- MaxPositions: 1
- MinProfitPoints: 30

### Indicator Fine-Tuning

#### For Faster Signals:
- MACD_Fast: 8
- MACD_Slow: 17
- BB_Period: 15

#### For Slower, More Reliable Signals:
- MACD_Fast: 16
- MACD_Slow: 32
- BB_Period: 25

## GUI Panel Guide

### Panel Layout
```
┌─────────────────────────────────┐
│ XAUUSD SCALPING EA              │
│ Status: Active/Paused           │
│ Balance: $10,000.00             │
│ Daily P/L: +$150.00             │
│ Trades Today: 8                 │
│ Win Rate: 75.0%                 │
│ Open Positions: 1               │
│ Spread: 25.0                    │
│ Session: Open/Closed            │
│ ATR: 8.50                       │
│ MACD: Bullish/Bearish          │
│ Signal: BUY/SELL/None          │
│ [Error messages]                │
└─────────────────────────────────┘
```

### Understanding Panel Information

**Status Colors:**
- 🟢 Green (Active): EA is trading normally
- 🔴 Red (Paused): Trading paused due to daily loss limit

**Daily P/L Colors:**
- 🟢 Green: Positive profit for the day
- 🔴 Red: Negative profit for the day

**Session Colors:**
- 🟢 Green (Open): Within trading session hours
- 🟠 Orange (Closed): Outside trading hours

**MACD Indicator:**
- 🟢 Bullish: MACD above signal line
- 🔴 Bearish: MACD below signal line

**Signal:**
- 🟢 BUY: Buy conditions met
- 🔴 SELL: Sell conditions met
- ⚪ None: No clear signal

### Customizing Panel Position
```
ShowPanel: true
PanelX: 20    // Distance from left (pixels)
PanelY: 50    // Distance from top (pixels)
PanelColor: clrNavy
TextColor: clrWhite
```

## Risk Management

### Understanding Risk Percentage
The `RiskPercentage` parameter determines how much of your account you risk per trade.

**Example Calculation:**
- Account Balance: $10,000
- Risk Percentage: 1.0%
- Risk Amount: $100 per trade
- Stop Loss Distance: 100 points (10 pips for XAUUSD)
- Calculated Lot Size: ~0.10 lots (will vary based on broker)

### Daily Loss Limit
The `MaxDailyLossPercent` protects your account from significant drawdown.

**How It Works:**
- At day start: Balance = $10,000
- Max Daily Loss: 5.0%
- Loss Threshold: $500

If account drops to $9,500 or below during the day, EA pauses trading until next day.

### Position Sizing Formula
```
Lot Size = (Account Balance × Risk%) / (Stop Loss Distance × Point Value)
```

The EA automatically:
- Calculates optimal lot size
- Respects broker's minimum/maximum lot sizes
- Rounds to broker's lot step (e.g., 0.01)

### Risk Management Best Practices
1. **Start Small**: Begin with 0.5% risk until comfortable
2. **Monitor Daily Loss**: Watch for patterns if hitting daily limit often
3. **Adjust for Volatility**: Reduce risk during high volatility periods
4. **Never Override**: Don't manually increase lot sizes beyond EA calculation
5. **Account Size**: Minimum $1,000 recommended for XAUUSD trading

## Trading Sessions

### Understanding GMT Offset
Your broker's server time may differ from GMT. Find your offset:
1. Open MT5, check server time
2. Compare to current GMT time
3. Calculate difference (e.g., GMT+2, GMT-5)

### Adjusting Session Times
If your broker is GMT+2:
- London Session: 10:00-19:00 (add 2 hours to default)
- New York Session: 15:00-00:00 (add 2 hours to default)

**Configuration:**
```
LondonStartHour: 10
LondonEndHour: 19
NewYorkStartHour: 15
NewYorkEndHour: 0    // Midnight = 0
```

### Session Overlap
The most volatile (and profitable) period is typically when sessions overlap:
- London/New York Overlap: ~13:00-17:00 GMT

### Weekend Trading
The EA automatically respects market hours. No trades will execute when market is closed.

## News Filter Setup

### Why Use News Filter?
High-impact news events can cause:
- Extreme volatility
- Wide spreads
- Unpredictable price movements
- Stop loss hunting

### Manual News Calendar Setup
Update the EA code to include upcoming news events:

```mql5
// In OnInit() function, add:
newsEventsCount = 5;
ArrayResize(newsEvents, newsEventsCount);

// Format: D'YYYY.MM.DD HH:MM'
newsEvents[0] = D'2024.02.01 14:30';  // US NFP
newsEvents[1] = D'2024.02.05 08:30';  // UK GDP
newsEvents[2] = D'2024.02.14 13:00';  // FOMC Minutes
newsEvents[3] = D'2024.02.20 09:00';  // ECB Rate Decision
newsEvents[4] = D'2024.02.28 14:00';  // US CPI
```

### Important News Events to Avoid
**High Impact (Always Avoid):**
- US Non-Farm Payrolls (NFP)
- FOMC Interest Rate Decisions
- US CPI (Inflation) Data
- US GDP Reports
- FOMC Meeting Minutes

**Medium Impact (Consider Avoiding):**
- US Unemployment Claims
- US Retail Sales
- Central Bank Speeches
- PMI Data Releases

### News Buffer Time
`NewsBufferMinutes: 30` means EA won't trade:
- 30 minutes before news event
- During news event
- 30 minutes after news event

**Recommendations:**
- High Impact News: 30-60 minutes buffer
- Medium Impact News: 15-30 minutes buffer

## Troubleshooting

### Common Issues and Solutions

#### 1. EA Not Opening Trades
**Symptoms:** No positions opening despite signals
**Possible Causes:**
- AutoTrading disabled
- Outside trading session
- Spread too wide
- Daily loss limit reached
- Insufficient account balance

**Solutions:**
- Enable AutoTrading button (green)
- Check session times vs broker time
- Wait for tighter spreads
- Reset EA at start of new day
- Deposit more funds or reduce risk %

#### 2. Compilation Errors
**Error:** "Trade.mqh not found"
**Solution:** Update MT5 to latest version

**Error:** "Syntax error"
**Solution:** Ensure using MT5 (not MT4)

#### 3. Wrong Session Times
**Symptoms:** Trading at odd hours
**Solution:** Calculate your broker's GMT offset correctly
```
Server Time - GMT Time = Offset
Adjust all session hours by this offset
```

#### 4. Lot Size Too Small
**Symptoms:** EA won't open trades, error "lot size too small"
**Solutions:**
- Increase account balance
- Reduce RiskPercentage temporarily
- Check broker's minimum lot size
- Widen stop loss (increase SL_ATR_Multiplier)

#### 5. Frequent Stop Outs
**Symptoms:** Many losing trades hit SL
**Solutions:**
- Increase SL_ATR_Multiplier (wider stops)
- Reduce trading during low liquidity
- Check if MACD/BB parameters suit current market
- Verify spread isn't too high

#### 6. GUI Panel Not Showing
**Solutions:**
- Set ShowPanel = true
- Check PanelX/PanelY values are on screen
- Remove and reattach EA to chart
- Restart MT5

## Best Practices

### Before Going Live

1. **Backtest Thoroughly**
   - Minimum 6 months historical data
   - Test on multiple timeframes (M5, M15)
   - Use 99% modeling quality
   - Include realistic spreads

2. **Forward Test on Demo**
   - Run for at least 2-4 weeks
   - Monitor all trading hours
   - Check behavior during news
   - Verify risk calculations

3. **Start Small**
   - Begin with minimum account size
   - Use 0.5% risk initially
   - Allow 1 position maximum
   - Gradually increase as confident

### During Live Trading

1. **Daily Monitoring**
   - Check GUI panel daily
   - Review trade logs
   - Monitor daily P/L
   - Watch for unusual behavior

2. **Weekly Review**
   - Calculate win rate
   - Review largest losses
   - Check if adjustments needed
   - Update news calendar

3. **Monthly Optimization**
   - Analyze performance metrics
   - Consider parameter adjustments
   - Review broker spreads/slippage
   - Evaluate different sessions

### VPS Recommendations

For 24/7 operation:
- **Location:** Close to broker's server
- **Specs:** 2GB RAM minimum, Windows Server
- **Uptime:** 99.9%+ guaranteed
- **Latency:** <50ms to broker

Popular VPS Providers:
- Forex VPS
- Amazon EC2
- Vultr
- DigitalOcean

### Record Keeping

Maintain logs of:
- Daily profit/loss
- Number of trades per day
- Win rate percentage
- Average win vs average loss
- Parameter changes made
- Market conditions

### When to Stop Trading

Stop and reassess if:
- 5 consecutive losing days
- Hit daily loss limit 3+ times in a week
- Win rate drops below 50%
- Drawdown exceeds 10%
- Market conditions change drastically

### Optimization Cycle

1. **Collect Data** (1 month)
2. **Analyze Performance** (identify weaknesses)
3. **Adjust Parameters** (one at a time)
4. **Test Changes** (demo for 2 weeks)
5. **Implement** (if improvement confirmed)
6. **Repeat** (continuous improvement)

## Advanced Tips

### Timeframe Selection
- **M5**: More frequent trades, requires closer monitoring
- **M15**: Fewer but potentially higher quality trades (recommended)
- **M30**: Very selective entries, lower frequency

### Combining with Manual Trading
- Let EA handle entries during your away time
- Manually close positions if strong reversal signal
- Disable EA before major news if you prefer manual control
- Use EA signals as confirmation for manual trades

### Multi-Symbol Strategy
Run EA on:
- XAUUSD (primary)
- XAGUSD (silver - similar behavior)

Adjust parameters for each symbol's characteristics.

### Seasonal Adjustments
- **Summer**: Lower volatility, consider reducing targets
- **Year-End**: Increased volatility, widen stops
- **NFP Week**: Consider more conservative settings

## Support Resources

- **MT5 Documentation:** https://www.mql5.com/en/docs
- **Trading Journal Template:** Track all EA trades
- **Economic Calendar:** forexfactory.com, myfxbook.com
- **Community Forums:** Share settings and results

---

Remember: This EA is a tool to assist your trading, not a guaranteed profit machine. Always trade responsibly, use proper risk management, and never invest more than you can afford to lose.

**Good luck and happy trading!** 📈
