# Simba Sniper EA - Multi-Timeframe Institutional Trading Strategy

## Overview

**Simba Sniper EA** is a professional-grade Expert Advisor that implements an institutional multi-timeframe analysis strategy for trading financial instruments (optimized for XAUUSD/Gold). The EA operates using a top-down analysis approach across H4, H1, M5, and optionally M1 timeframes to identify high-probability institutional trade setups.

## 🎯 Core Strategy Architecture

### 1. H4 Trend Bias Analysis
The EA starts by analyzing the H4 timeframe to identify the overall market trend:
- **Swing Structure Detection**: Identifies swing highs and swing lows
- **Displacement Identification**: Detects strong directional moves that indicate institutional activity
- **Trend Classification**: Determines if the market is BULLISH, BEARISH, or NEUTRAL

### 2. H1 High-Timeframe Zone Detection
On the H1 timeframe, the EA identifies key institutional zones:
- **Support/Resistance Zones**: Areas with multiple price touches indicating strong levels
- **Order Blocks (OBs)**: Down candles before strong bullish moves (or vice versa) where institutions placed orders
- **Fair Value Gaps (FVGs)**: Price gaps that represent imbalances and potential fill zones

### 3. M5 Entry Confirmation
The M5 timeframe is used for precise entry confirmation:
- **Break of Structure (BOS)**: Price breaking through recent swing points in the trend direction
- **Liquidity Sweeps**: Detection of stop hunts followed by reversals
- **Entry Trigger Logic**: Final confirmation before trade execution

### 4. Optional M1 Precision Entry
When enabled, M1 provides additional precision for:
- **Fine-tuning entries within identified zones**
- **Optimal entry price selection**
- **Reduced slippage and improved risk/reward**

## 🔍 9-Point Entry Validation System

Before executing any trade, the EA validates up to 9 critical criteria:

1. **H4 Trend Alignment**: H4 must show clear bullish or bearish trend
2. **H1 Zone Present**: Price must be at an H1 support/resistance zone
3. **Break of Structure (BOS)**: M5 must show BOS in trend direction
4. **Liquidity Sweep**: Optional - Detection of stop hunt reversal
5. **Fair Value Gap (FVG)**: Optional - Price within an unfilled FVG
6. **Order Block Confirmation**: Price at a valid H1 order block
7. **ATR Zone Validation**: Price within acceptable ATR distance from zones
8. **Valid Risk/Reward**: Trade setup meets minimum RR ratio requirement
9. **Session Filter Active**: Trading during active London or New York session

### Validation Requirements
- **Minimum Points**: Configurable minimum validation points (default: 6/9)
- **Required Checks**: Each validation can be set as required or optional
- **Flexible Configuration**: Adapt to different market conditions

## 📊 Key Features

### Multi-Timeframe Synergy
- Simultaneous analysis of H4, H1, M5, and optional M1
- ATR indicators on all timeframes for volatility-aware decisions
- Synchronized structure detection across timeframes

### Institutional Logic
- **Swing Structure Analysis**: Higher highs/lows or lower highs/lows
- **Displacement Detection**: Minimum % of ATR movement required
- **Order Block Detection**: Last down candle before bullish move
- **Fair Value Gap Identification**: Minimum gap size in points
- **Support/Resistance Zones**: Multi-touch validation with strength rating

### Professional Risk Management
- **Percentage-Based Position Sizing**: Risk fixed % of account per trade
- **Daily Loss Limit**: Automatic trading pause at max daily loss
- **ATR-Based SL/TP**: Dynamic stops based on market volatility
- **Minimum Risk/Reward**: Enforced RR ratio (default 2:1)
- **Maximum Positions**: Limit concurrent exposure

### Comprehensive Dashboard
Real-time display showing:
- **H4 Trend Direction**: Bullish/Bearish/Neutral with color coding
- **H1 Zones Count**: Number of active support/resistance zones
- **Order Blocks**: Active order blocks count
- **Fair Value Gaps**: Active FVGs count
- **Entry Validation**: Current validation score (x/9)
- **Validation Points**: Which specific points are met
- **Session Status**: Active/Closed
- **Account Statistics**: Balance, Daily P/L, Trades
- **ATR Values**: H4, H1, M5 volatility measurements
- **Trading Status**: Active/Paused
- **Error Messages**: Last error for debugging

### Session & Time Filters
- **London Session**: Configurable hours (default 08:00-17:00 GMT)
- **New York Session**: Configurable hours (default 13:00-22:00 GMT)
- **GMT Offset**: Broker time adjustment
- **Session-Based Trading**: Only trade during active sessions

## ⚙️ Configuration Parameters

### Multi-Timeframe Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| H4_Timeframe | PERIOD_H4 | Trend bias timeframe |
| H1_Timeframe | PERIOD_H1 | HTF zones timeframe |
| M5_Timeframe | PERIOD_M5 | Entry confirmation timeframe |
| M1_Timeframe | PERIOD_M1 | Precision entry timeframe |
| UseM1Precision | false | Enable M1 precision entries |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| RiskPercentage | 1.0% | Risk per trade |
| MaxDailyLossPercent | 3.0% | Maximum daily loss |
| MinRiskRewardRatio | 2.0 | Minimum RR ratio |
| MaxPositions | 1 | Maximum concurrent positions |

### ATR Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| ATR_Period | 14 | ATR calculation period |
| ATR_ZoneMultiplier | 1.5 | Zone validation distance |
| ATR_StopLossMultiplier | 1.5 | Stop loss calculation |
| ATR_TakeProfitMultiplier | 3.0 | Take profit calculation |

### Structure Detection
| Parameter | Default | Description |
|-----------|---------|-------------|
| SwingLookback | 20 | Bars for swing point detection |
| MinDisplacementPercent | 0.3 | Minimum displacement (% of ATR) |
| OrderBlockBars | 5 | Bars to analyze for OBs |
| FVG_MinGapPoints | 20 | Minimum FVG gap in points |

### 9-Point Validation
| Parameter | Default | Description |
|-----------|---------|-------------|
| Require_H4_Trend | true | Require H4 trend alignment |
| Require_H1_Zone | true | Require H1 zone present |
| Require_BOS | true | Require break of structure |
| Require_LiquiditySweep | false | Require liquidity sweep |
| Require_FVG | false | Require fair value gap |
| Require_OrderBlock | true | Require order block |
| Require_ATR_Zone | true | Require ATR zone validation |
| Require_ValidRR | true | Require valid risk/reward |
| Require_SessionFilter | true | Require session active |
| MinValidationPoints | 6 | Minimum points required (out of 9) |

## 🚀 Installation

1. **Copy EA File**:
   - Copy `SimbaSniperEA.mq5` to your MT5 data folder
   - Path: `File > Open Data Folder > MQL5 > Experts`

2. **Compile**:
   - Open MetaEditor (F4 in MT5)
   - Open `SimbaSniperEA.mq5`
   - Click Compile (F7)
   - Verify 0 errors, 0 warnings

3. **Attach to Chart**:
   - Open any chart (optimized for XAUUSD)
   - Drag EA from Navigator onto the chart
   - Enable "AutoTrading" button in toolbar
   - Configure parameters as needed

4. **Verify**:
   - Dashboard should appear on chart
   - Check Experts log for initialization message
   - Monitor H4 trend detection

## 📈 Trading Strategy Explained

### Entry Process

1. **H4 Analysis** (Every H4 bar):
   - Detect swing highs and lows
   - Determine trend direction (bullish/bearish/neutral)
   - Measure displacement strength
   - Update trend bias

2. **H1 Zone Detection** (Every M5 bar):
   - Identify support/resistance zones (3+ touches)
   - Detect order blocks (last opposite candle before move)
   - Find fair value gaps (price imbalances)
   - Rate zone strength

3. **M5 Entry Confirmation** (Every M5 bar):
   - Check for break of structure
   - Detect liquidity sweeps
   - Validate price within zones
   - Check ATR-based zone proximity

4. **9-Point Validation**:
   - Score entry against 9 criteria
   - Ensure minimum points met
   - Verify all required checks passed
   - Calculate risk/reward ratio

5. **Trade Execution**:
   - Calculate ATR-based SL/TP
   - Size position based on risk %
   - Execute market order
   - Log validation score

### Exit Strategy

- **Take Profit**: ATR_TakeProfitMultiplier × ATR (default 3.0)
- **Stop Loss**: ATR_StopLossMultiplier × ATR (default 1.5)
- **Risk/Reward**: Minimum 2:1 enforced
- **Daily Loss Limit**: Auto-pause at max loss

## 📊 Dashboard Guide

### Trend Information
- **H4 Trend**: GREEN = Bullish, RED = Bearish, YELLOW = Neutral
- **Swings**: Higher highs/lows or lower highs/lows

### Zone Information
- **H1 Zones**: Count of active S/R zones
- **Order Blocks**: Count of valid OBs
- **Fair Value Gaps**: Count of unfilled FVGs

### Validation Display
- **Entry Validation**: Current score out of 9
- **Points Met**: Abbreviations of which checks passed
  - H4 = H4 Trend
  - Zone = H1 Zone
  - BOS = Break of Structure
  - Sweep = Liquidity Sweep
  - FVG = Fair Value Gap
  - OB = Order Block
  - ATR = ATR Zone
  - Session = Session Active

### Statistics
- **Balance**: Current account balance
- **Daily P/L**: GREEN if positive, RED if negative
- **Trades**: Number of trades today
- **Open Positions**: Currently active positions

### Technical Data
- **ATR H4/H1/M5**: Volatility on each timeframe
- **Session**: ACTIVE (green) or CLOSED (orange)
- **Status**: ACTIVE (green) or PAUSED (red)

## 🎓 Best Practices

### For Conservative Trading
- Set `MinValidationPoints` to 7 or 8
- Enable all required checks
- Use `RiskPercentage` of 0.5-1.0%
- Set `MaxDailyLossPercent` to 2-3%
- Keep `MaxPositions` at 1

### For Aggressive Trading
- Set `MinValidationPoints` to 5 or 6
- Disable optional checks (Sweep, FVG)
- Use `RiskPercentage` of 1.5-2.0%
- Increase `MaxPositions` to 2-3
- Monitor closely

### Optimization Tips
1. **Backtest** minimum 6 months on H1 or M5 chart
2. **Walk-Forward Analysis** to validate robustness
3. **Optimize** ATR multipliers for your broker's spread
4. **Adjust** session times for broker GMT offset
5. **Test** different swing lookback periods (15-25)
6. **Validate** minimum displacement (0.2-0.5)

## 🔧 Troubleshooting

### No Trades Executing
- Check H4 trend is detected (not NEUTRAL)
- Verify validation score meets minimum
- Ensure session is ACTIVE
- Check required validations are met
- Review error messages on dashboard

### Too Many False Signals
- Increase `MinValidationPoints`
- Enable more required checks
- Increase `MinDisplacementPercent`
- Increase `SwingLookback` period
- Reduce trading sessions

### Trades Getting Stopped Out
- Increase `ATR_StopLossMultiplier`
- Check broker spread included in calculations
- Verify ATR period appropriate for market
- Consider increasing `MinRiskRewardRatio`

### Dashboard Not Showing
- Set `ShowDashboard` to true
- Adjust `DashboardX` and `DashboardY` positions
- Check for object creation errors in log
- Restart MT5 and reattach EA

## ⚠️ Risk Warnings

1. **Trading Risk**: All trading involves substantial risk of loss
2. **No Guarantees**: Past performance doesn't guarantee future results
3. **Demo First**: Always test on demo for minimum 2-4 weeks
4. **Monitor Daily**: Check EA operation and error messages
5. **Broker Compatibility**: Verify broker allows automated trading
6. **VPS Recommended**: For 24/7 operation and reliability
7. **Capital Protection**: Never risk more than you can afford to lose
8. **Start Small**: Begin with minimum risk percentage
9. **Understand Strategy**: Know how the EA makes decisions
10. **Regular Review**: Monitor performance and adjust as needed

## 📝 Version History

### Version 1.00 (Current)
- Initial release
- Multi-timeframe analysis (H4, H1, M5, M1)
- 9-point entry validation system
- Institutional structure detection (Swings, OBs, FVGs, Zones)
- ATR-based dynamic risk management
- Comprehensive dashboard
- Session filtering
- Daily loss limit protection
- Configurable validation requirements

## 🤝 Support

For issues, questions, or improvements:
- Review this documentation thoroughly
- Check Experts log for error messages
- Verify parameter configuration
- Test on demo account first
- Document any issues with screenshots

## 📚 Additional Resources

- **Problem Statement**: See original requirements document
- **MQL5 Documentation**: https://www.mql5.com/en/docs
- **Order Blocks**: Research institutional order flow
- **Fair Value Gaps**: Study smart money concepts
- **ICT Concepts**: Inner Circle Trader methodology

## 📄 License

This EA is provided for educational and trading purposes. Use at your own risk.

---

**Simba Sniper EA - Institutional-Grade Multi-Timeframe Analysis**

*Trade with the institutions, not against them.* 🦁🎯
