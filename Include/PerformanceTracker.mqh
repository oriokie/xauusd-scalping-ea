//+------------------------------------------------------------------+
//|                                           PerformanceTracker.mqh  |
//|                           Performance Analytics Module            |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Simba Sniper EA"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Trade Record Structure                                            |
//+------------------------------------------------------------------+
struct TradeRecord
{
    datetime entryTime;
    datetime exitTime;
    double entryPrice;
    double exitPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    int direction;        // 1 = Buy, -1 = Sell
    double profit;
    double profitPercent;
    
    // MAE/MFE tracking
    double maxAdverseExcursion;      // Worst price against position
    double maxFavorableExcursion;    // Best price for position
    
    // Setup details
    int validationPoints;
    double weightedScore;
    string setupType;     // "BREAKOUT", "REVERSAL", etc.
    string session;       // "LONDON", "NEWYORK", "ASIAN"
    
    // Additional metrics
    int barsHeld;
    double riskRewardActual;
};

//+------------------------------------------------------------------+
//| Performance Tracker Class                                         |
//+------------------------------------------------------------------+
class CPerformanceTracker
{
private:
    TradeRecord m_tradeHistory[];
    int m_maxHistorySize;
    
    // Current open position tracking
    struct OpenPositionTrack
    {
        ulong ticket;
        double entryPrice;
        double stopLoss;
        double takeProfit;
        double currentMAE;
        double currentMFE;
        datetime entryTime;
        bool isTracking;
    };
    
    OpenPositionTrack m_currentPosition;
    
    // Session statistics
    struct SessionStats
    {
        int trades;
        int wins;
        int losses;
        double totalProfit;
        double avgWin;
        double avgLoss;
    };
    
    SessionStats m_londonStats;
    SessionStats m_newYorkStats;
    SessionStats m_asianStats;
    
    // Setup type statistics
    struct SetupStats
    {
        int trades;
        int wins;
        double totalProfit;
        double avgExpectancy;
    };
    
    SetupStats m_breakoutStats;
    SetupStats m_reversalStats;
    SetupStats m_continuationStats;
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    CPerformanceTracker()
    {
        m_maxHistorySize = 1000;
        ArrayResize(m_tradeHistory, 0);
        ArraySetAsSeries(m_tradeHistory, true);
        
        m_currentPosition.isTracking = false;
        
        // Initialize session stats
        ZeroMemory(m_londonStats);
        ZeroMemory(m_newYorkStats);
        ZeroMemory(m_asianStats);
        
        // Initialize setup stats
        ZeroMemory(m_breakoutStats);
        ZeroMemory(m_reversalStats);
        ZeroMemory(m_continuationStats);
    }
    
    //+------------------------------------------------------------------+
    //| Start tracking a new position                                    |
    //+------------------------------------------------------------------+
    void StartTrackingPosition(ulong ticket, double entryPrice, double stopLoss, 
                               double takeProfit, datetime entryTime)
    {
        m_currentPosition.ticket = ticket;
        m_currentPosition.entryPrice = entryPrice;
        m_currentPosition.stopLoss = stopLoss;
        m_currentPosition.takeProfit = takeProfit;
        m_currentPosition.currentMAE = 0.0;
        m_currentPosition.currentMFE = 0.0;
        m_currentPosition.entryTime = entryTime;
        m_currentPosition.isTracking = true;
    }
    
    //+------------------------------------------------------------------+
    //| Update MAE/MFE for current position                              |
    //+------------------------------------------------------------------+
    void UpdateCurrentPosition(double currentBid, double currentAsk, bool isBuy)
    {
        if(!m_currentPosition.isTracking)
            return;
        
        double currentPrice = isBuy ? currentBid : currentAsk;
        double priceMove = currentPrice - m_currentPosition.entryPrice;
        
        if(isBuy)
        {
            // For buy position
            // MFE = highest price reached above entry
            if(priceMove > m_currentPosition.currentMFE)
                m_currentPosition.currentMFE = priceMove;
            
            // MAE = lowest price reached below entry (negative value)
            if(priceMove < m_currentPosition.currentMAE)
                m_currentPosition.currentMAE = priceMove;
        }
        else
        {
            // For sell position
            // MFE = lowest price reached below entry (inverted)
            if(-priceMove > m_currentPosition.currentMFE)
                m_currentPosition.currentMFE = -priceMove;
            
            // MAE = highest price reached above entry (inverted, negative)
            if(-priceMove < m_currentPosition.currentMAE)
                m_currentPosition.currentMAE = -priceMove;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Record completed trade                                           |
    //+------------------------------------------------------------------+
    void RecordTrade(datetime entryTime, datetime exitTime, double entryPrice, 
                     double exitPrice, double stopLoss, double takeProfit,
                     double lotSize, int direction, double profit,
                     int validationPoints, double weightedScore,
                     string setupType, string session)
    {
        // Shift array and add new trade
        int currentSize = ArraySize(m_tradeHistory);
        if(currentSize >= m_maxHistorySize)
        {
            // Remove oldest trade
            ArrayResize(m_tradeHistory, m_maxHistorySize - 1);
            currentSize = m_maxHistorySize - 1;
        }
        
        ArrayResize(m_tradeHistory, currentSize + 1);
        ArraySetAsSeries(m_tradeHistory, true);
        
        // Create trade record
        TradeRecord trade;
        trade.entryTime = entryTime;
        trade.exitTime = exitTime;
        trade.entryPrice = entryPrice;
        trade.exitPrice = exitPrice;
        trade.stopLoss = stopLoss;
        trade.takeProfit = takeProfit;
        trade.lotSize = lotSize;
        trade.direction = direction;
        trade.profit = profit;
        
        // Calculate profit percent (relative to risk)
        double riskAmount = MathAbs(entryPrice - stopLoss) * lotSize;
        trade.profitPercent = (riskAmount > 0) ? (profit / riskAmount) * 100.0 : 0.0;
        
        // Set MAE/MFE from current tracking
        if(m_currentPosition.isTracking)
        {
            trade.maxAdverseExcursion = m_currentPosition.currentMAE;
            trade.maxFavorableExcursion = m_currentPosition.currentMFE;
            m_currentPosition.isTracking = false;
        }
        else
        {
            trade.maxAdverseExcursion = 0.0;
            trade.maxFavorableExcursion = 0.0;
        }
        
        // Setup details
        trade.validationPoints = validationPoints;
        trade.weightedScore = weightedScore;
        trade.setupType = setupType;
        trade.session = session;
        
        // Calculate additional metrics
        trade.barsHeld = (int)((exitTime - entryTime) / PeriodSeconds(PERIOD_M5));
        
        double riskDistance = MathAbs(entryPrice - stopLoss);
        double rewardDistance = MathAbs(exitPrice - entryPrice);
        trade.riskRewardActual = (riskDistance > 0) ? (rewardDistance / riskDistance) : 0.0;
        if(direction == -1) // Sell
            trade.riskRewardActual = (profit >= 0) ? trade.riskRewardActual : -trade.riskRewardActual;
        else if(profit < 0) // Buy loss
            trade.riskRewardActual = -trade.riskRewardActual;
        
        // Add to history
        m_tradeHistory[0] = trade;
        
        // Update session stats
        UpdateSessionStats(session, profit);
        
        // Update setup type stats
        UpdateSetupStats(setupType, profit);
    }
    
    //+------------------------------------------------------------------+
    //| Update session statistics                                        |
    //+------------------------------------------------------------------+
    void UpdateSessionStats(string session, double profit)
    {
        SessionStats *stats = NULL;
        
        if(session == "LONDON")
            stats = &m_londonStats;
        else if(session == "NEWYORK")
            stats = &m_newYorkStats;
        else if(session == "ASIAN")
            stats = &m_asianStats;
        
        if(stats != NULL)
        {
            stats.trades++;
            stats.totalProfit += profit;
            
            if(profit > 0)
            {
                stats.wins++;
                stats.avgWin = (stats.avgWin * (stats.wins - 1) + profit) / stats.wins;
            }
            else
            {
                stats.losses++;
                stats.avgLoss = (stats.avgLoss * (stats.losses - 1) + profit) / stats.losses;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Update setup type statistics                                     |
    //+------------------------------------------------------------------+
    void UpdateSetupStats(string setupType, double profit)
    {
        SetupStats *stats = NULL;
        
        if(StringFind(setupType, "BREAKOUT") >= 0)
            stats = &m_breakoutStats;
        else if(StringFind(setupType, "REVERSAL") >= 0)
            stats = &m_reversalStats;
        else if(StringFind(setupType, "CONTINUATION") >= 0)
            stats = &m_continuationStats;
        
        if(stats != NULL)
        {
            stats.trades++;
            stats.totalProfit += profit;
            if(profit > 0)
                stats.wins++;
            
            // Calculate expectancy
            int wins = stats.wins;
            int losses = stats.trades - wins;
            if(stats.trades > 0)
            {
                double winRate = (double)wins / stats.trades;
                double avgProfit = stats.totalProfit / stats.trades;
                stats.avgExpectancy = avgProfit;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Calculate overall expectancy                                     |
    //+------------------------------------------------------------------+
    double CalculateExpectancy()
    {
        int totalTrades = ArraySize(m_tradeHistory);
        if(totalTrades == 0)
            return 0.0;
        
        double totalProfit = 0.0;
        for(int i = 0; i < totalTrades; i++)
            totalProfit += m_tradeHistory[i].profit;
        
        return totalProfit / totalTrades;
    }
    
    //+------------------------------------------------------------------+
    //| Get average MAE                                                  |
    //+------------------------------------------------------------------+
    double GetAverageMAE()
    {
        int count = ArraySize(m_tradeHistory);
        if(count == 0) return 0.0;
        
        double totalMAE = 0.0;
        for(int i = 0; i < count; i++)
            totalMAE += MathAbs(m_tradeHistory[i].maxAdverseExcursion);
        
        return totalMAE / count;
    }
    
    //+------------------------------------------------------------------+
    //| Get average MFE                                                  |
    //+------------------------------------------------------------------+
    double GetAverageMFE()
    {
        int count = ArraySize(m_tradeHistory);
        if(count == 0) return 0.0;
        
        double totalMFE = 0.0;
        for(int i = 0; i < count; i++)
            totalMFE += m_tradeHistory[i].maxFavorableExcursion;
        
        return totalMFE / count;
    }
    
    //+------------------------------------------------------------------+
    //| Get session performance summary                                  |
    //+------------------------------------------------------------------+
    string GetSessionSummary(string session)
    {
        SessionStats *stats = NULL;
        
        if(session == "LONDON")
            stats = &m_londonStats;
        else if(session == "NEWYORK")
            stats = &m_newYorkStats;
        else if(session == "ASIAN")
            stats = &m_asianStats;
        
        if(stats == NULL || stats.trades == 0)
            return StringFormat("%s: No trades", session);
        
        double winRate = (stats.trades > 0) ? ((double)stats.wins / stats.trades) * 100.0 : 0.0;
        
        return StringFormat("%s: %d trades | WR: %.1f%% | P/L: %.2f",
                           session, stats.trades, winRate, stats.totalProfit);
    }
    
    //+------------------------------------------------------------------+
    //| Get setup type performance summary                               |
    //+------------------------------------------------------------------+
    string GetSetupSummary(string setupType)
    {
        SetupStats *stats = NULL;
        
        if(setupType == "BREAKOUT")
            stats = &m_breakoutStats;
        else if(setupType == "REVERSAL")
            stats = &m_reversalStats;
        else if(setupType == "CONTINUATION")
            stats = &m_continuationStats;
        
        if(stats == NULL || stats.trades == 0)
            return StringFormat("%s: No trades", setupType);
        
        double winRate = (stats.trades > 0) ? ((double)stats.wins / stats.trades) * 100.0 : 0.0;
        
        return StringFormat("%s: %d trades | WR: %.1f%% | Exp: %.2f",
                           setupType, stats.trades, winRate, stats.avgExpectancy);
    }
    
    //+------------------------------------------------------------------+
    //| Get diagnostic summary                                           |
    //+------------------------------------------------------------------+
    string GetDiagnosticSummary()
    {
        return StringFormat("Trades: %d | Exp: %.2f | AvgMAE: %.2f | AvgMFE: %.2f",
                           ArraySize(m_tradeHistory),
                           CalculateExpectancy(),
                           GetAverageMAE(),
                           GetAverageMFE());
    }
    
    //+------------------------------------------------------------------+
    //| Reset all statistics                                             |
    //+------------------------------------------------------------------+
    void ResetStats()
    {
        ArrayResize(m_tradeHistory, 0);
        ZeroMemory(m_londonStats);
        ZeroMemory(m_newYorkStats);
        ZeroMemory(m_asianStats);
        ZeroMemory(m_breakoutStats);
        ZeroMemory(m_reversalStats);
        ZeroMemory(m_continuationStats);
    }
};
