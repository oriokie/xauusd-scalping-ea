# Changelog

All notable changes to the XAUUSD Scalping EA will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-01

### Added
- **RSI Integration:** Integrated Relative Strength Index (RSI) as a momentum oscillator for enhanced trade filtering
  - New parameter `UseRSI` (default: true) to enable/disable RSI filter
  - New parameter `RSI_Period` (default: 14) for RSI calculation period
  - New parameter `RSI_Overbought` (default: 70.0) for overbought threshold
  - New parameter `RSI_Oversold` (default: 30.0) for oversold threshold
  - Buy signals only trigger when RSI is oversold (<30) or neutral (30-70), preventing buys in overbought conditions
  - Sell signals only trigger when RSI is overbought (>70) or neutral (30-70), preventing sells in oversold conditions
  - RSI value and status (Overbought/Oversold/Neutral) displayed in GUI panel
  - Color-coded RSI indicator: Green (Oversold), Red (Overbought), Gray (Neutral)

### Changed
- Updated GUI panel height from 350 to 375 pixels to accommodate RSI display
- Enhanced entry signal logic with RSI confirmation for better accuracy
- Improved multi-indicator confirmation system with RSI as additional filter

### Improved
- More accurate trade entry timing with RSI momentum confirmation
- Reduced false signals by filtering against extreme RSI conditions
- Better alignment with market momentum through RSI analysis

## [1.1.0] - 2026-01-01

### Fixed
- **Stop-Loss Calculation:** Added minimum stop-loss distance validation to prevent overly tight stops during low volatility periods
  - New parameter `MinStopLossPoints` (default: 30 points) ensures SL is never too close to entry
  - Prevents premature stop-outs when ATR is unusually low
- **Risk-Reward Ratio:** Automatically adjusts TP to maintain minimum 1.5:1 reward/risk ratio
  - Ensures profitable trades have adequate profit potential relative to risk
- **Mean Reversion Exit Logic:** Improved exit conditions to prevent premature position closures
  - Changed threshold from 0.2 to 0.3 ATR for more room
  - Now only exits when price crosses beyond middle BB, not just approaches it
  - Requires 1.5x MinProfitPoints before considering mean reversion exits
- **Trailing Stop Logic:** Enhanced with minimum distance validation
  - Applies same minimum distance rules as initial stop-loss
  - Prevents trailing stop from being placed too close to current price
  - Added detailed logging for trailing stop adjustments

### Added
- Enhanced logging for trade execution showing entry price, SL, TP, and distances in points
- Position management logging with detailed exit information
- Warning messages when ATR-based calculations are adjusted to meet minimum requirements

### Changed
- Mean reversion exit now more conservative to allow trades more time to develop
- Trailing stop movements now logged with point distances for better debugging

## [1.0.0] - 2024-01-01

### Added
- Initial release of XAUUSD Scalping EA
- Early entry detection system with liquidity sweep recognition
- MACD indicator integration for momentum analysis
- Bollinger Bands integration for volatility-based entries
- Price action analysis for stop-hunt zone detection
- ATR-based dynamic volatility adjustment
- Percentage-based risk management system
- Dynamic lot size calculation based on account risk
- Maximum daily loss limit protection
- Instant market order execution with error handling
- ATR-based dynamic SL/TP calculation
- Trailing stop-loss feature for profit protection
- London and New York trading session filters
- Configurable session times (GMT-based)
- News filter with time-based avoidance
- Scalping logic optimized for small frequent profits
- Mean reversion exit strategy using Bollinger Bands
- Minimum profit threshold system
- Maximum concurrent positions limit
- Graphical User Interface (GUI) panel
- Real-time account statistics display
- Trade signal visualization
- Session status indicator
- Spread monitoring display
- ATR and MACD status display
- Comprehensive logging system
- Trade execution notifications
- Alert system for SL/TP hits
- Daily loss limit warnings
- Error message display
- Automatic daily reset functionality
- Position management system
- Spread checking before trades
- Account protection mechanisms

### Features
- **Risk Management:**
  - Configurable risk percentage per trade (default: 1%)
  - Daily loss limit (default: 5%)
  - Maximum spread filter (default: 50 points)
  - Automatic lot size normalization

- **Technical Indicators:**
  - MACD (12/26/9)
  - Bollinger Bands (20/2.0)
  - ATR (14)
  - All fully configurable

- **Trade Execution:**
  - ATR-based SL/TP calculation
  - Trailing stop with configurable distance
  - Mean reversion exits
  - Minimum profit enforcement

- **Session Management:**
  - London session (08:00-17:00 GMT)
  - New York session (13:00-22:00 GMT)
  - Fully adjustable hours
  - Automatic session detection

- **GUI Features:**
  - Status display (Active/Paused)
  - Balance and P/L tracking
  - Trade count and win rate
  - Position monitoring
  - Spread indicator
  - Signal display
  - Customizable position and colors

- **Notifications:**
  - Trade entry alerts
  - SL/TP notifications
  - Daily limit warnings
  - Error messages

### Documentation
- Comprehensive README.md with feature overview
- USER_GUIDE.md with detailed usage instructions
- ADVANCED_GUIDE.md for experienced traders
- Parameter descriptions in code
- Strategy explanation
- Installation instructions
- Troubleshooting guide
- Best practices documentation

### Technical Details
- Built for MetaTrader 5
- Uses CTrade class for execution
- MQL5 Standard Library integration
- Object-oriented design
- Modular function structure
- Optimized for XAUUSD symbol
- Compatible with all MT5 brokers

## [Unreleased]

### Planned Features
- Automatic news calendar integration via API
- Multi-currency support (XAGUSD, EURUSD, etc.)
- Advanced pattern recognition
- Machine learning signal enhancement
- Telegram notifications integration
- Cloud-based parameter synchronization
- Performance analytics dashboard
- Trade copying capabilities
- Custom indicator support
- Risk/reward optimization
- Market regime detection
- Correlation analysis
- Volume profile integration
- Advanced money management strategies

### Future Enhancements
- Walk-forward optimization tool
- Monte Carlo simulation
- Multi-timeframe confirmation
- Sentiment analysis integration
- Order flow analysis
- Tick volume analysis
- Advanced trailing methods
- Partial position closing
- Break-even automation
- Time-based filters
- Volatility regime adaptation
- Spread-adaptive strategies

## Version History

### Version 1.0.0 (Current)
- Full implementation of all core features
- Production-ready Expert Advisor
- Comprehensive documentation
- Tested and optimized for XAUUSD

---

## How to Update

When new versions are released:

1. **Backup Current Version:**
   - Save your current .mq5 file
   - Export your parameter settings
   - Note any customizations made

2. **Download New Version:**
   - Get latest .mq5 file from repository
   - Read changelog for new features
   - Review any breaking changes

3. **Install Update:**
   - Copy new file to Experts folder
   - Compile in MetaEditor
   - Test on demo account first

4. **Restore Settings:**
   - Apply your saved parameter values
   - Verify all settings before live use
   - Monitor first few trades closely

## Reporting Issues

Found a bug or have a feature request?

1. Check existing issues on GitHub
2. Create new issue with:
   - EA version number
   - MT5 build number
   - Broker name
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit pull request with description

---

**Stay Updated:** Watch this repository for new releases and updates.

**Support:** For questions and support, open an issue on GitHub.
