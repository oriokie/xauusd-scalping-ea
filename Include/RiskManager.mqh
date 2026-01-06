//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh  |
//|                           Risk Management Module                 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Simba Sniper EA"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    CAccountInfo m_account;
    
    // Streak tracking
    int m_consecutiveWins;
    int m_consecutiveLosses;
    
    // Drawdown tracking
    double m_peakBalance;
    double m_currentDrawdown;
    
    // Volatility regime
    enum VOLATILITY_REGIME { VOLATILITY_LOW, VOLATILITY_MEDIUM, VOLATILITY_HIGH };
    VOLATILITY_REGIME m_currentVolatilityRegime;
    
    // Time-based exposure
    datetime m_firstTradeToday;
    int m_tradesThisHour;
    datetime m_currentHourStart;
    
    // Risk parameters
    double m_baseRiskPercent;
    double m_maxDailyLossPercent;
    double m_maxDrawdownPercent;
    
    // Dynamic risk adjustments
    bool m_useStreakAdjustment;
    bool m_useDrawdownAdjustment;
    bool m_useVolatilityAdjustment;
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    CRiskManager()
    {
        m_consecutiveWins = 0;
        m_consecutiveLosses = 0;
        m_peakBalance = m_account.Balance();
        m_currentDrawdown = 0.0;
        m_currentVolatilityRegime = VOLATILITY_MEDIUM;
        m_firstTradeToday = 0;
        m_tradesThisHour = 0;
        m_currentHourStart = 0;
        
        // Default risk parameters
        m_baseRiskPercent = 1.0;
        m_maxDailyLossPercent = 3.0;
        m_maxDrawdownPercent = 10.0;
        
        // Default adjustments enabled
        m_useStreakAdjustment = true;
        m_useDrawdownAdjustment = true;
        m_useVolatilityAdjustment = true;
    }
    
    //+------------------------------------------------------------------+
    //| Initialize with parameters                                        |
    //+------------------------------------------------------------------+
    void Init(double baseRisk, double maxDailyLoss, double maxDrawdown,
              bool useStreak, bool useDrawdown, bool useVolatility)
    {
        m_baseRiskPercent = baseRisk;
        m_maxDailyLossPercent = maxDailyLoss;
        m_maxDrawdownPercent = maxDrawdown;
        m_useStreakAdjustment = useStreak;
        m_useDrawdownAdjustment = useDrawdown;
        m_useVolatilityAdjustment = useVolatility;
        m_peakBalance = m_account.Balance();
    }
    
    //+------------------------------------------------------------------+
    //| Calculate dynamic position size                                  |
    //+------------------------------------------------------------------+
    double CalculatePositionSize(double stopLossDistance, string symbol = NULL)
    {
        if(symbol == NULL) symbol = _Symbol;
        
        // Start with base risk
        double adjustedRisk = m_baseRiskPercent;
        
        // Apply streak adjustment
        if(m_useStreakAdjustment)
            adjustedRisk *= GetStreakMultiplier();
        
        // Apply drawdown adjustment
        if(m_useDrawdownAdjustment)
            adjustedRisk *= GetDrawdownMultiplier();
        
        // Apply volatility adjustment
        if(m_useVolatilityAdjustment)
            adjustedRisk *= GetVolatilityMultiplier();
        
        // Cap adjusted risk
        adjustedRisk = MathMin(adjustedRisk, m_baseRiskPercent * 1.5);  // Max 150% of base
        adjustedRisk = MathMax(adjustedRisk, m_baseRiskPercent * 0.25); // Min 25% of base
        
        // Calculate position size
        double balance = m_account.Balance();
        double riskAmount = balance * (adjustedRisk / 100.0);
        
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        
        double positionSize = 0.0;
        if(stopLossDistance > 0 && tickValue > 0 && tickSize > 0)
        {
            double ticksInSL = stopLossDistance / tickSize;
            positionSize = riskAmount / (ticksInSL * tickValue);
            
            // Normalize to lot step
            positionSize = MathFloor(positionSize / lotStep) * lotStep;
            
            // Ensure within limits
            positionSize = MathMax(positionSize, minLot);
            positionSize = MathMin(positionSize, maxLot);
        }
        else
        {
            positionSize = minLot;
        }
        
        return positionSize;
    }
    
    //+------------------------------------------------------------------+
    //| Update after trade result                                        |
    //+------------------------------------------------------------------+
    void OnTradeResult(bool isWin, double profit)
    {
        // Update streak
        if(isWin)
        {
            m_consecutiveWins++;
            m_consecutiveLosses = 0;
        }
        else
        {
            m_consecutiveLosses++;
            m_consecutiveWins = 0;
        }
        
        // Update peak balance and drawdown
        double currentBalance = m_account.Balance();
        if(currentBalance > m_peakBalance)
            m_peakBalance = currentBalance;
        
        m_currentDrawdown = ((m_peakBalance - currentBalance) / m_peakBalance) * 100.0;
    }
    
    //+------------------------------------------------------------------+
    //| Update volatility regime                                         |
    //+------------------------------------------------------------------+
    void UpdateVolatilityRegime(double currentATR, double avgATR)
    {
        if(currentATR > avgATR * 1.3)
            m_currentVolatilityRegime = VOLATILITY_HIGH;
        else if(currentATR < avgATR * 0.7)
            m_currentVolatilityRegime = VOLATILITY_LOW;
        else
            m_currentVolatilityRegime = VOLATILITY_MEDIUM;
    }
    
    //+------------------------------------------------------------------+
    //| Check if can open new position (exposure limits)                 |
    //+------------------------------------------------------------------+
    bool CanOpenPosition(int maxTradesPerHour = 3)
    {
        // Check hourly limit
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        datetime hourStart = StringToTime(StringFormat("%04d.%02d.%02d %02d:00:00", 
                                                       dt.year, dt.mon, dt.day, dt.hour));
        
        if(hourStart != m_currentHourStart)
        {
            m_currentHourStart = hourStart;
            m_tradesThisHour = 0;
        }
        
        if(m_tradesThisHour >= maxTradesPerHour)
            return false;
        
        // Check drawdown limit
        if(m_currentDrawdown > m_maxDrawdownPercent)
            return false;
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Record new trade opening                                         |
    //+------------------------------------------------------------------+
    void OnTradeOpen()
    {
        m_tradesThisHour++;
    }
    
    //+------------------------------------------------------------------+
    //| Get streak multiplier                                            |
    //+------------------------------------------------------------------+
    double GetStreakMultiplier()
    {
        // Reduce risk after consecutive losses
        if(m_consecutiveLosses >= 3)
            return 0.5;  // 50% risk after 3+ losses
        else if(m_consecutiveLosses >= 2)
            return 0.75; // 75% risk after 2 losses
        
        // Slightly increase after consecutive wins (cautious)
        if(m_consecutiveWins >= 3)
            return 1.2;  // 120% risk after 3+ wins
        else if(m_consecutiveWins >= 2)
            return 1.1;  // 110% risk after 2 wins
        
        return 1.0; // Normal risk
    }
    
    //+------------------------------------------------------------------+
    //| Get drawdown multiplier                                          |
    //+------------------------------------------------------------------+
    double GetDrawdownMultiplier()
    {
        // Reduce risk proportionally to drawdown
        if(m_currentDrawdown >= 7.0)
            return 0.5;  // 50% risk at 7%+ drawdown
        else if(m_currentDrawdown >= 5.0)
            return 0.7;  // 70% risk at 5-7% drawdown
        else if(m_currentDrawdown >= 3.0)
            return 0.85; // 85% risk at 3-5% drawdown
        
        return 1.0; // Normal risk
    }
    
    //+------------------------------------------------------------------+
    //| Get volatility multiplier                                        |
    //+------------------------------------------------------------------+
    double GetVolatilityMultiplier()
    {
        switch(m_currentVolatilityRegime)
        {
            case VOLATILITY_HIGH:
                return 0.75; // Reduce risk by 25% in high volatility
            case VOLATILITY_LOW:
                return 1.1;  // Increase risk by 10% in low volatility
            default:
                return 1.0;  // Normal risk in medium volatility
        }
    }
    
    //+------------------------------------------------------------------+
    //| Get current adjusted risk percentage                             |
    //+------------------------------------------------------------------+
    double GetAdjustedRiskPercent()
    {
        double adjustedRisk = m_baseRiskPercent;
        
        if(m_useStreakAdjustment)
            adjustedRisk *= GetStreakMultiplier();
        
        if(m_useDrawdownAdjustment)
            adjustedRisk *= GetDrawdownMultiplier();
        
        if(m_useVolatilityAdjustment)
            adjustedRisk *= GetVolatilityMultiplier();
        
        return adjustedRisk;
    }
    
    //+------------------------------------------------------------------+
    //| Get diagnostic info                                              |
    //+------------------------------------------------------------------+
    string GetDiagnosticInfo()
    {
        string volRegime = "MEDIUM";
        if(m_currentVolatilityRegime == VOLATILITY_HIGH)
            volRegime = "HIGH";
        else if(m_currentVolatilityRegime == VOLATILITY_LOW)
            volRegime = "LOW";
        
        return StringFormat("Streak: W%d L%d | DD: %.1f%% | Vol: %s | AdjRisk: %.2f%%",
                           m_consecutiveWins, m_consecutiveLosses,
                           m_currentDrawdown,
                           volRegime,
                           GetAdjustedRiskPercent());
    }
    
    //+------------------------------------------------------------------+
    //| Reset daily counters                                             |
    //+------------------------------------------------------------------+
    void ResetDaily()
    {
        m_firstTradeToday = 0;
        // Note: We don't reset streak or drawdown on daily basis
    }
    
    //+------------------------------------------------------------------+
    //| Get current drawdown                                             |
    //+------------------------------------------------------------------+
    double GetCurrentDrawdown() { return m_currentDrawdown; }
    
    //+------------------------------------------------------------------+
    //| Get consecutive wins                                             |
    //+------------------------------------------------------------------+
    int GetConsecutiveWins() { return m_consecutiveWins; }
    
    //+------------------------------------------------------------------+
    //| Get consecutive losses                                           |
    //+------------------------------------------------------------------+
    int GetConsecutiveLosses() { return m_consecutiveLosses; }
};
