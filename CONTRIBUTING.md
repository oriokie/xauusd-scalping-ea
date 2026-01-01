# Contributing to XAUUSD Scalping EA

First off, thank you for considering contributing to this project! It's people like you that make this Expert Advisor better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)

## Code of Conduct

This project and everyone participating in it is governed by a simple principle: **Be respectful and constructive**.

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When reporting a bug, include:**

- **MT5 Version:** Your MetaTrader 5 build number
- **EA Version:** Version of the Expert Advisor
- **Broker:** Your broker name (helps identify platform differences)
- **Description:** Clear description of the issue
- **Steps to Reproduce:** Detailed steps to reproduce the behavior
- **Expected Behavior:** What you expected to happen
- **Actual Behavior:** What actually happened
- **Screenshots:** If applicable
- **Logs:** Any relevant log entries from the Experts tab

**Example Bug Report:**

```
**MT5 Version:** Build 3850
**EA Version:** 1.0.0
**Broker:** IC Markets

**Description:**
Trailing stop not activating when profit exceeds MinProfitPoints

**Steps to Reproduce:**
1. Attach EA to XAUUSD M15 chart
2. Set UseTrailingStop = true
3. Set MinProfitPoints = 20
4. Wait for position to reach 25 points profit
5. Observe that trailing stop doesn't activate

**Expected:** Trailing stop should activate at 20+ points profit
**Actual:** Trailing stop never activates

**Logs:**
[Include relevant log entries]
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Before suggesting, please:

1. Check if it's already been suggested
2. Consider if it fits the EA's core purpose (scalping XAUUSD)
3. Think about how it benefits most users

**Enhancement Suggestion Template:**

```
**Feature Name:** [Name of the feature]

**Problem It Solves:**
[Describe what problem this addresses]

**Proposed Solution:**
[Describe your proposed implementation]

**Alternatives Considered:**
[Any alternative approaches you've thought about]

**Additional Context:**
[Screenshots, examples, or references]
```

### Contributing Code

We love code contributions! Here's how to do it:

1. **Fork the Repository**
2. **Create a Branch:** `git checkout -b feature/amazing-feature`
3. **Make Changes:** Implement your feature or fix
4. **Test Thoroughly:** On demo account, minimum 2 weeks
5. **Commit:** `git commit -m 'Add amazing feature'`
6. **Push:** `git push origin feature/amazing-feature`
7. **Open Pull Request:** Describe your changes

## Development Setup

### Prerequisites

- MetaTrader 5 (latest build)
- MetaEditor (comes with MT5)
- Access to XAUUSD trading (demo account minimum)
- Basic understanding of MQL5 programming

### Setting Up Development Environment

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/oriokie/xauusd-scalping-ea.git
   ```

2. **Open in MetaEditor:**
   - Launch MetaEditor (F4 from MT5)
   - File > Open > Navigate to cloned repository
   - Open `XAUUSDScalpingEA.mq5`

3. **Configure MT5 Data Folder:**
   - In MT5: File > Open Data Folder
   - Navigate to MQL5/Experts
   - Create symbolic link or copy files here

4. **Test Compilation:**
   - In MetaEditor, press F7 (Compile)
   - Ensure no errors

### Development Workflow

1. **Create Feature Branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes:**
   - Edit code in MetaEditor
   - Follow coding standards (see below)
   - Add comments for complex logic

3. **Test Changes:**
   - Compile and fix any errors
   - Test on demo account
   - Verify no regressions

4. **Commit Changes:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

5. **Push and Create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### MQL5 Style Guide

**Naming Conventions:**

```mql5
// Constants: UPPER_SNAKE_CASE
#define MAX_POSITIONS 10

// Global Variables: camelCase with type prefix
int g_signalValue;
double g_atrBuffer[];

// Input Parameters: PascalCase
input double RiskPercentage = 1.0;

// Functions: PascalCase
void ExecuteBuyOrder()
{
    // Function body
}

// Local Variables: camelCase
double lotSize = 0.01;
int signalType = 0;
```

**Code Formatting:**

```mql5
// Indentation: 4 spaces (not tabs)
if(condition)
{
    // Code here
}

// Braces: New line for opening brace
void FunctionName()
{
    // Code
}

// Spacing: Space after keywords
if(condition)
for(int i = 0; i < count; i++)
while(running)

// Operators: Spaces around operators
int result = a + b;
bool isValid = (value > 0) && (value < 100);
```

**Comments:**

```mql5
//+------------------------------------------------------------------+
//| Function: ExecuteBuyOrder                                         |
//| Description: Executes a buy market order with calculated SL/TP   |
//| Parameters: None                                                 |
//| Returns: void                                                    |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
{
    // Calculate entry price
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Determine SL and TP levels
    double sl = ask - (atrBuffer[0] * SL_ATR_Multiplier);
    double tp = ask + (atrBuffer[0] * TP_ATR_Multiplier);
    
    // Execute trade
    trade.Buy(lotSize, _Symbol, ask, sl, tp, "Scalp Buy");
}
```

**Error Handling:**

```mql5
// Always check return values
if(!UpdateIndicators())
{
    Print("Failed to update indicators");
    return;
}

// Handle trade execution errors
if(!trade.Buy(lotSize, _Symbol, ask, sl, tp))
{
    Print("Buy order failed: ", trade.ResultRetcode());
    SendNotification("Trade execution error");
}
```

### Best Practices

1. **Keep Functions Focused:**
   - One function = one responsibility
   - Maximum 50-100 lines per function
   - Extract complex logic into separate functions

2. **Avoid Magic Numbers:**
   ```mql5
   // Bad
   if(profit > 100)
   
   // Good
   const int MIN_PROFIT_CLOSE = 100;
   if(profit > MIN_PROFIT_CLOSE)
   ```

3. **Use Meaningful Names:**
   ```mql5
   // Bad
   double x = 1.5;
   int n = 0;
   
   // Good
   double atrMultiplier = 1.5;
   int positionCount = 0;
   ```

4. **Document Complex Logic:**
   ```mql5
   // Liquidity sweep detection:
   // Checks if price broke previous low then reversed
   // indicating institutional stop hunting
   bool bullishSweep = (low1 < low2) && 
                       (close1 > open1) && 
                       ((close1 - low1) > atr * 0.3);
   ```

5. **Minimize Global Variables:**
   - Use local variables when possible
   - Pass parameters to functions
   - Only use globals for EA-wide state

## Testing Guidelines

### Minimum Testing Requirements

Before submitting a PR, ensure:

1. **Compilation:**
   - Code compiles without errors
   - No warnings (or documented if unavoidable)

2. **Demo Account Testing:**
   - Minimum 2 weeks on demo
   - Test multiple market conditions:
     - Trending up
     - Trending down
     - Ranging/choppy
     - High volatility
     - Low volatility

3. **Backtesting:**
   - Minimum 6 months historical data
   - Use "Every tick based on real ticks"
   - Include realistic spreads
   - Document results

4. **Functional Testing:**
   - All entry signals work correctly
   - SL/TP calculated properly
   - Trailing stop activates
   - GUI displays correctly
   - Notifications sent
   - Daily limit enforced

### Testing Checklist

- [ ] Code compiles without errors
- [ ] Tested on demo account (2+ weeks)
- [ ] Backtested with historical data (6+ months)
- [ ] Entry signals working
- [ ] Exit logic functioning
- [ ] Risk management correct
- [ ] Lot size calculations accurate
- [ ] SL/TP levels appropriate
- [ ] Trailing stop working
- [ ] Session filters active
- [ ] News filter functioning
- [ ] GUI displaying correctly
- [ ] Notifications sending
- [ ] Daily reset working
- [ ] Error handling tested
- [ ] Edge cases considered
- [ ] Documentation updated

### Reporting Test Results

Include in your PR:

```
**Testing Summary:**

**Demo Account:**
- Duration: 2 weeks
- Trades: 45
- Win Rate: 64%
- Profit Factor: 1.8
- Max Drawdown: 3.2%

**Backtest:**
- Period: 2023.06.01 - 2023.12.31
- Trades: 287
- Win Rate: 61%
- Profit Factor: 1.6
- Max Drawdown: 8.5%

**Issues Found:**
None

**Market Conditions:**
Tested in trending and ranging markets
```

## Pull Request Process

### Before Submitting

1. **Update Documentation:**
   - Update README.md if adding features
   - Update CHANGELOG.md
   - Add/update code comments
   - Update USER_GUIDE.md if needed

2. **Test Thoroughly:**
   - Follow testing guidelines above
   - Fix any issues found
   - Verify no regressions

3. **Clean Up Code:**
   - Remove debug Print() statements
   - Remove commented-out code
   - Ensure consistent formatting
   - Check for typos

### PR Description Template

```markdown
## Description
[Brief description of changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Enhancement
- [ ] Documentation update

## Motivation and Context
[Why is this change needed? What problem does it solve?]

## Testing Performed
[Describe testing done - see Testing Guidelines]

## Checklist
- [ ] Code compiles without errors
- [ ] Tested on demo account (2+ weeks)
- [ ] Backtested with historical data
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic

## Screenshots (if applicable)
[Add screenshots of GUI changes, backtest results, etc.]

## Additional Notes
[Any other information reviewers should know]
```

### Review Process

1. **Automated Checks:**
   - Code must compile
   - Must pass basic validation

2. **Code Review:**
   - Maintainer reviews code quality
   - Checks adherence to standards
   - Verifies testing was performed

3. **Testing:**
   - Maintainer may test on demo
   - May request additional testing

4. **Approval:**
   - Once approved, will be merged
   - May request changes first

## Feature Development Priority

We prioritize contributions in this order:

1. **Bug Fixes:** Critical issues affecting functionality
2. **Performance:** Improvements to execution speed
3. **Risk Management:** Enhanced protection features
4. **Documentation:** Better guides and examples
5. **New Features:** Additional capabilities
6. **Optimizations:** Fine-tuning existing features

## Questions?

- **General Questions:** Open a Discussion on GitHub
- **Bug Reports:** Open an Issue
- **Feature Ideas:** Open an Issue with enhancement tag
- **Code Questions:** Comment on relevant code section

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in CHANGELOG.md
- Credited in code comments (for significant contributions)

Thank you for contributing! 🎉

---

**Remember:** The goal is to create a reliable, profitable, and safe Expert Advisor for the community. Quality over quantity!
