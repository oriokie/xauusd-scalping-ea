# Repository Summary - XAUUSD Scalping EA Project

## Overview

This repository contains **TWO SEPARATE Expert Advisors** for MetaTrader 5:

1. **XAUUSDScalpingEA.mq5** - Original scalping EA (pre-existing)
2. **SimbaSniperEA.mq5** - NEW multi-timeframe institutional EA (just implemented)

## ⚠️ Important Note

**These are completely independent EAs with NO relationship to each other:**
- Different trading strategies
- Different code implementations
- Different documentation
- Can be used separately or together

---

## EA #1: XAUUSD Scalping EA

### File
- `XAUUSDScalpingEA.mq5` (43 KB, 1,166 lines)

### Strategy
- Scalping strategy using MACD, Bollinger Bands, RSI
- Liquidity sweep detection
- Mean reversion exits
- Adaptive risk management
- Higher timeframe trend filter

### Documentation
- `README.md` - Main documentation
- `USER_GUIDE.md`
- `ADVANCED_GUIDE.md`
- `QUICK_REFERENCE.md`
- `INSTALLATION.md`
- `FEATURES_CHECKLIST.md`
- `PROFITABILITY_IMPROVEMENTS.md`
- `CHANGELOG.md`
- And more...

### Status
✅ Fully functional and tested

---

## EA #2: Simba Sniper EA ⭐ NEW

### File
- `SimbaSniperEA.mq5` (42 KB, 1,201 lines)

### Strategy
- Multi-timeframe institutional analysis (H4→H1→M5→M1)
- 9-point entry validation system
- Order Block detection
- Fair Value Gap identification
- Break of Structure confirmation
- Liquidity sweep detection
- ATR-based zone validation
- Smart money concepts

### Documentation
- `SIMBA_SNIPER_START_HERE.md` ⭐ **Start here**
- `SIMBA_SNIPER_README.md` - Complete guide
- `SIMBA_SNIPER_QUICK_REFERENCE.md` - Quick lookup
- `SIMBA_SNIPER_INSTALLATION.md` - Setup guide
- `SIMBA_SNIPER_CHANGELOG.md` - Version history
- `SIMBA_SNIPER_IMPLEMENTATION_SUMMARY.md` - Technical details

### Status
✅ Complete - Ready for testing (v1.00, 2026-01-02)

---

## Quick Start Guide

### For Simba Sniper EA (NEW)
1. Read: `SIMBA_SNIPER_START_HERE.md`
2. Copy: `SimbaSniperEA.mq5` to MT5 Experts folder
3. Compile and test

### For XAUUSD Scalping EA (Original)
1. Read: `README.md`
2. Copy: `XAUUSDScalpingEA.mq5` to MT5 Experts folder
3. Compile and test

---

## File Structure

```
xauusd-scalping-ea/
├── EA Files
│   ├── XAUUSDScalpingEA.mq5          (Original EA)
│   └── SimbaSniperEA.mq5             (NEW Institutional EA)
│
├── Simba Sniper Documentation (NEW)
│   ├── SIMBA_SNIPER_START_HERE.md
│   ├── SIMBA_SNIPER_README.md
│   ├── SIMBA_SNIPER_QUICK_REFERENCE.md
│   ├── SIMBA_SNIPER_INSTALLATION.md
│   ├── SIMBA_SNIPER_CHANGELOG.md
│   └── SIMBA_SNIPER_IMPLEMENTATION_SUMMARY.md
│
├── XAUUSD Scalping EA Documentation (Original)
│   ├── README.md
│   ├── USER_GUIDE.md
│   ├── ADVANCED_GUIDE.md
│   ├── QUICK_REFERENCE.md
│   ├── INSTALLATION.md
│   ├── FEATURES_CHECKLIST.md
│   ├── PROFITABILITY_IMPROVEMENTS.md
│   ├── CHANGELOG.md
│   ├── IMPLEMENTATION_COMPLETE.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── TRADING_STRATEGY_FIXES.md
│   └── CONTRIBUTING.md
│
└── General Files
    ├── LICENSE
    ├── .gitignore
    └── REPOSITORY_SUMMARY.md (this file)
```

---

## Comparison

| Feature | XAUUSD Scalping EA | Simba Sniper EA |
|---------|-------------------|-----------------|
| **Strategy Type** | Scalping | Multi-Timeframe Institutional |
| **Primary Timeframe** | Current chart | H4/H1/M5/M1 |
| **Main Indicators** | MACD, BB, RSI, ATR | ATR (all TFs) |
| **Entry Logic** | Technical indicators | 9-point validation |
| **Institutional Focus** | Liquidity sweeps | Full institutional analysis |
| **Trade Frequency** | Higher (scalping) | Lower (quality setups) |
| **Documentation** | Extensive (original) | Comprehensive (new) |
| **Lines of Code** | 1,166 | 1,201 |
| **Version** | 1.20+ | 1.00 |

---

## Which EA Should I Use?

### Use XAUUSD Scalping EA if you want:
- ✅ More frequent trades
- ✅ Scalping approach
- ✅ Traditional technical indicators
- ✅ Tested and refined over time
- ✅ Mean reversion strategy

### Use Simba Sniper EA if you want:
- ✅ Institutional-style trading
- ✅ Multi-timeframe analysis
- ✅ Smart money concepts (OBs, FVGs)
- ✅ Stricter entry validation
- ✅ Quality over quantity
- ✅ NEW implementation (needs testing)

### Use Both if you want:
- ✅ Diversified strategies
- ✅ Different market approaches
- ✅ Risk spreading
- ⚠️ Ensure sufficient capital
- ⚠️ Monitor both carefully

---

## Testing Recommendations

### For Either EA:
1. **Always test on demo first** (minimum 2 weeks)
2. **Backtest thoroughly** (6+ months historical data)
3. **Start with conservative settings**
4. **Monitor daily performance**
5. **Never risk more than you can afford to lose**

---

## Support

### For Simba Sniper EA:
- Start: `SIMBA_SNIPER_START_HERE.md`
- Full docs: `SIMBA_SNIPER_README.md`
- Quick help: `SIMBA_SNIPER_QUICK_REFERENCE.md`

### For XAUUSD Scalping EA:
- Start: `README.md`
- User guide: `USER_GUIDE.md`
- Quick help: `QUICK_REFERENCE.md`

---

## Version Information

### Simba Sniper EA
- **Version**: 1.00
- **Release**: 2026-01-02
- **Status**: Complete - Ready for testing

### XAUUSD Scalping EA
- **Version**: 1.20+
- **Status**: Active and tested

---

## License

Both EAs are provided for educational and trading purposes.
See `LICENSE` file for details.

---

## Risk Warning

**⚠️ IMPORTANT**: Trading financial instruments involves substantial risk of loss. Past performance does not guarantee future results. Always:
- Test on demo accounts first
- Start with minimum risk
- Understand the strategy
- Monitor performance
- Never trade with money you can't afford to lose

---

## Repository Statistics

- **Total EA Files**: 2
- **Total Lines of Code**: 2,367
- **Documentation Files**: 20+
- **Total Documentation**: ~150 KB

---

**Last Updated**: 2026-01-02  
**Repository**: oriokie/xauusd-scalping-ea
