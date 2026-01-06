//+------------------------------------------------------------------+
//|                                             MarketAnalysis.mqh   |
//|                           Market Analysis & Entry Quality Module |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Simba Sniper EA"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Market Regime Enumeration                                         |
//+------------------------------------------------------------------+
enum MARKET_REGIME
{
    REGIME_STRONG_TREND,      // Strong trending market
    REGIME_WEAK_TREND,        // Weak trending market
    REGIME_RANGING,           // Range-bound market
    REGIME_HIGH_VOLATILITY,   // High volatility / news events
    REGIME_CONSOLIDATION      // Low volatility consolidation
};

//+------------------------------------------------------------------+
//| Entry Quality Grade                                               |
//+------------------------------------------------------------------+
enum ENTRY_GRADE
{
    GRADE_A,  // Excellent setup (8+ weighted points)
    GRADE_B,  // Good setup (6-8 weighted points)
    GRADE_C,  // Acceptable setup (4-6 weighted points)
    GRADE_D   // Poor setup (< 4 weighted points, should skip)
};

//+------------------------------------------------------------------+
//| Market Analysis Class                                             |
//+------------------------------------------------------------------+
class CMarketAnalysis
{
private:
    MARKET_REGIME m_currentRegime;
    double m_trendStrength;
    double m_volatilityLevel;
    bool m_isNewsTime;
    
    // Confluence detection
    int m_confluenceCount;
    string m_confluenceFactors[];
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    CMarketAnalysis()
    {
        m_currentRegime = REGIME_RANGING;
        m_trendStrength = 0.0;
        m_volatilityLevel = 0.0;
        m_isNewsTime = false;
        m_confluenceCount = 0;
        ArrayResize(m_confluenceFactors, 0);
    }
    
    //+------------------------------------------------------------------+
    //| Detect market regime                                             |
    //+------------------------------------------------------------------+
    MARKET_REGIME DetectMarketRegime(string symbol, ENUM_TIMEFRAMES timeframe, 
                                     double currentATR, double avgATR,
                                     int emaTrend) // 1=bullish, -1=bearish, 0=neutral
    {
        // High volatility detection
        if(currentATR > avgATR * 1.4)
        {
            m_currentRegime = REGIME_HIGH_VOLATILITY;
            m_volatilityLevel = (currentATR / avgATR) * 100.0;
            return m_currentRegime;
        }
        
        // Low volatility / consolidation
        if(currentATR < avgATR * 0.6)
        {
            m_currentRegime = REGIME_CONSOLIDATION;
            m_volatilityLevel = (currentATR / avgATR) * 100.0;
            return m_currentRegime;
        }
        
        // Calculate trend strength using ADX-like logic
        m_trendStrength = CalculateTrendStrength(symbol, timeframe);
        m_volatilityLevel = (currentATR / avgATR) * 100.0;
        
        // Strong trend: high directional movement
        if(m_trendStrength > 70.0 && emaTrend != 0)
        {
            m_currentRegime = REGIME_STRONG_TREND;
        }
        // Weak trend: some directional bias but not strong
        else if(m_trendStrength > 40.0 && emaTrend != 0)
        {
            m_currentRegime = REGIME_WEAK_TREND;
        }
        // Ranging: no clear direction
        else
        {
            m_currentRegime = REGIME_RANGING;
        }
        
        return m_currentRegime;
    }
    
    //+------------------------------------------------------------------+
    //| Calculate trend strength (0-100 scale)                           |
    //+------------------------------------------------------------------+
    double CalculateTrendStrength(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        int bars = 20;
        double totalMove = 0.0;
        double directionalMove = 0.0;
        
        for(int i = 1; i < bars; i++)
        {
            double high = iHigh(symbol, timeframe, i);
            double low = iLow(symbol, timeframe, i);
            double close = iClose(symbol, timeframe, i);
            double prevClose = iClose(symbol, timeframe, i + 1);
            
            totalMove += MathAbs(high - low);
            directionalMove += MathAbs(close - prevClose);
        }
        
        if(totalMove == 0) return 0.0;
        
        // Calculate efficiency ratio (0-100)
        double efficiency = (directionalMove / totalMove) * 100.0;
        
        // Additional: Check if moves are in same direction
        int upMoves = 0, downMoves = 0;
        for(int i = 1; i < bars; i++)
        {
            if(iClose(symbol, timeframe, i) > iClose(symbol, timeframe, i + 1))
                upMoves++;
            else
                downMoves++;
        }
        
        double directionality = (MathAbs(upMoves - downMoves) / (double)bars) * 100.0;
        
        // Combine efficiency and directionality
        return (efficiency * 0.6 + directionality * 0.4);
    }
    
    //+------------------------------------------------------------------+
    //| Detect confluence (multiple factors aligning)                    |
    //+------------------------------------------------------------------+
    int DetectConfluence(bool h4Trend, bool h1Zone, bool bos, bool fvg, 
                        bool orderBlock, bool asianLevel, bool validRR)
    {
        m_confluenceCount = 0;
        ArrayResize(m_confluenceFactors, 0);
        
        // Major confluence: H4 trend + H1 zone + Valid RR
        if(h4Trend && h1Zone && validRR)
        {
            m_confluenceCount++;
            ArrayResize(m_confluenceFactors, ArraySize(m_confluenceFactors) + 1);
            m_confluenceFactors[ArraySize(m_confluenceFactors) - 1] = "H4Trend+Zone+RR";
        }
        
        // Structure confluence: BOS + Order Block
        if(bos && orderBlock)
        {
            m_confluenceCount++;
            ArrayResize(m_confluenceFactors, ArraySize(m_confluenceFactors) + 1);
            m_confluenceFactors[ArraySize(m_confluenceFactors) - 1] = "BOS+OrderBlock";
        }
        
        // Zone confluence: FVG + Order Block + H1 Zone
        if(fvg && orderBlock && h1Zone)
        {
            m_confluenceCount++;
            ArrayResize(m_confluenceFactors, ArraySize(m_confluenceFactors) + 1);
            m_confluenceFactors[ArraySize(m_confluenceFactors) - 1] = "FVG+OB+Zone";
        }
        
        // Asian session confluence: Asian level + BOS
        if(asianLevel && bos)
        {
            m_confluenceCount++;
            ArrayResize(m_confluenceFactors, ArraySize(m_confluenceFactors) + 1);
            m_confluenceFactors[ArraySize(m_confluenceFactors) - 1] = "Asian+BOS";
        }
        
        // Triple confirmation: H4 + Zone + BOS
        if(h4Trend && h1Zone && bos)
        {
            m_confluenceCount++;
            ArrayResize(m_confluenceFactors, ArraySize(m_confluenceFactors) + 1);
            m_confluenceFactors[ArraySize(m_confluenceFactors) - 1] = "H4+Zone+BOS";
        }
        
        return m_confluenceCount;
    }
    
    //+------------------------------------------------------------------+
    //| Calculate entry quality grade                                    |
    //+------------------------------------------------------------------+
    ENTRY_GRADE CalculateEntryGrade(double weightedScore, int confluenceCount,
                                    MARKET_REGIME regime)
    {
        // Base grade on weighted score
        double adjustedScore = weightedScore;
        
        // Bonus for confluence
        adjustedScore += confluenceCount * 0.5;
        
        // Regime adjustments
        if(regime == REGIME_STRONG_TREND)
            adjustedScore += 1.0; // Bonus for strong trend
        else if(regime == REGIME_HIGH_VOLATILITY)
            adjustedScore -= 1.0; // Penalty for high volatility
        else if(regime == REGIME_RANGING)
            adjustedScore -= 0.5; // Slight penalty for ranging
        
        // Grade assignment
        if(adjustedScore >= 8.0)
            return GRADE_A;
        else if(adjustedScore >= 6.0)
            return GRADE_B;
        else if(adjustedScore >= 4.0)
            return GRADE_C;
        else
            return GRADE_D;
    }
    
    //+------------------------------------------------------------------+
    //| Get recommended position size multiplier based on grade          |
    //+------------------------------------------------------------------+
    double GetGradeMultiplier(ENTRY_GRADE grade)
    {
        switch(grade)
        {
            case GRADE_A:
                return 1.2;  // 120% of normal position for excellent setups
            case GRADE_B:
                return 1.0;  // 100% - normal position
            case GRADE_C:
                return 0.7;  // 70% - reduced position for acceptable setups
            case GRADE_D:
                return 0.0;  // Skip trade - poor quality
            default:
                return 1.0;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Check if entry timing is optimal                                 |
    //+------------------------------------------------------------------+
    bool IsOptimalEntryTiming(int currentHour)
    {
        // Avoid low-probability hours
        // Based on typical gold trading patterns
        
        // Dead hours (low liquidity): 22:00-01:00 GMT
        if(currentHour >= 22 || currentHour <= 1)
            return false;
        
        // Asian session close / European open transition: 07:00-09:00 GMT (can be choppy)
        if(currentHour >= 7 && currentHour <= 8)
            return false;
        
        // Optimal times:
        // London open: 08:00-12:00 GMT
        // NY open: 13:00-17:00 GMT
        // London-NY overlap: 13:00-16:00 GMT (best)
        
        if((currentHour >= 9 && currentHour <= 12) ||   // London session
           (currentHour >= 13 && currentHour <= 17))    // NY session
        {
            return true;
        }
        
        // Neutral times
        return true; // Allow if not in avoid list
    }
    
    //+------------------------------------------------------------------+
    //| Get market regime as string                                      |
    //+------------------------------------------------------------------+
    string GetRegimeString()
    {
        switch(m_currentRegime)
        {
            case REGIME_STRONG_TREND: return "STRONG_TREND";
            case REGIME_WEAK_TREND: return "WEAK_TREND";
            case REGIME_RANGING: return "RANGING";
            case REGIME_HIGH_VOLATILITY: return "HIGH_VOL";
            case REGIME_CONSOLIDATION: return "CONSOLIDATION";
            default: return "UNKNOWN";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Get entry grade as string                                        |
    //+------------------------------------------------------------------+
    string GetGradeString(ENTRY_GRADE grade)
    {
        switch(grade)
        {
            case GRADE_A: return "A (Excellent)";
            case GRADE_B: return "B (Good)";
            case GRADE_C: return "C (Acceptable)";
            case GRADE_D: return "D (Poor)";
            default: return "Unknown";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Get diagnostic info                                              |
    //+------------------------------------------------------------------+
    string GetDiagnosticInfo()
    {
        return StringFormat("Regime: %s | Trend: %.1f%% | Vol: %.1f%% | Confluence: %d",
                           GetRegimeString(),
                           m_trendStrength,
                           m_volatilityLevel,
                           m_confluenceCount);
    }
    
    //+------------------------------------------------------------------+
    //| Get current regime                                               |
    //+------------------------------------------------------------------+
    MARKET_REGIME GetCurrentRegime() { return m_currentRegime; }
    
    //+------------------------------------------------------------------+
    //| Get trend strength                                               |
    //+------------------------------------------------------------------+
    double GetTrendStrength() { return m_trendStrength; }
    
    //+------------------------------------------------------------------+
    //| Get confluence count                                             |
    //+------------------------------------------------------------------+
    int GetConfluenceCount() { return m_confluenceCount; }
};
