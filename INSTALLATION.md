# Installation & Setup Guide

## Prerequisites

Before installing the XAUUSD Scalping EA, ensure you have:

- ✅ MetaTrader 5 (latest version) - [Download from MetaQuotes](https://www.metatrader5.com/en/download)
- ✅ A demo or live trading account with XAUUSD available
- ✅ Basic understanding of MT5 interface
- ✅ At least 1GB free disk space
- ✅ Stable internet connection

## Step-by-Step Installation

### Step 1: Download the EA

1. Navigate to the GitHub repository
2. Click on "Code" → "Download ZIP"
3. Extract the ZIP file to a temporary location
4. Locate `XAUUSDScalpingEA.mq5` file

### Step 2: Copy to MT5 Experts Folder

**Option A: Using MT5 Interface (Recommended)**

1. Open MetaTrader 5
2. Click `File` → `Open Data Folder`
3. Navigate to `MQL5` → `Experts` folder
4. Copy `XAUUSDScalpingEA.mq5` into this folder
5. Return to MT5

**Option B: Manual Path**

Windows default path:
```
C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[BrokerID]\MQL5\Experts\
```

Mac default path:
```
~/Library/Application Support/MetaQuotes/Terminal/[BrokerID]/MQL5/Experts/
```

### Step 3: Compile the EA

1. In MT5, press `F4` to open MetaEditor
2. In Navigator panel (left side), expand `Experts`
3. Double-click `XAUUSDScalpingEA.mq5` to open it
4. Press `F7` or click `Compile` button
5. Check the Toolbox panel at bottom:
   - ✅ Should say "0 error(s), 0 warning(s)"
   - ❌ If errors appear, verify you're using MT5 (not MT4)

**Expected Compilation Output:**
```
Compiling 'XAUUSDScalpingEA.mq5'...
0 error(s), 0 warning(s)
succeeded
```

### Step 4: Attach EA to Chart

1. In MT5, open a new chart:
   - File → New Chart → XAUUSD
2. Set your preferred timeframe:
   - Right-click chart → Timeframe → M15 (recommended)
   - M5 also works well for more active trading
3. Open Navigator panel:
   - View → Navigator (or press Ctrl+N)
4. Expand `Expert Advisors` section
5. Find `XAUUSDScalpingEA`
6. Drag and drop it onto the XAUUSD chart

### Step 5: Configure EA Settings

When you attach the EA, a settings dialog appears:

**Common Tab:**
- ✅ Check "Allow live trading"
- ✅ Check "Allow DLL imports" (if needed)
- ⚠️ Note: EA doesn't use external DLLs by default

**Inputs Tab:**

Recommended settings for first-time use:

```
=== Risk Management ===
RiskPercentage: 1.0
MaxDailyLossPercent: 5.0
MaxSpreadPoints: 50

=== Indicator Settings ===
MACD_Fast: 12
MACD_Slow: 26
MACD_Signal: 9
BB_Period: 20
BB_Deviation: 2.0
ATR_Period: 14

=== Trade Settings ===
TP_ATR_Multiplier: 1.5
SL_ATR_Multiplier: 1.0
UseTrailingStop: true
TrailingStopATR: 1.0
TrailingStepATR: 0.5

=== Trading Sessions ===
TradeLondonSession: true
TradeNewYorkSession: true
LondonStartHour: 8     ⚠️ Adjust for your broker's GMT offset
LondonEndHour: 17      ⚠️ Adjust for your broker's GMT offset
NewYorkStartHour: 13   ⚠️ Adjust for your broker's GMT offset
NewYorkEndHour: 22     ⚠️ Adjust for your broker's GMT offset

=== News Filter ===
UseNewsFilter: true
NewsBufferMinutes: 30

=== Scalping Settings ===
MinProfitPoints: 20
UseMeanReversion: true
MaxPositions: 1

=== GUI Settings ===
ShowPanel: true
PanelX: 20
PanelY: 50
PanelColor: clrNavy
TextColor: clrWhite
```

Click `OK` to apply settings.

### Step 6: Enable Auto Trading

**Critical Step!**

1. Look at the MT5 toolbar
2. Find the "Algo Trading" button (icon with a graph)
3. Click it to turn **green**
4. If red, EA won't trade!

**Visual Indicators:**
- ✅ Green button = Auto trading enabled
- ❌ Red button = Auto trading disabled
- 😊 Smile icon on chart = EA is running
- 😟 Sad face icon = EA has errors

### Step 7: Verify EA is Running

Check multiple indicators:

1. **Chart Corner:**
   - Should see 😊 smile icon
   - Name: "XAUUSDScalpingEA"

2. **GUI Panel:**
   - Should appear on chart at specified position
   - Status should show "Active" in green
   - Balance should display correctly

3. **Experts Log:**
   - Press `Ctrl+T` to open Toolbox
   - Click `Experts` tab
   - Should see: "XAUUSD Scalping EA initialized successfully"

4. **Terminal Window:**
   - In Toolbox, click `Trade` tab
   - Will show positions when EA opens trades

## Important: Adjust Session Times for Your Broker

Your broker's server time may differ from GMT. **This is critical!**

### Finding Your Broker's GMT Offset

**Method 1: Market Watch**
1. Open Market Watch (Ctrl+M)
2. Right-click → Symbols
3. Find XAUUSD → Properties
4. Check "Server Time" description
5. Note the GMT offset (e.g., GMT+2, GMT-5)

**Method 2: Compare Times**
1. Note MT5 server time (shown in Market Watch)
2. Check current GMT time online
3. Calculate difference

### Adjusting Session Hours

**Example 1: Broker is GMT+2**
```
London Session:
- Default: 08:00-17:00 GMT
- Adjusted: 10:00-19:00 (add 2 hours)

New York Session:
- Default: 13:00-22:00 GMT
- Adjusted: 15:00-00:00 (add 2 hours, 00:00 = midnight)

Settings:
LondonStartHour: 10
LondonEndHour: 19
NewYorkStartHour: 15
NewYorkEndHour: 0
```

**Example 2: Broker is GMT-5 (EST)**
```
London Session:
- Default: 08:00-17:00 GMT
- Adjusted: 03:00-12:00 (subtract 5 hours)

New York Session:
- Default: 13:00-22:00 GMT
- Adjusted: 08:00-17:00 (subtract 5 hours)

Settings:
LondonStartHour: 3
LondonEndHour: 12
NewYorkStartHour: 8
NewYorkEndHour: 17
```

**Example 3: Broker is GMT+0 (London Time)**
```
Use default settings:
LondonStartHour: 8
LondonEndHour: 17
NewYorkStartHour: 13
NewYorkEndHour: 22
```

## Post-Installation Checklist

After installation, verify:

- [ ] EA compiled without errors
- [ ] Attached to XAUUSD chart
- [ ] Auto Trading button is GREEN
- [ ] Smile icon visible on chart
- [ ] GUI panel displaying correctly
- [ ] "Initialized successfully" message in Experts log
- [ ] Session times adjusted for broker's GMT offset
- [ ] Risk percentage set appropriately (1% recommended)
- [ ] Account balance showing correctly in panel

## Demo Testing Setup

Before going live, **always test on demo!**

### Creating a Demo Account

1. In MT5: File → Open an Account
2. Select your broker's server
3. Choose "Demo Account"
4. Fill in details:
   - Name: Your name
   - Email: Your email
   - Currency: USD (recommended for XAUUSD)
   - Leverage: 1:100 or 1:500
   - Deposit: Start with $10,000
5. Click Next and save login credentials

### Demo Testing Period

**Minimum testing duration: 2 weeks**

During demo testing, monitor:
- Win rate (target: 55-65%)
- Daily profit/loss
- Maximum drawdown
- Number of trades per day
- EA behavior during news events
- Session filter accuracy

**Keep a testing log:**
```
Date: 2024-01-15
Balance Start: $10,000
Trades: 5
Wins: 3
Losses: 2
Daily P/L: +$125
Max Drawdown: 1.2%
Notes: EA performed well during London session, 
       avoided trading during high spread period
```

## Going Live

When ready to trade live:

### Pre-Live Checklist

- [ ] Tested on demo for 2+ weeks
- [ ] Win rate above 55%
- [ ] Comfortable with EA behavior
- [ ] Understand all settings
- [ ] Have sufficient account balance (minimum $1,000)
- [ ] VPS setup (optional but recommended)
- [ ] Risk settings configured conservatively
- [ ] News calendar prepared (if using news filter)

### First Live Trade Settings

**Ultra-Conservative for First Week:**
```
RiskPercentage: 0.5%
MaxDailyLossPercent: 3.0%
SL_ATR_Multiplier: 1.5
MaxPositions: 1
```

### Monitoring Live Trading

**First Week:**
- Check EA every 4 hours
- Review each trade manually
- Keep detailed log
- Be ready to disable if issues occur

**After First Week:**
- Daily check of P/L
- Weekly performance review
- Monthly optimization review

## VPS Setup (Optional - For 24/7 Trading)

### Why Use a VPS?

- ✅ EA runs 24/7 even when your computer is off
- ✅ Lower latency to broker
- ✅ No interruptions from power/internet outages
- ✅ Better execution speeds

### VPS Requirements

**Minimum Specifications:**
- OS: Windows Server 2016 or newer
- RAM: 2GB
- CPU: 1 vCore
- Storage: 20GB SSD
- Location: Same region as broker

### Popular VPS Providers

1. **Forex VPS** (specialized for trading)
   - Pre-configured MT5
   - Low latency
   - $20-40/month

2. **Amazon EC2**
   - Flexible
   - Multiple locations
   - $10-30/month

3. **Vultr**
   - Easy setup
   - Good performance
   - $10-20/month

### VPS Setup Steps

1. Choose VPS provider
2. Select server location (close to broker)
3. Install Windows Server
4. Install MetaTrader 5
5. Copy EA files
6. Configure EA
7. Enable Auto Trading
8. Set to run on startup

## Troubleshooting Installation

### "Expert Advisor is not allowed to trade"

**Solution:**
1. Click Auto Trading button (make it green)
2. Tools → Options → Expert Advisors
3. Check "Allow automated trading"
4. Restart MT5

### "Expert Advisor removed from chart"

**Possible causes:**
- Compilation error
- Wrong account type
- Terminal restart

**Solution:**
1. Check Experts log for errors
2. Recompile EA
3. Reattach to chart

### "Invalid stops" or "Invalid volume"

**Solution:**
1. Check broker's minimum lot size
2. Increase account balance
3. Reduce risk percentage
4. Verify broker allows scalping

### GUI Panel Not Visible

**Solution:**
1. Set ShowPanel = true in settings
2. Check PanelX and PanelY are within screen
3. Remove and reattach EA
4. Try different position values:
   ```
   PanelX: 20
   PanelY: 50
   ```

### No Trades Opening

**Check:**
1. Auto Trading is enabled (green button)
2. Session times are correct for your broker
3. Spread is below MaxSpreadPoints (50)
4. Account has sufficient balance
5. Not within news buffer time
6. Market conditions meet entry criteria

## Updating the EA

When new versions are released:

1. **Backup:**
   - Save current .mq5 file as backup
   - Export your settings (Save button in EA properties)
   - Note any custom modifications

2. **Download:**
   - Get latest version from GitHub
   - Review CHANGELOG.md for changes

3. **Install:**
   - Follow installation steps above
   - Recompile new version

4. **Test:**
   - Test on demo first
   - Verify all features work
   - Apply saved settings

5. **Deploy:**
   - Only then use on live account

## Getting Help

If you encounter issues:

1. **Check Documentation:**
   - README.md (overview)
   - USER_GUIDE.md (detailed usage)
   - QUICK_REFERENCE.md (quick tips)
   - ADVANCED_GUIDE.md (optimization)

2. **Review Logs:**
   - Experts tab (Ctrl+T)
   - Journal tab
   - Look for error messages

3. **Search Issues:**
   - GitHub Issues page
   - Check if someone had same problem

4. **Ask for Help:**
   - Open new GitHub Issue
   - Provide:
     * MT5 version
     * EA version
     * Broker name
     * Error messages
     * Screenshots

## Next Steps

After successful installation:

1. Read USER_GUIDE.md for detailed usage
2. Review QUICK_REFERENCE.md for quick tips
3. Set up news calendar (optional)
4. Start demo testing
5. Keep trading journal
6. Monitor and optimize

---

**Congratulations!** 🎉 Your XAUUSD Scalping EA is now installed and ready to use.

**Remember:** Always test thoroughly on demo before live trading!

**Good luck and happy trading!** 📈
