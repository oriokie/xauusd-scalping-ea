# Simba Sniper EA - Start Here 🦁🎯

## What is Simba Sniper EA?

**Simba Sniper EA** is a professional-grade MetaTrader 5 Expert Advisor that implements an institutional multi-timeframe trading strategy. It analyzes H4, H1, M5, and optionally M1 timeframes to identify high-probability trade setups using smart money concepts.

This is a **completely separate EA** from the XAUUSDScalpingEA in this repository. It uses a different strategy and approach.

## 🚀 Quick Start

### 1. Installation
Read the detailed installation guide:
📖 **[SIMBA_SNIPER_INSTALLATION.md](SIMBA_SNIPER_INSTALLATION.md)**

### 2. Configuration
For parameter explanations and configuration help:
📖 **[SIMBA_SNIPER_README.md](SIMBA_SNIPER_README.md)**

### 3. Quick Reference
For fast lookups while trading:
📖 **[SIMBA_SNIPER_QUICK_REFERENCE.md](SIMBA_SNIPER_QUICK_REFERENCE.md)**

## 📁 Files Overview

| File | Purpose | Size |
|------|---------|------|
| `SimbaSniperEA.mq5` | Main EA file - copy to MT5 Experts folder | 42 KB |
| `SIMBA_SNIPER_README.md` | Complete documentation and strategy guide | 13 KB |
| `SIMBA_SNIPER_QUICK_REFERENCE.md` | Quick lookup guide | 8.2 KB |
| `SIMBA_SNIPER_INSTALLATION.md` | Installation and testing guide | 13 KB |
| `SIMBA_SNIPER_CHANGELOG.md` | Version history and changes | 9.5 KB |
| `SIMBA_SNIPER_IMPLEMENTATION_SUMMARY.md` | Technical implementation details | 14 KB |

## 🎯 Core Features

### Multi-Timeframe Analysis
- **H4**: Trend bias (swing structure + displacement)
- **H1**: Zone detection (S/R, Order Blocks, FVGs)
- **M5**: Entry confirmation (BOS, liquidity sweeps)
- **M1**: Optional precision entry

### 9-Point Entry Validation
Every trade is validated against 9 criteria before execution:
1. H4 Trend Alignment
2. H1 Zone Present
3. Break of Structure
4. Liquidity Sweep (optional)
5. Fair Value Gap (optional)
6. Order Block
7. ATR Zone Validation
8. Valid Risk/Reward
9. Session Filter

**Configurable**: Set minimum points required (default 6/9)

### Professional Dashboard
Real-time on-chart display showing:
- H4 trend direction
- Zone/OB/FVG counts
- Validation score (X/9)
- Account statistics
- ATR values
- Session status

## 📋 5-Minute Setup

1. **Copy** `SimbaSniperEA.mq5` to MT5 `Experts` folder
2. **Compile** in MetaEditor (F7) - verify 0 errors
3. **Attach** to any XAUUSD chart
4. **Set** `SessionGMTOffset` for your broker
5. **Enable** AutoTrading button

Dashboard should appear immediately!

## ⚙️ Critical Settings

Before trading, verify these settings:

```
SessionGMTOffset = ?     ← SET THIS for your broker!
                            (usually 0, -2, or -3)

RiskPercentage = 1.0     ← Start conservative (0.5-1.0%)

MinValidationPoints = 6  ← Higher = more selective
```

## 🧪 Testing Protocol

**DO NOT skip testing!**

1. **Strategy Tester** (1-2 days)
   - Test 6+ months historical data
   - Verify win rate 50%+
   - Check profit factor >1.5

2. **Demo Account** (2-4 weeks)
   - Real-time market testing
   - Monitor daily performance
   - Verify no critical errors

3. **Live Micro Lots** (Optional, 4+ weeks)
   - Only if demo successful
   - Start 0.01 lots
   - Conservative parameters

## 📚 Documentation Guide

### For New Users
Start here → **[SIMBA_SNIPER_INSTALLATION.md](SIMBA_SNIPER_INSTALLATION.md)**

### For Configuration
Go here → **[SIMBA_SNIPER_README.md](SIMBA_SNIPER_README.md)**

### For Quick Lookups
Check here → **[SIMBA_SNIPER_QUICK_REFERENCE.md](SIMBA_SNIPER_QUICK_REFERENCE.md)**

### For Troubleshooting
All guides have troubleshooting sections

### For Version History
See → **[SIMBA_SNIPER_CHANGELOG.md](SIMBA_SNIPER_CHANGELOG.md)**

## 🎓 Strategy Concepts

The EA implements institutional trading concepts:

- **Swing Structure**: Higher highs/lows pattern
- **Displacement**: Strong directional moves
- **Order Blocks**: Institutional order zones
- **Fair Value Gaps**: Price imbalances
- **Liquidity Sweeps**: Stop hunts
- **Break of Structure**: Trend continuation

## ⚠️ Important Warnings

🚨 **ALWAYS test on demo first** (minimum 2-4 weeks)  
🚨 **NEVER risk more than you can afford to lose**  
🚨 **SET correct SessionGMTOffset** for your broker  
🚨 **START with low risk percentage** (0.5-1.0%)  
🚨 **MONITOR closely** especially first month  
🚨 **USE VPS** for 24/7 operation  
🚨 **UNDERSTAND the strategy** before trading  

## 📊 Expected Performance

Realistic targets with default settings:

| Metric | Target |
|--------|--------|
| Trade Frequency | 1-5 per week |
| Win Rate | 50-65% |
| Risk/Reward | 1:2 minimum |
| Monthly Return | 5-15% |
| Max Drawdown | <10% |

## 🔍 Troubleshooting

### No Trades Executing?
- Check H4 Trend is not NEUTRAL
- Verify validation score meets minimum
- Check session is ACTIVE
- Review error messages on dashboard

### Too Many Trades?
- Increase `MinValidationPoints` to 7 or 8
- Enable more required validations
- Review validation settings

### Dashboard Not Showing?
- Set `ShowDashboard = true`
- Adjust position (DashboardX, DashboardY)
- Check Experts log for errors

## 💡 Pro Tips

1. **Session Offset**: Most important setting to configure correctly
2. **Start Conservative**: Use MinValidationPoints = 7 initially
3. **Monitor Validation**: Watch which points are commonly met
4. **Backtest Thoroughly**: 6+ months minimum
5. **Keep Journal**: Document all trades and adjustments
6. **Be Patient**: Quality over quantity

## 🤝 Support

For help and questions:
1. Read the comprehensive documentation
2. Check troubleshooting sections
3. Review Experts log in MT5
4. Test on demo account first

## 📜 License & Disclaimer

This EA is provided for educational and trading purposes.

**Risk Warning**: Trading involves substantial risk of loss. Past performance does not guarantee future results. Always test thoroughly on demo accounts before live trading.

## 🎯 Current Version

**Version**: 1.00  
**Release Date**: 2026-01-02  
**Status**: Complete - Ready for Testing

## 📞 Quick Links

- **Installation Guide**: [SIMBA_SNIPER_INSTALLATION.md](SIMBA_SNIPER_INSTALLATION.md)
- **Full Documentation**: [SIMBA_SNIPER_README.md](SIMBA_SNIPER_README.md)
- **Quick Reference**: [SIMBA_SNIPER_QUICK_REFERENCE.md](SIMBA_SNIPER_QUICK_REFERENCE.md)
- **Changelog**: [SIMBA_SNIPER_CHANGELOG.md](SIMBA_SNIPER_CHANGELOG.md)

---

**Ready to get started?**

→ Go to [SIMBA_SNIPER_INSTALLATION.md](SIMBA_SNIPER_INSTALLATION.md) for step-by-step setup instructions!

---

*Trade with the institutions, not against them.* 🦁🎯
