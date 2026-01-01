# XAUUSD Scalping EA - Advanced Expert Advisor for MetaTrader 5

A fully functional and advanced Expert Advisor (EA) designed specifically for scalping XAUUSD (Gold) on the MetaTrader 5 platform. This EA incorporates sophisticated technical analysis, dynamic risk management, and intelligent trade execution to maximize profitability while protecting capital.

## 🎯 Key Features

### 1. **Early Entry Detection System**
- **MACD Integration**: Detects momentum shifts and trend changes using configurable Fast, Slow, and Signal periods
- **Bollinger Bands**: Identifies overbought/oversold conditions and volatility expansion/contraction
- **RSI Filter**: Uses Relative Strength Index to confirm trade entries based on overbought (70) and oversold (30) levels
- **Liquidity Sweep Detection**: Recognizes stop-hunt zones and fake breakouts for optimal entry timing
- **Volatility-Aware Logic**: Uses ATR (Average True Range) for dynamic adjustment based on market conditions

### 2. **Advanced Risk Management**
- **Percentage-Based Position Sizing**: Automatically calculates lot size based on configurable risk percentage per trade
- **Daily Loss Limit**: Pauses trading when maximum daily loss threshold is reached to protect capital
- **Spread Filter**: Avoids trading during unfavorable spread conditions
- **Dynamic SL/TP Calculation**: Stop Loss and Take Profit levels adjust based on ATR volatility

### 3. **Intelligent Trade Execution**
- **Instant Market Orders**: Fast execution with configurable slippage tolerance
- **ATR-Based SL/TP**: Adaptive stop loss and take profit levels that respond to market volatility
- **Trailing Stop Loss**: Dynamically locks in profits as price moves favorably
- **Maximum Position Control**: Limits concurrent positions to manage exposure

### 4. **Session and News Filtering**
- **Trading Session Controls**: 
  - London Session (08:00-17:00 GMT)
  - New York Session (13:00-22:00 GMT)
  - Fully configurable session times
- **News Filter**: Avoids trading during high-impact economic events with configurable buffer time

### 5. **Scalping Logic**
- **Small Profit Targets**: Optimized for frequent small wins
- **Mean Reversion Exits**: Uses Bollinger Bands to detect optimal exit points
- **Minimum Profit Threshold**: Only exits when minimum profit target is met
- **Rapid Trade Cycling**: Designed for multiple trades per session

### 6. **Graphical User Interface (GUI)**
- **Real-Time Information Panel**: On-chart display showing:
  - Account balance and daily P/L
  - Trading status (Active/Paused)
  - Number of trades and win rate
  - Current spread and ATR values
  - MACD signal and entry conditions
  - Open positions count
  - Session status
- **Customizable Display**: Adjustable position, colors, and visibility

### 7. **Comprehensive Logging and Notifications**
- **Detailed Trade Logs**: Complete audit trail of all trading activity
- **Real-Time Alerts**: Notifications for:
  - Trade entries (Buy/Sell)
  - Stop Loss and Take Profit hits
  - Daily loss limit reached
  - Trading session changes
- **Error Tracking**: Displays last error message on GUI panel

## 📋 Installation Instructions

1. **Download the EA**: Clone or download this repository
2. **Copy to MT5**: 
   - Copy `XAUUSDScalpingEA.mq5` to your MetaTrader 5 data folder:
   - Navigate to: `File > Open Data Folder > MQL5 > Experts`
3. **Compile**: 
   - Open MetaEditor (F4 in MT5)
   - Open `XAUUSDScalpingEA.mq5`
   - Click Compile (F7)
4. **Attach to Chart**:
   - Open a XAUUSD chart
   - Drag the EA from Navigator onto the chart
   - Ensure "AutoTrading" is enabled

## ⚙️ Configuration Parameters

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| RiskPercentage | 1.0% | Risk per trade as percentage of account balance |
| MaxDailyLossPercent | 5.0% | Maximum daily loss before trading pauses |
| MaxSpreadPoints | 50 | Maximum allowed spread in points |

### Indicator Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| MACD_Fast | 12 | MACD Fast EMA period |
| MACD_Slow | 26 | MACD Slow EMA period |
| MACD_Signal | 9 | MACD Signal line period |
| BB_Period | 20 | Bollinger Bands period |
| BB_Deviation | 2.0 | Bollinger Bands standard deviation |
| ATR_Period | 14 | ATR period for volatility measurement |
| UseRSI | true | Enable/disable RSI filter |
| RSI_Period | 14 | RSI period for momentum measurement |
| RSI_Overbought | 70.0 | RSI overbought level (sell filter) |
| RSI_Oversold | 30.0 | RSI oversold level (buy filter) |

### Trade Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| TP_ATR_Multiplier | 1.5 | Take Profit as multiple of ATR |
| SL_ATR_Multiplier | 1.0 | Stop Loss as multiple of ATR |
| MinStopLossPoints | 30 | Minimum Stop Loss in points (prevents too-tight stops) |
| MinRiskRewardRatio | 1.5 | Minimum Risk/Reward Ratio (TP must be at least this times SL) |
| UseTrailingStop | true | Enable/disable trailing stop |
| TrailingStopATR | 1.0 | Trailing stop distance (ATR multiple) |
| TrailingStepATR | 0.5 | Trailing step size (ATR multiple) |

### Trading Sessions
| Parameter | Default | Description |
|-----------|---------|-------------|
| TradeLondonSession | true | Enable London session trading |
| TradeNewYorkSession | true | Enable New York session trading |
| LondonStartHour | 8 | London session start (GMT) |
| LondonEndHour | 17 | London session end (GMT) |
| NewYorkStartHour | 13 | New York session start (GMT) |
| NewYorkEndHour | 22 | New York session end (GMT) |

### News Filter
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseNewsFilter | true | Enable news filter |
| NewsBufferMinutes | 30 | Minutes before/after news to avoid trading |

### Scalping Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| MinProfitPoints | 20 | Minimum profit in points before exit consideration |
| UseMeanReversion | true | Enable mean reversion exit logic |
| MaxPositions | 1 | Maximum concurrent positions |

### GUI Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| ShowPanel | true | Display information panel |
| PanelX | 20 | Panel X position on chart |
| PanelY | 50 | Panel Y position on chart |
| PanelColor | Navy | Panel background color |
| TextColor | White | Panel text color |

## 🎓 Trading Strategy Explained

### Entry Logic
The EA uses a multi-factor approach to identify high-probability entry points:

1. **Liquidity Sweep Detection**: 
   - Identifies when price breaks a previous high/low then quickly reverses
   - This often indicates stop-hunting by institutions, creating entry opportunities

2. **MACD Confirmation**:
   - Bullish: MACD line crosses above signal line
   - Bearish: MACD line crosses below signal line

3. **Bollinger Bands Position**:
   - Buy signals when price is near or below lower band
   - Sell signals when price is near or above upper band

4. **RSI Filter**:
   - Buy signals only when RSI is oversold (<30) or neutral (30-70)
   - Sell signals only when RSI is overbought (>70) or neutral (30-70)
   - Prevents buying when market is already overbought and selling when oversold

5. **Volatility Check**:
   - Uses ATR to confirm sufficient market movement
   - Adapts to changing volatility conditions

### Exit Logic
Multiple exit strategies work together:

1. **Fixed Take Profit**: Based on ATR multiplier
2. **Fixed Stop Loss**: Based on ATR multiplier
3. **Trailing Stop**: Locks in profits as trade moves favorably
4. **Mean Reversion**: Exits when price returns to Bollinger Bands middle line
5. **Minimum Profit Rule**: Only considers exits when minimum profit is achieved

## 📊 Performance Monitoring

The EA provides real-time performance metrics via the on-chart panel:
- **Balance**: Current account balance
- **Daily P/L**: Profit/Loss for current trading day
- **Trades Today**: Number of trades executed
- **Win Rate**: Percentage of winning trades
- **Open Positions**: Currently active positions
- **Spread**: Current market spread
- **Session Status**: Whether trading session is active
- **ATR**: Current volatility measurement
- **MACD Signal**: Current trend direction
- **RSI**: Current RSI value with status (Overbought/Oversold/Neutral)
- **Entry Signal**: Current buy/sell/neutral signal

## 🔧 Customization Tips

### For More Conservative Trading:
- Reduce `RiskPercentage` to 0.5% or lower
- Increase `SL_ATR_Multiplier` to 1.5 or 2.0
- Reduce `MaxPositions` to 1
- Increase `MaxDailyLossPercent` check threshold

### For More Aggressive Trading:
- Increase `RiskPercentage` to 2.0% (not recommended above 2%)
- Reduce `TP_ATR_Multiplier` for quicker profits
- Increase `MaxPositions` to 2 or 3
- Reduce `MinProfitPoints` for faster exits

### For Specific Sessions:
- Disable unwanted sessions by setting to false
- Adjust session hours for your broker's GMT offset
- Test different session combinations for optimal results

## ⚠️ Important Disclaimers

1. **Backtesting Required**: Always backtest with historical data before live trading
2. **Demo Testing**: Test on demo account for at least 2 weeks before going live
3. **Risk Warning**: Trading involves substantial risk of loss
4. **Broker Compatibility**: Ensure your broker allows automated trading
5. **VPS Recommended**: For 24/7 operation, use a Virtual Private Server
6. **News Events**: Update news filter manually or use external calendar integration

## 🛠️ Troubleshooting

### EA Not Trading:
- Check that AutoTrading is enabled (button in toolbar)
- Verify trading session times match your broker's GMT offset
- Check spread - may be too wide (exceeds MaxSpreadPoints)
- Ensure sufficient account balance for calculated lot size
- Check if daily loss limit has been reached

### Compilation Errors:
- Ensure you're using MetaTrader 5 (not MT4)
- Check that Trade library is available
- Update to latest MT5 build

### No Signals Appearing:
- Verify indicators are loading (check Experts log)
- Check that market conditions meet entry criteria
- Adjust indicator parameters if market has changed

## 📝 News Filter Setup (Optional Enhancement)

To integrate an external news calendar:

1. Use a news feed API or manually update the `newsEvents[]` array
2. Add news times in the format: `newsEvents[0] = D'2024.01.15 14:30'`
3. Set appropriate `NewsBufferMinutes` (default 30)
4. The EA will avoid trading during these windows

Example:
```mql5
// In OnInit() function, add:
newsEventsCount = 3;
ArrayResize(newsEvents, newsEventsCount);
newsEvents[0] = D'2024.01.15 14:30';  // FOMC Meeting
newsEvents[1] = D'2024.01.20 08:30';  // NFP Release
newsEvents[2] = D'2024.01.25 13:00';  // GDP Data
```

## 📈 Optimization Recommendations

For best results:
1. **Backtest Period**: Minimum 6 months of historical data
2. **Optimization Variables**: Focus on ATR multipliers and risk percentage
3. **Walk-Forward Analysis**: Validate strategy on out-of-sample data
4. **Different Market Conditions**: Test in trending, ranging, and volatile markets
5. **Broker Spreads**: Account for your broker's typical spreads in testing

## 🤝 Support and Contributions

This EA is open source and contributions are welcome. For issues or enhancements:
- Open an issue on GitHub
- Submit pull requests for improvements
- Share your optimization results

## 📜 License

This project is provided as-is for educational and trading purposes. Use at your own risk.

## 🔄 Version History

### Version 1.00 (Current)
- Initial release with all core features
- MACD + Bollinger Bands + Liquidity Sweep detection
- Dynamic risk management with percentage-based sizing
- Session and news filtering
- GUI panel with real-time statistics
- Trailing stop and mean reversion exits
- Comprehensive logging and notifications

---

**Happy Trading! 🚀📈**

*Remember: Past performance does not guarantee future results. Always trade responsibly and never risk more than you can afford to lose.*
