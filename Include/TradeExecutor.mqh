//+------------------------------------------------------------------+
//|                                              TradeExecutor.mqh   |
//|                           Trade Execution & Exit Strategy Module |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Simba Sniper EA"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Exit Phase Enumeration                                           |
//+------------------------------------------------------------------+
enum EXIT_PHASE
{
    PHASE_INITIAL,        // Position just opened
    PHASE_PARTIAL_1,      // First partial profit taken
    PHASE_PARTIAL_2,      // Second partial profit taken
    PHASE_TRAILING,       // Trailing stop active
    PHASE_CLOSED          // Position closed
};

//+------------------------------------------------------------------+
//| Position State Structure                                         |
//+------------------------------------------------------------------+
struct PositionState
{
    ulong ticket;
    double entryPrice;
    double currentSL;
    double currentTP;
    double highestPrice;  // For trailing (buy) / lowest for sell
    EXIT_PHASE phase;
    datetime entryTime;
    int barsHeld;
    bool trailingPaused;
    datetime lastTrailUpdate;
};

//+------------------------------------------------------------------+
//| Trade Executor Class                                             |
//+------------------------------------------------------------------+
class CTradeExecutor
{
private:
    CTrade m_trade;
    CPositionInfo m_position;
    
    PositionState m_state;
    
    // Exit strategy parameters
    bool m_usePartialExits;
    double m_partial1Percent;  // % of position to close at first TP
    double m_partial1RR;       // R:R ratio for first partial
    double m_partial2Percent;  // % of position to close at second TP
    double m_partial2RR;       // R:R ratio for second partial
    
    bool m_useSmartTrailing;
    double m_trailingATRMultiplier;
    int m_trailingPauseBars;   // Pause trailing during pullbacks
    
    bool m_useTimeDecay;
    int m_timeDecayBars;       // Exit if no movement after X bars
    double m_timeDecayRR;      // Minimum R:R to hold position
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    CTradeExecutor()
    {
        // Default exit strategy parameters
        m_usePartialExits = true;
        m_partial1Percent = 50.0;  // Close 50% at first TP
        m_partial1RR = 1.5;        // First TP at 1.5R
        m_partial2Percent = 30.0;  // Close 30% at second TP
        m_partial2RR = 2.5;        // Second TP at 2.5R
        
        m_useSmartTrailing = true;
        m_trailingATRMultiplier = 1.0;
        m_trailingPauseBars = 3;
        
        m_useTimeDecay = true;
        m_timeDecayBars = 100;
        m_timeDecayRR = 0.5;  // If not at 0.5R after 100 bars, consider exit
        
        ResetState();
    }
    
    //+------------------------------------------------------------------+
    //| Initialize with parameters                                        |
    //+------------------------------------------------------------------+
    void Init(bool usePartials, double partial1Pct, double partial1RR,
              double partial2Pct, double partial2RR,
              bool useTrailing, double trailingMult, int pauseBars,
              bool useDecay, int decayBars, double decayRR)
    {
        m_usePartialExits = usePartials;
        m_partial1Percent = partial1Pct;
        m_partial1RR = partial1RR;
        m_partial2Percent = partial2Pct;
        m_partial2RR = partial2RR;
        
        m_useSmartTrailing = useTrailing;
        m_trailingATRMultiplier = trailingMult;
        m_trailingPauseBars = pauseBars;
        
        m_useTimeDecay = useDecay;
        m_timeDecayBars = decayBars;
        m_timeDecayRR = decayRR;
    }
    
    //+------------------------------------------------------------------+
    //| Start tracking a position                                        |
    //+------------------------------------------------------------------+
    void StartTracking(ulong ticket, double entryPrice, double sl, double tp)
    {
        m_state.ticket = ticket;
        m_state.entryPrice = entryPrice;
        m_state.currentSL = sl;
        m_state.currentTP = tp;
        m_state.highestPrice = entryPrice;
        m_state.phase = PHASE_INITIAL;
        m_state.entryTime = TimeCurrent();
        m_state.barsHeld = 0;
        m_state.trailingPaused = false;
        m_state.lastTrailUpdate = 0;
    }
    
    //+------------------------------------------------------------------+
    //| Manage position (call on every tick or bar)                      |
    //+------------------------------------------------------------------+
    void ManagePosition(double currentBid, double currentAsk, double currentATR,
                       ENUM_TIMEFRAMES timeframe, string symbol)
    {
        if(m_state.ticket == 0) return;
        
        // Select position
        if(!m_position.SelectByTicket(m_state.ticket))
        {
            ResetState();
            return;
        }
        
        bool isBuy = (m_position.Type() == POSITION_TYPE_BUY);
        double currentPrice = isBuy ? currentBid : currentAsk;
        
        // Update bars held
        m_state.barsHeld = (int)((TimeCurrent() - m_state.entryTime) / PeriodSeconds(timeframe));
        
        // Update highest/lowest price
        if(isBuy && currentPrice > m_state.highestPrice)
            m_state.highestPrice = currentPrice;
        else if(!isBuy && currentPrice < m_state.highestPrice)
            m_state.highestPrice = currentPrice;
        
        // Calculate current R:R
        double risk = MathAbs(m_state.entryPrice - m_state.currentSL);
        double currentRR = 0.0;
        
        if(risk > 0)
        {
            if(isBuy)
                currentRR = (currentPrice - m_state.entryPrice) / risk;
            else
                currentRR = (m_state.entryPrice - currentPrice) / risk;
        }
        
        // Phase-based management
        switch(m_state.phase)
        {
            case PHASE_INITIAL:
                ManageInitialPhase(currentRR, currentPrice, isBuy, symbol);
                break;
            case PHASE_PARTIAL_1:
                ManagePartial1Phase(currentRR, currentPrice, isBuy, symbol);
                break;
            case PHASE_PARTIAL_2:
            case PHASE_TRAILING:
                ManageTrailingPhase(currentPrice, currentATR, isBuy, symbol);
                break;
        }
        
        // Time decay check
        if(m_useTimeDecay && m_state.barsHeld > m_timeDecayBars)
        {
            if(currentRR < m_timeDecayRR)
            {
                // Close position due to time decay
                ClosePosition("Time decay exit", symbol);
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Manage initial phase (waiting for first partial TP)              |
    //+------------------------------------------------------------------+
    void ManageInitialPhase(double currentRR, double currentPrice, bool isBuy, string symbol)
    {
        if(!m_usePartialExits)
        {
            // No partials, move to trailing immediately
            m_state.phase = PHASE_TRAILING;
            return;
        }
        
        // Check if reached first partial TP
        if(currentRR >= m_partial1RR)
        {
            // Close partial position
            double currentVolume = m_position.Volume();
            double closeVolume = currentVolume * (m_partial1Percent / 100.0);
            
            // Normalize volume
            double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
            double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
            closeVolume = MathFloor(closeVolume / lotStep) * lotStep;
            
            if(closeVolume >= minLot && closeVolume < currentVolume)
            {
                if(m_trade.PositionClosePartial(m_state.ticket, closeVolume))
                {
                    Print(StringFormat("Partial 1 closed: %.2f%% at R:R %.2f", m_partial1Percent, currentRR));
                    m_state.phase = PHASE_PARTIAL_1;
                    
                    // Move SL to breakeven
                    MoveSLToBreakeven(symbol);
                }
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Manage partial 1 phase (waiting for second partial TP)           |
    //+------------------------------------------------------------------+
    void ManagePartial1Phase(double currentRR, double currentPrice, bool isBuy, string symbol)
    {
        // Check if reached second partial TP
        if(currentRR >= m_partial2RR)
        {
            // Close second partial
            double currentVolume = m_position.Volume();
            double closeVolume = currentVolume * (m_partial2Percent / 100.0);
            
            // Normalize volume
            double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
            double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
            closeVolume = MathFloor(closeVolume / lotStep) * lotStep;
            
            if(closeVolume >= minLot && closeVolume < currentVolume)
            {
                if(m_trade.PositionClosePartial(m_state.ticket, closeVolume))
                {
                    Print(StringFormat("Partial 2 closed: %.2f%% at R:R %.2f", m_partial2Percent, currentRR));
                    m_state.phase = PHASE_TRAILING;
                    return; // Exit after closing partial
                }
            }
        }
        
        // If not at second partial yet, stay in PARTIAL_1 phase
        // Trailing will be applied anyway in the main ManagePosition
    }
    
    //+------------------------------------------------------------------+
    //| Manage trailing phase (smart trailing stop)                      |
    //+------------------------------------------------------------------+
    void ManageTrailingPhase(double currentPrice, double currentATR, bool isBuy, string symbol)
    {
        if(!m_useSmartTrailing) return;
        
        double trailingDistance = currentATR * m_trailingATRMultiplier;
        double newSL = 0.0;
        
        if(isBuy)
        {
            // For buy: trail below highest price
            newSL = m_state.highestPrice - trailingDistance;
            
            // Only move SL up, never down
            if(newSL > m_state.currentSL)
            {
                // Check if price is moving away (pullback) - pause trailing
                if(currentPrice < m_state.highestPrice - (trailingDistance * 0.5))
                {
                    if(!m_state.trailingPaused)
                    {
                        m_state.trailingPaused = true;
                        m_state.lastTrailUpdate = TimeCurrent();
                    }
                    return; // Don't update SL during pullback
                }
                else
                {
                    m_state.trailingPaused = false;
                }
                
                // Update stop loss
                if(m_trade.PositionModify(m_state.ticket, newSL, m_state.currentTP))
                {
                    m_state.currentSL = newSL;
                }
            }
        }
        else
        {
            // For sell: trail above lowest price
            newSL = m_state.highestPrice + trailingDistance;
            
            // Only move SL down, never up
            if(newSL < m_state.currentSL || m_state.currentSL == 0)
            {
                // Check if price is moving away (pullback) - pause trailing
                if(currentPrice > m_state.highestPrice + (trailingDistance * 0.5))
                {
                    if(!m_state.trailingPaused)
                    {
                        m_state.trailingPaused = true;
                        m_state.lastTrailUpdate = TimeCurrent();
                    }
                    return; // Don't update SL during pullback
                }
                else
                {
                    m_state.trailingPaused = false;
                }
                
                // Update stop loss
                if(m_trade.PositionModify(m_state.ticket, newSL, m_state.currentTP))
                {
                    m_state.currentSL = newSL;
                }
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Move stop loss to breakeven                                      |
    //+------------------------------------------------------------------+
    void MoveSLToBreakeven(string symbol)
    {
        double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
        double newSL = m_state.entryPrice;
        
        bool isBuy = (m_position.Type() == POSITION_TYPE_BUY);
        if(isBuy)
            newSL = m_state.entryPrice + spread; // Breakeven + spread for buy
        else
            newSL = m_state.entryPrice - spread; // Breakeven - spread for sell
        
        if(m_trade.PositionModify(m_state.ticket, newSL, m_state.currentTP))
        {
            m_state.currentSL = newSL;
            Print("Stop loss moved to breakeven");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Close position                                                    |
    //+------------------------------------------------------------------+
    void ClosePosition(string reason, string symbol)
    {
        if(m_trade.PositionClose(m_state.ticket))
        {
            Print(StringFormat("Position closed: %s", reason));
            ResetState();
        }
    }
    
    //+------------------------------------------------------------------+
    //| Reset state                                                       |
    //+------------------------------------------------------------------+
    void ResetState()
    {
        m_state.ticket = 0;
        m_state.entryPrice = 0;
        m_state.currentSL = 0;
        m_state.currentTP = 0;
        m_state.highestPrice = 0;
        m_state.phase = PHASE_INITIAL;
        m_state.entryTime = 0;
        m_state.barsHeld = 0;
        m_state.trailingPaused = false;
        m_state.lastTrailUpdate = 0;
    }
    
    //+------------------------------------------------------------------+
    //| Get diagnostic info                                              |
    //+------------------------------------------------------------------+
    string GetDiagnosticInfo()
    {
        if(m_state.ticket == 0)
            return "No active position";
        
        string phaseStr = "";
        switch(m_state.phase)
        {
            case PHASE_INITIAL: phaseStr = "INITIAL"; break;
            case PHASE_PARTIAL_1: phaseStr = "PARTIAL_1"; break;
            case PHASE_PARTIAL_2: phaseStr = "PARTIAL_2"; break;
            case PHASE_TRAILING: phaseStr = "TRAILING"; break;
            case PHASE_CLOSED: phaseStr = "CLOSED"; break;
        }
        
        return StringFormat("Ticket: %llu | Phase: %s | Bars: %d | Trailing: %s",
                           m_state.ticket, phaseStr, m_state.barsHeld,
                           m_state.trailingPaused ? "PAUSED" : "ACTIVE");
    }
    
    //+------------------------------------------------------------------+
    //| Check if tracking a position                                     |
    //+------------------------------------------------------------------+
    bool IsTracking() { return (m_state.ticket != 0); }
    
    //+------------------------------------------------------------------+
    //| Get current phase                                                |
    //+------------------------------------------------------------------+
    EXIT_PHASE GetPhase() { return m_state.phase; }
};
