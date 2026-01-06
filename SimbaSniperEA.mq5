//+------------------------------------------------------------------+
//|                                              SimbaSniperEA.mq5    |
//|                           Multi-Timeframe Institutional Strategy  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Simba Sniper EA"
#property link      ""
#property version   "1.00"
#property strict
#property description "Institutional-grade multi-timeframe analysis EA"
#property description "H4 Trend -> H1 Zones -> M5 Entry -> Optional M1 Precision"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

// Custom modules
#include "Include/RiskManager.mqh"
#include "Include/PerformanceTracker.mqh"
#include "Include/MarketAnalysis.mqh"
#include "Include/TradeExecutor.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+

//--- Multi-Timeframe Settings
input group "=== Multi-Timeframe Analysis ==="
input ENUM_TIMEFRAMES H4_Timeframe = PERIOD_H4;    // H4: Trend Bias Timeframe
input ENUM_TIMEFRAMES H1_Timeframe = PERIOD_H1;    // H1: HTF Zones Timeframe
input ENUM_TIMEFRAMES M5_Timeframe = PERIOD_M5;    // M5: Entry Confirmation Timeframe
input ENUM_TIMEFRAMES M1_Timeframe = PERIOD_M1;    // M1: Precision Entry Timeframe (Optional)
input bool UseM1Precision = false;                 // Use M1 for precision entries

//--- Risk Management
input group "=== Risk Management ==="
input double RiskPercentage = 1.0;                 // Risk per trade (%)
input double MaxDailyLossPercent = 3.0;            // Maximum daily loss (%)
input double MaxDrawdownPercent = 10.0;            // Maximum drawdown (%)
input double MinRiskRewardRatio = 2.5;             // Minimum Risk/Reward Ratio
input int MaxPositions = 1;                        // Maximum concurrent positions
input int MaxTradesPerHour = 3;                    // Maximum trades per hour (exposure limit)
input bool UseDynamicRR = false;                   // Use dynamic R:R based on volatility
input double DynamicRR_Multiplier = 1.0;           // Dynamic R:R volatility multiplier
input bool UsePartialPositions = false;            // Use partial position scaling
input double PartialEntry_Percent = 50.0;          // Initial position size (% of full size)

//--- Advanced Risk Management
input group "=== Advanced Risk Management ==="
input bool UseStreakAdjustment = true;             // Adjust risk based on win/loss streak
input bool UseDrawdownAdjustment = true;           // Adjust risk based on drawdown
input bool UseVolatilityRiskAdjustment = true;     // Adjust risk based on volatility regime

// NOTE: Time-based exit parameters below are prepared for future implementation
// TODO: Implement time-based exit logic in OnTick() to check position age and close if thresholds exceeded
input int MaxHoldingTimeBars = 0;                  // [FUTURE] Max holding time in bars (0 = no limit)
input bool UseTimeBasedExit = false;               // [FUTURE] Enable time-based exit
input int TimeBasedExit_Bars = 100;                // [FUTURE] Exit if no movement after X bars

//--- ATR Settings
input group "=== ATR Settings ==="
input int ATR_Period = 14;                         // ATR Period
input double ATR_ZoneMultiplier = 1.5;             // ATR multiplier for zone validation
input double ATR_StopLossMultiplier = 2.5;         // Stop Loss ATR Multiplier (Increased for gold volatility)
input double ATR_TakeProfitMultiplier = 4.0;       // Take Profit ATR Multiplier
input double ATR_BreakoutMultiplier = 1.5;         // Breakout detection ATR multiplier

//--- Structure Detection Settings
input group "=== Structure Detection ==="
input int SwingLookback = 20;                      // Bars to lookback for swing points
input double MinDisplacementPercent = 0.3;         // Minimum displacement (% of ATR)
input int OrderBlockBars = 5;                      // Bars to analyze for Order Blocks
input int FVG_MinGapPoints = 10;                   // Minimum FVG gap in points (REDUCED from 20 to 10)
input bool UseSwingPointSL = true;                 // Use swing points for stop-loss
input bool UseBreakEvenStop = true;                // Enable break-even stop-loss
input double BreakEvenTriggerRatio = 0.5;          // Break-even trigger (ratio of TP distance)
input bool UseTrailingStop = true;                 // Enable trailing stop-loss
input double TrailingStopATRMultiplier = 1.0;      // Trailing stop ATR multiplier

//--- Performance Analytics
input group "=== Performance Analytics ==="
input bool EnablePerformanceTracking = true;       // Enable detailed performance tracking
input bool TrackMAE_MFE = true;                    // Track Maximum Adverse/Favorable Excursion
input bool ShowSessionStats = true;                // Show session-based statistics
input bool ShowSetupTypeStats = true;              // Show setup type statistics

//--- Entry Quality & Market Analysis
input group "=== Entry Quality & Analysis ==="
input bool UseEntryGrading = true;                 // Use entry quality grading (A/B/C/D)
input bool SkipGradeD = true;                      // Skip Grade D (poor quality) setups
input bool AdjustSizeByGrade = true;               // Adjust position size by grade (A=120%, B=100%, C=70%)
input bool UseConfluenceBonus = true;              // Add bonus points for confluence detection
input bool UseMarketRegimeFilter = true;           // Filter entries by market regime
input bool AvoidHighVolatilityRegime = true;       // Avoid trading in high volatility regime
input bool PreferStrongTrend = false;              // Only trade in strong trend regime (strict)

//--- Exit Strategy Enhancement
input group "=== Exit Strategy ==="
input bool UsePartialExits = true;                 // Enable partial profit taking
input double Partial1_Percent = 50.0;              // First partial: % of position to close
input double Partial1_RR = 1.5;                    // First partial: R:R ratio
input double Partial2_Percent = 30.0;              // Second partial: % of position to close
input double Partial2_RR = 2.5;                    // Second partial: R:R ratio
input bool UseSmartTrailing = true;                // Enable smart trailing stop
input double SmartTrailingATRMult = 1.0;           // Smart trailing ATR multiplier
input int TrailingPauseBars = 3;                   // Pause trailing during pullbacks (bars)
input bool UseTimeDecayExit = true;                // Enable time-decay exit
input int TimeDecayBars = 100;                     // Exit if no movement after X bars
input double TimeDecayMinRR = 0.5;                 // Minimum R:R to keep position open

//--- Diagnostics and Logging
input group "=== Diagnostics ==="
input bool EnableDetailedLogging = true;           // Enable detailed validation logging
input bool TrackNearMisses = true;                 // Track near-miss setups (trades close to minimum points)
input bool ShowValidationDetails = true;           // Show validation details on dashboard
input bool LogFVGStrategy = true;                  // Log FVG Strategy diagnostics
input bool LogBOSStrategy = true;                  // Log BOS Strategy diagnostics
input bool LogHTFZoneStrategy = true;              // Log HTF Zone Strategy diagnostics
input bool LogOBStrategy = true;                   // Log Order Block Strategy diagnostics
input bool LogBreakoutStrategy = true;             // Log Breakout Strategy diagnostics
input bool LogStrategyCriteria = true;             // Log detailed criteria checks for each strategy

//--- Entry Validation (11-Point System) - UPDATED for better trade execution
input group "=== 11-Point Entry Validation ==="
input int MinValidationPoints = 6;                 // Minimum validation points required (can be weighted or traditional points)
input bool UseWeightedScoring = true;              // Use weighted validation scoring (recommended)
input double H4TrendWeight = 3.0;                  // H4 Trend weight multiplier (CRITICAL)
input double RiskRewardWeight = 2.0;               // Risk/Reward weight multiplier (IMPORTANT)
input double SessionWeight = 1.5;                  // Session filter weight multiplier
input double ZoneWeight = 1.0;                     // Zone/Structure weight multiplier (default)
input bool UseEssentialOnly = false;               // Use only essential validations (H4 Trend + Session + Valid RR)
input bool Require_H4_Trend = true;                // 1. H4 Trend Alignment (ESSENTIAL)
input bool Require_H1_Zone = false;                // 2. H1 Zone Present (OPTIONAL - was required)
input bool Require_BOS = false;                    // 3. Break of Structure (OPTIONAL - was required)
input bool Require_LiquiditySweep = false;         // 4. Liquidity Sweep (OPTIONAL)
input bool Require_FVG = false;                    // 5. Fair Value Gap (OPTIONAL)
input bool Require_OrderBlock = false;             // 6. Order Block Confirmation (OPTIONAL - was required)
input bool Require_ATR_Zone = false;               // 7. ATR Zone Validation (OPTIONAL - was required)
input bool Require_ValidRR = true;                 // 8. Valid Risk/Reward (ESSENTIAL)
input bool Require_SessionFilter = true;           // 9. Trading Session Active (ESSENTIAL)

//--- Entry Strategy Selection
input group "=== Entry Strategy Type ==="
enum ENTRY_STRATEGY { STRATEGY_UNIVERSAL, STRATEGY_BREAKOUT, STRATEGY_REVERSAL, STRATEGY_CONTINUATION };
input ENTRY_STRATEGY EntryStrategy = STRATEGY_UNIVERSAL;  // Entry Strategy Type
input bool SessionSpecificRulesOptional = true;    // Make session-specific rules optional (recommended: true)

//--- Independent Trading Strategies System
input group "=== Independent Strategies (NEW) ==="
input bool UseIndependentStrategies = true;        // Enable Independent Strategies System
input bool EnableAllStrategies = true;             // Quick toggle: Enable all strategies

//--- FVG Strategy
input group "=== FVG Strategy ==="
input bool Enable_FVG_Strategy = false;            // Enable FVG Strategy
input double FVG_MinRR = 2.0;                      // FVG: Minimum Risk/Reward Ratio
input bool FVG_RequireRejection = false;           // FVG: Require rejection candle pattern
input bool FVG_RequireFresh = false;               // FVG: Require fresh FVG (< 20 bars old)
input int FVG_MaxAgeBars = 20;                     // FVG: Maximum age in bars

//--- BOS Strategy
input group "=== BOS Strategy ==="
input bool Enable_BOS_Strategy = false;            // Enable BOS Strategy
input double BOS_MinRR = 2.0;                      // BOS: Minimum Risk/Reward Ratio
input bool BOS_RequireVolumeExpansion = false;     // BOS: Require volume expansion (150% avg)
input double BOS_VolumeMultiplier = 1.5;           // BOS: Volume expansion multiplier
input bool BOS_RequireProximityToZone = false;     // BOS: Require proximity to H1 zone

//--- HTF Zone Strategy
input group "=== HTF Zone Strategy ==="
input bool Enable_HTFZone_Strategy = false;        // Enable HTF Zone Strategy
input double HTFZone_MinRR = 2.5;                  // HTF Zone: Minimum Risk/Reward Ratio
input int HTFZone_MinTouches = 3;                  // HTF Zone: Minimum touches required
input double HTFZone_MinStrength = 1.0;            // HTF Zone: Minimum strength score
input bool HTFZone_RequireRejection = true;        // HTF Zone: Require rejection candle (wick > 2x body)

//--- Order Block Strategy
input group "=== Order Block Strategy ==="
input bool Enable_OB_Strategy = false;             // Enable Order Block Strategy
input double OB_MinRR = 2.0;                       // OB: Minimum Risk/Reward Ratio
input bool OB_RequireFVG = false;                  // OB: Require FVG within OB
input bool OB_OnlyUntested = false;                // OB: Only untested blocks (no violation)

//--- Breakout Strategy (Asian Range)
input group "=== Breakout Strategy ==="
input bool Enable_Breakout_Strategy = false;       // Enable Breakout Strategy
input double Breakout_MinRR = 1.5;                 // Breakout: Minimum Risk/Reward Ratio
input bool Breakout_RequireVolumeExpansion = true; // Breakout: Require volume expansion
input double Breakout_VolumeMultiplier = 1.5;      // Breakout: Volume expansion multiplier
input bool Breakout_RequireATRExpansion = true;    // Breakout: Require ATR expansion
input double Breakout_ATRMultiplier = 1.5;         // Breakout: ATR expansion multiplier
input int Breakout_ATRAveragePeriod = 14;          // Breakout: ATR average period for expansion check

//--- Trading Sessions
input group "=== Trading Sessions ==="
input bool TradeLondonSession = true;              // Trade London Session
input bool TradeNewYorkSession = true;             // Trade New York Session
input bool TradeAsianSession = false;              // Trade Asian Session
input int AsianStartHour = 0;                      // Asian Start Hour (GMT)
input int AsianEndHour = 6;                        // Asian End Hour (GMT)
input int LondonStartHour = 8;                     // London Start Hour (GMT)
input int LondonEndHour = 17;                      // London End Hour (GMT)
input int NewYorkStartHour = 13;                   // New York Start Hour (GMT)
input int NewYorkEndHour = 22;                     // New York End Hour (GMT)
input int SessionGMTOffset = 0;                    // Broker GMT Offset
input bool UseAsianHighLow = true;                 // Use Asian High/Low levels
input bool AsianRangeBound = false;                // Asian session: range-bound strategy (RELAXED: set to false)
input bool LondonNYBreakout = false;               // London/NY sessions: breakout strategy (RELAXED: set to false)
input double AsianLevelDistanceMultiplier = 0.5;   // Asian level proximity multiplier (ATR)

//--- H4 Trend Detection Mode
input group "=== H4 Trend Detection ==="
enum TREND_MODE { TREND_STRICT, TREND_SIMPLE };
input TREND_MODE H4TrendMode = TREND_SIMPLE;       // H4 Trend Detection Mode (SIMPLE recommended)
input bool AllowWeakTrend = true;                  // Allow trades in weak trend conditions

//--- Additional Filters
input group "=== Additional Filters ==="
input bool UseSpreadFilter = true;                 // Enable spread filter
input double MaxSpreadPoints = 30.0;               // Maximum allowed spread in points
input bool UseNewsFilter = false;                  // Enable news filter (placeholder for future)
input bool UseTimeOfDayFilter = false;             // Enable time-of-day performance filter
input int AvoidTradingHourStart = 22;              // Avoid trading start hour (GMT)
input int AvoidTradingHourEnd = 1;                 // Avoid trading end hour (GMT)

//--- Dashboard Settings
input group "=== Dashboard Settings ==="
input bool ShowDashboard = true;                   // Show Dashboard
input int DashboardX = 20;                         // Dashboard X Position
input int DashboardY = 50;                         // Dashboard Y Position
input color DashboardBGColor = clrDarkSlateGray;   // Dashboard Background
input color DashboardTextColor = clrWhite;         // Dashboard Text Color

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

CTrade trade;
CPositionInfo positionInfo;
CAccountInfo accountInfo;

// Advanced modules
CRiskManager *riskManager;
CPerformanceTracker *perfTracker;
CMarketAnalysis *marketAnalysis;
CTradeExecutor *tradeExecutor;

// ATR Handles for each timeframe
int atrH4Handle, atrH1Handle, atrM5Handle, atrM1Handle;
double atrH4[], atrH1[], atrM5[], atrM1[];

// EMA Handles for trend confirmation
int ema20H4Handle, ema50H4Handle;
double ema20H4[], ema50H4[];

// Market Structure Variables
enum TREND_DIRECTION { TREND_BULLISH, TREND_BEARISH, TREND_NEUTRAL };
TREND_DIRECTION h4Trend = TREND_NEUTRAL;

struct SwingPoint {
    datetime time;
    double price;
    bool isHigh;
};

SwingPoint h4Swings[];
SwingPoint h1Swings[];

struct OrderBlock {
    datetime time;
    double high;
    double low;
    bool isBullish;
    bool isValid;
};

OrderBlock h1OrderBlocks[];

struct FairValueGap {
    datetime time;
    double upperBound;
    double lowerBound;
    bool isBullish;
    bool isFilled;
};

FairValueGap h1FVGs[];

struct SupportResistanceZone {
    double level;
    int touches;
    bool isSupport;
    double strength;
};

SupportResistanceZone h1Zones[];

// Asian Session High/Low Tracking
struct AsianSessionLevels {
    double high;
    double low;
    datetime sessionDate;
    bool isValid;
};

AsianSessionLevels asianLevels;

// Daily Statistics
datetime dailyStartTime;
double dailyStartBalance;
int dailyTrades = 0;
int dailyWins = 0;
int dailyLosses = 0;
bool tradingPaused = false;

// Entry Validation Tracking
struct EntryValidation {
    bool h4TrendValid;
    bool h1ZoneValid;
    bool bosDetected;
    bool liquiditySweep;
    bool fvgPresent;
    bool orderBlockValid;
    bool atrZoneValid;
    bool validRiskReward;
    bool sessionActive;
    bool breakoutDetected;
    bool asianLevelValid;
    int totalPoints;
    double weightedScore;  // Weighted validation score
};
};

EntryValidation currentValidation;

datetime lastBarTime;
string lastErrorMsg = "";

// Diagnostics tracking
int nearMissCount = 0;        // Setups that got close to minimum points
int validationFailCount[11];  // Track which validation points fail most often
string validationPointNames[11] = {
    "H4 Trend", "H1 Zone", "BOS", "Liquidity Sweep", "FVG", 
    "Order Block", "ATR Zone", "Breakout", "Asian Level", "Valid R:R", "Session Active"
};

// Constants
#define PRICE_UNSET 999999.0
#define DASHBOARD_WIDTH 380
#define DASHBOARD_HEIGHT 620

// Session tracking
enum SESSION_TYPE { SESSION_ASIAN, SESSION_LONDON, SESSION_NEWYORK, SESSION_NONE };
SESSION_TYPE currentSession = SESSION_NONE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize advanced modules
    riskManager = new CRiskManager();
    riskManager.Init(RiskPercentage, MaxDailyLossPercent, MaxDrawdownPercent,
                     UseStreakAdjustment, UseDrawdownAdjustment, UseVolatilityRiskAdjustment);
    
    perfTracker = new CPerformanceTracker();
    
    marketAnalysis = new CMarketAnalysis();
    
    tradeExecutor = new CTradeExecutor();
    tradeExecutor.Init(UsePartialExits, Partial1_Percent, Partial1_RR,
                      Partial2_Percent, Partial2_RR,
                      UseSmartTrailing, SmartTrailingATRMult, TrailingPauseBars,
                      UseTimeDecayExit, TimeDecayBars, TimeDecayMinRR);
    
    // Initialize ATR indicators for each timeframe
    atrH4Handle = iATR(_Symbol, H4_Timeframe, ATR_Period);
    atrH1Handle = iATR(_Symbol, H1_Timeframe, ATR_Period);
    atrM5Handle = iATR(_Symbol, M5_Timeframe, ATR_Period);
    
    if(UseM1Precision)
        atrM1Handle = iATR(_Symbol, M1_Timeframe, ATR_Period);
    
    // Initialize EMA indicators for H4 trend confirmation
    ema20H4Handle = iMA(_Symbol, H4_Timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
    ema50H4Handle = iMA(_Symbol, H4_Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
    
    if(atrH4Handle == INVALID_HANDLE || atrH1Handle == INVALID_HANDLE || 
       atrM5Handle == INVALID_HANDLE || ema20H4Handle == INVALID_HANDLE || 
       ema50H4Handle == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }
    
    // Set arrays as series
    ArraySetAsSeries(atrH4, true);
    ArraySetAsSeries(atrH1, true);
    ArraySetAsSeries(atrM5, true);
    ArraySetAsSeries(ema20H4, true);
    ArraySetAsSeries(ema50H4, true);
    if(UseM1Precision) ArraySetAsSeries(atrM1, true);
    
    // Initialize arrays
    ArrayResize(h4Swings, 0);
    ArrayResize(h1Swings, 0);
    ArrayResize(h1OrderBlocks, 0);
    ArrayResize(h1FVGs, 0);
    ArrayResize(h1Zones, 0);
    
    // Initialize Asian levels
    asianLevels.high = 0;
    asianLevels.low = PRICE_UNSET;
    asianLevels.sessionDate = 0;
    asianLevels.isValid = false;
    
    // Initialize daily tracking
    dailyStartTime = TimeCurrent();
    dailyStartBalance = accountInfo.Balance();
    
    // Create dashboard
    if(ShowDashboard)
        CreateDashboard();
    
    Print("Simba Sniper EA initialized successfully");
    Print("Multi-Timeframe Analysis: H4->H1->M5", UseM1Precision ? "->M1" : "");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up advanced modules
    if(CheckPointer(riskManager) == POINTER_DYNAMIC)
        delete riskManager;
    if(CheckPointer(perfTracker) == POINTER_DYNAMIC)
        delete perfTracker;
    if(CheckPointer(marketAnalysis) == POINTER_DYNAMIC)
        delete marketAnalysis;
    if(CheckPointer(tradeExecutor) == POINTER_DYNAMIC)
        delete tradeExecutor;
    
    // Release indicators
    IndicatorRelease(atrH4Handle);
    IndicatorRelease(atrH1Handle);
    IndicatorRelease(atrM5Handle);
    IndicatorRelease(ema20H4Handle);
    IndicatorRelease(ema50H4Handle);
    if(UseM1Precision) IndicatorRelease(atrM1Handle);
    
    // Remove dashboard
    DeleteDashboard();
    
    Print("Simba Sniper EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new day
    CheckNewDay();
    
    // Update current session
    UpdateCurrentSession();
    
    // Update Asian session high/low
    if(UseAsianHighLow)
        UpdateAsianSessionLevels();
    
    // Update ATR buffers
    if(!UpdateATRBuffers())
        return;
    
    // Check for new bar on M5
    datetime currentBarTime = iTime(_Symbol, M5_Timeframe, 0);
    bool isNewBar = (currentBarTime != lastBarTime);
    
    if(isNewBar)
    {
        lastBarTime = currentBarTime;
        
        // Update risk manager volatility regime
        if(CheckPointer(riskManager) == POINTER_DYNAMIC && ArraySize(atrH1) >= 3)
        {
            double avgATR = (atrH1[0] + atrH1[1] + atrH1[2]) / 3.0;
            riskManager.UpdateVolatilityRegime(atrH1[0], avgATR);
        }
        
        // Update market structure analysis
        AnalyzeH4Trend();
        DetectH1Zones();
        DetectH1OrderBlocks();
        DetectH1FairValueGaps();
        
        // Check for entry opportunities
        if(!tradingPaused && CountOpenPositions() < MaxPositions)
        {
            // Check risk manager exposure limits
            bool canTrade = true;
            if(CheckPointer(riskManager) == POINTER_DYNAMIC)
                canTrade = riskManager.CanOpenPosition(MaxTradesPerHour);
            
            if(!canTrade)
            {
                if(EnableDetailedLogging)
                    Print("Trading restricted: Hourly limit or drawdown exceeded");
            }
            else if(CheckDailyLossLimit())
            {
                int signal = AnalyzeEntryOpportunity();
                
                if(signal == 1) // Buy signal
                    ExecuteBuyOrder();
                else if(signal == -1) // Sell signal
                    ExecuteSellOrder();
            }
            else
            {
                tradingPaused = true;
                Print("Trading paused: Daily loss limit reached");
            }
        }
    }
    
    // Update MAE/MFE for current position
    if(EnablePerformanceTracking && TrackMAE_MFE && CheckPointer(perfTracker) == POINTER_DYNAMIC)
    {
        if(PositionsTotal() > 0 && positionInfo.SelectByIndex(0))
        {
            if(positionInfo.Magic() == 0 || positionInfo.Symbol() == _Symbol)
            {
                double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                bool isBuy = (positionInfo.Type() == POSITION_TYPE_BUY);
                perfTracker.UpdateCurrentPosition(currentBid, currentAsk, isBuy);
            }
        }
    }
    
    // Manage positions with TradeExecutor
    if(CheckPointer(tradeExecutor) == POINTER_DYNAMIC && tradeExecutor.IsTracking())
    {
        double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double currentATR = (ArraySize(atrM5) > 0) ? atrM5[0] : 0.0;
        
        tradeExecutor.ManagePosition(currentBid, currentAsk, currentATR, M5_Timeframe, _Symbol);
    }
    
    // Manage open positions (legacy management for positions not tracked by TradeExecutor)
    ManageOpenPositions();
    
    // Update dashboard
    if(ShowDashboard)
        UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Update ATR buffers for all timeframes                            |
//+------------------------------------------------------------------+
bool UpdateATRBuffers()
{
    if(CopyBuffer(atrH4Handle, 0, 0, 3, atrH4) <= 0)
    {
        lastErrorMsg = "Failed to copy H4 ATR data";
        return false;
    }
    
    if(CopyBuffer(atrH1Handle, 0, 0, 3, atrH1) <= 0)
    {
        lastErrorMsg = "Failed to copy H1 ATR data";
        return false;
    }
    
    if(CopyBuffer(atrM5Handle, 0, 0, 3, atrM5) <= 0)
    {
        lastErrorMsg = "Failed to copy M5 ATR data";
        return false;
    }
    
    if(UseM1Precision && CopyBuffer(atrM1Handle, 0, 0, 3, atrM1) <= 0)
    {
        lastErrorMsg = "Failed to copy M1 ATR data";
        return false;
    }
    
    // Copy EMA buffers for trend confirmation
    if(CopyBuffer(ema20H4Handle, 0, 0, 3, ema20H4) <= 0)
    {
        lastErrorMsg = "Failed to copy EMA20 H4 data";
        return false;
    }
    
    if(CopyBuffer(ema50H4Handle, 0, 0, 3, ema50H4) <= 0)
    {
        lastErrorMsg = "Failed to copy EMA50 H4 data";
        return false;
    }
    
    lastErrorMsg = "";
    return true;
}

//+------------------------------------------------------------------+
//| Analyze H4 trend bias (swing structure and displacement)         |
//| UPDATED: Now supports STRICT and SIMPLE modes                     |
//+------------------------------------------------------------------+
void AnalyzeH4Trend()
{
    // Check if we have enough H4 bars
    if(Bars(_Symbol, H4_Timeframe) < SwingLookback + 5)
    {
        h4Trend = TREND_NEUTRAL;
        return;
    }
    
    double currentClose = iClose(_Symbol, H4_Timeframe, 0);
    
    // SIMPLE MODE: Just use EMA alignment (much less restrictive)
    if(H4TrendMode == TREND_SIMPLE)
    {
        // Bullish: price > EMA20 > EMA50
        if(currentClose > ema20H4[0] && ema20H4[0] > ema50H4[0])
        {
            h4Trend = TREND_BULLISH;
            return;
        }
        // Bearish: price < EMA20 < EMA50
        else if(currentClose < ema20H4[0] && ema20H4[0] < ema50H4[0])
        {
            h4Trend = TREND_BEARISH;
            return;
        }
        // Neutral: EMAs not aligned
        else
        {
            h4Trend = TREND_NEUTRAL;
            if(AllowWeakTrend)
            {
                // In weak trend mode, allow simple price vs EMA20
                if(currentClose > ema20H4[0])
                    h4Trend = TREND_BULLISH;
                else if(currentClose < ema20H4[0])
                    h4Trend = TREND_BEARISH;
            }
            return;
        }
    }
    
    // STRICT MODE: Original logic with swing structure + EMA alignment
    // Detect swing highs and lows on H4
    ArrayResize(h4Swings, 0);
    
    for(int i = 2; i < SwingLookback; i++)
    {
        double high = iHigh(_Symbol, H4_Timeframe, i);
        double low = iLow(_Symbol, H4_Timeframe, i);
        double highPrev = iHigh(_Symbol, H4_Timeframe, i+1);
        double lowPrev = iLow(_Symbol, H4_Timeframe, i+1);
        double highNext = iHigh(_Symbol, H4_Timeframe, i-1);
        double lowNext = iLow(_Symbol, H4_Timeframe, i-1);
        
        // Swing High detection
        if(high > highPrev && high > highNext)
        {
            SwingPoint swing;
            swing.time = iTime(_Symbol, H4_Timeframe, i);
            swing.price = high;
            swing.isHigh = true;
            
            int size = ArraySize(h4Swings);
            ArrayResize(h4Swings, size + 1);
            h4Swings[size] = swing;
        }
        
        // Swing Low detection
        if(low < lowPrev && low < lowNext)
        {
            SwingPoint swing;
            swing.time = iTime(_Symbol, H4_Timeframe, i);
            swing.price = low;
            swing.isHigh = false;
            
            int size = ArraySize(h4Swings);
            ArrayResize(h4Swings, size + 1);
            h4Swings[size] = swing;
        }
    }
    
    // Determine trend from swing structure
    if(ArraySize(h4Swings) >= 4)
    {
        // Check for higher highs and higher lows (bullish)
        bool higherHighs = true;
        bool higherLows = true;
        bool lowerHighs = true;
        bool lowerLows = true;
        
        for(int i = 0; i < ArraySize(h4Swings) - 1; i++)
        {
            if(h4Swings[i].isHigh && h4Swings[i+1].isHigh)
            {
                if(h4Swings[i].price <= h4Swings[i+1].price)
                    higherHighs = false;
                if(h4Swings[i].price >= h4Swings[i+1].price)
                    lowerHighs = false;
            }
            else if(!h4Swings[i].isHigh && !h4Swings[i+1].isHigh)
            {
                if(h4Swings[i].price <= h4Swings[i+1].price)
                    higherLows = false;
                if(h4Swings[i].price >= h4Swings[i+1].price)
                    lowerLows = false;
            }
        }
        
        if(higherHighs && higherLows)
            h4Trend = TREND_BULLISH;
        else if(lowerHighs && lowerLows)
            h4Trend = TREND_BEARISH;
        else
            h4Trend = TREND_NEUTRAL;
    }
    
    // Confirm trend with EMA alignment (strict mode only)
    // For bullish trend: price > EMA20 > EMA50
    if(h4Trend == TREND_BULLISH)
    {
        if(!(currentClose > ema20H4[0] && ema20H4[0] > ema50H4[0]))
        {
            if(AllowWeakTrend)
            {
                // Keep trend but note it's weak
                lastErrorMsg = "H4 bullish swing structure but EMA not perfectly aligned (weak trend allowed)";
            }
            else
            {
                h4Trend = TREND_NEUTRAL;
                lastErrorMsg = "H4 bullish swing structure but EMA not aligned";
            }
        }
    }
    // For bearish trend: price < EMA20 < EMA50
    else if(h4Trend == TREND_BEARISH)
    {
        if(!(currentClose < ema20H4[0] && ema20H4[0] < ema50H4[0]))
        {
            if(AllowWeakTrend)
            {
                // Keep trend but note it's weak
                lastErrorMsg = "H4 bearish swing structure but EMA not perfectly aligned (weak trend allowed)";
            }
            else
            {
                h4Trend = TREND_NEUTRAL;
                lastErrorMsg = "H4 bearish swing structure but EMA not aligned";
            }
        }
    }
    
    // Check for displacement (strong directional move)
    double displacement = MathAbs(iClose(_Symbol, H4_Timeframe, 0) - iClose(_Symbol, H4_Timeframe, 3));
    double minDisplacement = atrH4[0] * MinDisplacementPercent;
    
    if(displacement < minDisplacement)
    {
        // Not enough displacement, trend may be weak
        if(h4Trend != TREND_NEUTRAL && !AllowWeakTrend)
        {
            // In strict mode without weak trend allowance, this could invalidate trend
            lastErrorMsg = "H4 trend detected but weak displacement";
        }
    }
}

//+------------------------------------------------------------------+
//| Detect H1 support/resistance zones                               |
//+------------------------------------------------------------------+
void DetectH1Zones()
{
    ArrayResize(h1Zones, 0);
    
    if(Bars(_Symbol, H1_Timeframe) < 100)
        return;
    
    // Look for price levels with multiple touches
    double priceStep = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 100; // 10 pips for XAUUSD
    
    // Analyze last 100 H1 bars
    for(int i = 10; i < 100; i++)
    {
        double high = iHigh(_Symbol, H1_Timeframe, i);
        double low = iLow(_Symbol, H1_Timeframe, i);
        
        // Check for support zone (multiple lows near this level)
        int touchesSupport = 0;
        for(int j = 0; j < 100; j++)
        {
            double testLow = iLow(_Symbol, H1_Timeframe, j);
            if(MathAbs(testLow - low) < atrH1[0] * 0.3)
                touchesSupport++;
        }
        
        if(touchesSupport >= 3)
        {
            // Check if we already have a zone near this level
            bool exists = false;
            for(int z = 0; z < ArraySize(h1Zones); z++)
            {
                if(MathAbs(h1Zones[z].level - low) < atrH1[0] * 0.5)
                {
                    exists = true;
                    break;
                }
            }
            
            if(!exists)
            {
                SupportResistanceZone zone;
                zone.level = low;
                zone.touches = touchesSupport;
                zone.isSupport = true;
                zone.strength = touchesSupport / 3.0;
                
                int size = ArraySize(h1Zones);
                ArrayResize(h1Zones, size + 1);
                h1Zones[size] = zone;
            }
        }
        
        // Check for resistance zone
        int touchesResistance = 0;
        for(int j = 0; j < 100; j++)
        {
            double testHigh = iHigh(_Symbol, H1_Timeframe, j);
            if(MathAbs(testHigh - high) < atrH1[0] * 0.3)
                touchesResistance++;
        }
        
        if(touchesResistance >= 3)
        {
            bool exists = false;
            for(int z = 0; z < ArraySize(h1Zones); z++)
            {
                if(MathAbs(h1Zones[z].level - high) < atrH1[0] * 0.5)
                {
                    exists = true;
                    break;
                }
            }
            
            if(!exists)
            {
                SupportResistanceZone zone;
                zone.level = high;
                zone.touches = touchesResistance;
                zone.isSupport = false;
                zone.strength = touchesResistance / 3.0;
                
                int size = ArraySize(h1Zones);
                ArrayResize(h1Zones, size + 1);
                h1Zones[size] = zone;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Detect H1 Order Blocks                                           |
//+------------------------------------------------------------------+
void DetectH1OrderBlocks()
{
    // Clear old order blocks
    ArrayResize(h1OrderBlocks, 0);
    
    if(Bars(_Symbol, H1_Timeframe) < OrderBlockBars + 5)
        return;
    
    // Look for order blocks in recent bars with enhanced logic
    for(int i = 3; i < 20; i++)
    {
        double close3 = iClose(_Symbol, H1_Timeframe, i+2);
        double close2 = iClose(_Symbol, H1_Timeframe, i+1);
        double close1 = iClose(_Symbol, H1_Timeframe, i);
        double close0 = iClose(_Symbol, H1_Timeframe, i-1);
        
        double open1 = iOpen(_Symbol, H1_Timeframe, i);
        double high1 = iHigh(_Symbol, H1_Timeframe, i);
        double low1 = iLow(_Symbol, H1_Timeframe, i);
        
        // Bullish OB: Strong down move, then reversal candle, then sustained up
        bool bullishOB = (close2 < close3) &&              // Down move before
                         (close1 < open1) &&                // Bearish candle (last down)
                         (close0 > high1) &&                // Break above OB
                         (close0 - close1) > atrH1[0] * 0.8; // Strong move
        
        // Bearish OB: Strong up move, then reversal candle, then sustained down
        bool bearishOB = (close2 > close3) &&              // Up move before
                         (close1 > open1) &&                // Bullish candle (last up)
                         (close0 < low1) &&                 // Break below OB
                         (close1 - close0) > atrH1[0] * 0.8; // Strong move
        
        if(bullishOB)
        {
            OrderBlock ob;
            ob.time = iTime(_Symbol, H1_Timeframe, i);
            ob.high = high1;
            ob.low = low1;
            ob.isBullish = true;
            ob.isValid = true;
            
            // Check if OB hasn't been violated (price didn't go below low)
            bool violated = false;
            for(int j = i-1; j >= 0; j--)
            {
                if(iLow(_Symbol, H1_Timeframe, j) < low1)
                {
                    violated = true;
                    break;
                }
            }
            
            if(!violated)
            {
                int size = ArraySize(h1OrderBlocks);
                ArrayResize(h1OrderBlocks, size + 1);
                h1OrderBlocks[size] = ob;
            }
        }
        else if(bearishOB)
        {
            OrderBlock ob;
            ob.time = iTime(_Symbol, H1_Timeframe, i);
            ob.high = high1;
            ob.low = low1;
            ob.isBullish = false;
            ob.isValid = true;
            
            // Check if OB hasn't been violated (price didn't go above high)
            bool violated = false;
            for(int j = i-1; j >= 0; j--)
            {
                if(iHigh(_Symbol, H1_Timeframe, j) > high1)
                {
                    violated = true;
                    break;
                }
            }
            
            if(!violated)
            {
                int size = ArraySize(h1OrderBlocks);
                ArrayResize(h1OrderBlocks, size + 1);
                h1OrderBlocks[size] = ob;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Detect H1 Fair Value Gaps                                        |
//+------------------------------------------------------------------+
void DetectH1FairValueGaps()
{
    // Clear old FVGs
    ArrayResize(h1FVGs, 0);
    
    if(Bars(_Symbol, H1_Timeframe) < 10)
        return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Look for FVGs in recent bars
    for(int i = 2; i < 20; i++)
    {
        double high2 = iHigh(_Symbol, H1_Timeframe, i+1);
        double low2 = iLow(_Symbol, H1_Timeframe, i+1);
        double high1 = iHigh(_Symbol, H1_Timeframe, i);
        double low1 = iLow(_Symbol, H1_Timeframe, i);
        double high0 = iHigh(_Symbol, H1_Timeframe, i-1);
        double low0 = iLow(_Symbol, H1_Timeframe, i-1);
        
        // Bullish FVG: Gap between bar[i+1].high and bar[i-1].low
        double bullishGap = low0 - high2;
        if(bullishGap > FVG_MinGapPoints * point)
        {
            FairValueGap fvg;
            fvg.time = iTime(_Symbol, H1_Timeframe, i);
            fvg.upperBound = low0;
            fvg.lowerBound = high2;
            fvg.isBullish = true;
            fvg.isFilled = false;
            
            int size = ArraySize(h1FVGs);
            ArrayResize(h1FVGs, size + 1);
            h1FVGs[size] = fvg;
        }
        
        // Bearish FVG: Gap between bar[i+1].low and bar[i-1].high
        double bearishGap = low2 - high0;
        if(bearishGap > FVG_MinGapPoints * point)
        {
            FairValueGap fvg;
            fvg.time = iTime(_Symbol, H1_Timeframe, i);
            fvg.upperBound = low2;
            fvg.lowerBound = high0;
            fvg.isBullish = false;
            fvg.isFilled = false;
            
            int size = ArraySize(h1FVGs);
            ArrayResize(h1FVGs, size + 1);
            h1FVGs[size] = fvg;
        }
    }
}

//+------------------------------------------------------------------+
//| Log Strategy Decision - Helper function                          |
//+------------------------------------------------------------------+
void LogStrategyDecision(string strategyName, string reason, bool isPass, string details = "")
{
    // Only log if at least one logging flag is enabled
    if(!EnableDetailedLogging && !LogStrategyCriteria)
        return;
    
    string logPrefix = StringFormat("[%s] ", strategyName);
    string status = isPass ? "PASS" : "FAIL";
    
    if(details == "")
        Print(logPrefix, status, " - ", reason);
    else
        Print(logPrefix, status, " - ", reason, " | ", details);
}

//+------------------------------------------------------------------+
//| FVG Strategy Analysis                                             |
//| Returns: 1 (buy), -1 (sell), 0 (no signal)                       |
//+------------------------------------------------------------------+
int AnalyzeFVGStrategy()
{
    if(LogFVGStrategy)
        Print("========== FVG STRATEGY ANALYSIS START ==========");
    
    // Must have H4 trend alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        if(LogFVGStrategy)
            LogStrategyDecision("FVG", "H4 Trend is NEUTRAL", false, "Required: Bullish or Bearish trend");
        return 0;
    }
    
    if(LogFVGStrategy)
        LogStrategyDecision("FVG", "H4 Trend Check", true, h4Trend == TREND_BULLISH ? "BULLISH" : "BEARISH");
    
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    // Check for valid FVG entry
    int fvgCount = ArraySize(h1FVGs);
    
    if(fvgCount == 0)
    {
        if(LogFVGStrategy)
        {
            LogStrategyDecision("FVG", "FVG Detection", false, "No FVGs found on H1");
            Print("========== FVG STRATEGY: NO FVGs FOUND ==========");
        }
        return 0;
    }
    
    if(LogFVGStrategy)
        LogStrategyDecision("FVG", "FVG Detection", true, StringFormat("Found %d FVG(s)", fvgCount));
    
    for(int i = 0; i < fvgCount; i++)
    {
        if(!h1FVGs[i].isFilled)
        {
            // Check if price is within FVG
            bool withinFVG = (currentPrice >= h1FVGs[i].lowerBound && 
                             currentPrice <= h1FVGs[i].upperBound);
            
            if(LogFVGStrategy && withinFVG)
                LogStrategyDecision("FVG", StringFormat("FVG #%d Price Check", i), true, 
                                   StringFormat("Price %.2f in range [%.2f - %.2f]", 
                                               currentPrice, h1FVGs[i].lowerBound, h1FVGs[i].upperBound));
            
            if(withinFVG)
            {
                // Check FVG age if required
                if(FVG_RequireFresh)
                {
                    // Calculate bars since FVG creation
                    datetime currentTime = iTime(_Symbol, H1_Timeframe, 0);
                    int barsSinceFVG = (int)((currentTime - h1FVGs[i].time) / PeriodSeconds(H1_Timeframe));
                    
                    if(LogFVGStrategy)
                        LogStrategyDecision("FVG", "FVG Age Check", barsSinceFVG <= FVG_MaxAgeBars,
                                           StringFormat("Age: %d bars (Max: %d)", barsSinceFVG, FVG_MaxAgeBars));
                    
                    if(barsSinceFVG > FVG_MaxAgeBars)
                        continue;
                }
                else if(LogFVGStrategy)
                {
                    LogStrategyDecision("FVG", "FVG Age Check", true, "Fresh FVG check DISABLED");
                }
                
                // Check trend alignment
                bool isBullishSetup = h1FVGs[i].isBullish && (h4Trend == TREND_BULLISH);
                bool isBearishSetup = !h1FVGs[i].isBullish && (h4Trend == TREND_BEARISH);
                
                if(LogFVGStrategy)
                {
                    string fvgType = h1FVGs[i].isBullish ? "Bullish FVG" : "Bearish FVG";
                    string trendType = h4Trend == TREND_BULLISH ? "Bullish Trend" : "Bearish Trend";
                    LogStrategyDecision("FVG", "Trend Alignment", isBullishSetup || isBearishSetup,
                                       StringFormat("%s with %s", fvgType, trendType));
                }
                
                if(!isBullishSetup && !isBearishSetup)
                    continue;
                
                // Check rejection if required
                if(FVG_RequireRejection)
                {
                    bool hasRejection = DetectRejectionFromLevel();
                    if(LogFVGStrategy)
                        LogStrategyDecision("FVG", "Rejection Pattern", hasRejection,
                                           hasRejection ? "Rejection candle detected" : "No rejection candle");
                    if(!hasRejection)
                        continue;
                }
                else if(LogFVGStrategy)
                {
                    LogStrategyDecision("FVG", "Rejection Pattern", true, "Rejection check DISABLED");
                }
                
                // Check R:R ratio
                double potentialRR = CalculatePotentialRR(isBullishSetup);
                if(LogFVGStrategy)
                    LogStrategyDecision("FVG", "Risk/Reward Check", potentialRR >= FVG_MinRR,
                                       StringFormat("R:R %.2f (Min: %.2f)", potentialRR, FVG_MinRR));
                
                if(potentialRR < FVG_MinRR)
                    continue;
                
                // Valid FVG signal
                if(LogFVGStrategy)
                {
                    Print(StringFormat("========== FVG STRATEGY: %s SIGNAL CONFIRMED ==========", 
                                      isBullishSetup ? "BUY" : "SELL"));
                }
                return isBullishSetup ? 1 : -1;
            }
        }
    }
    
    if(LogFVGStrategy)
        Print("========== FVG STRATEGY: NO VALID SIGNAL ==========");
    
    return 0;
}

//+------------------------------------------------------------------+
//| BOS Strategy Analysis                                             |
//| Returns: 1 (buy), -1 (sell), 0 (no signal)                       |
//+------------------------------------------------------------------+
int AnalyzeBOSStrategy()
{
    if(LogBOSStrategy)
        Print("========== BOS STRATEGY ANALYSIS START ==========");
    
    // Must have H4 trend alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        if(LogBOSStrategy)
            LogStrategyDecision("BOS", "H4 Trend is NEUTRAL", false, "Required: Bullish or Bearish trend");
        return 0;
    }
    
    if(LogBOSStrategy)
        LogStrategyDecision("BOS", "H4 Trend Check", true, h4Trend == TREND_BULLISH ? "BULLISH" : "BEARISH");
    
    if(Bars(_Symbol, M5_Timeframe) < 10)
    {
        if(LogBOSStrategy)
            LogStrategyDecision("BOS", "Insufficient Bars", false, StringFormat("Need 10 bars, have %d", Bars(_Symbol, M5_Timeframe)));
        return 0;
    }
    
    // Get recent swing points on M5 - initialize with first values
    double swingHigh = iHigh(_Symbol, M5_Timeframe, 2);
    double swingLow = iLow(_Symbol, M5_Timeframe, 2);
    
    for(int i = 3; i < SwingLookback; i++)
    {
        double high = iHigh(_Symbol, M5_Timeframe, i);
        double low = iLow(_Symbol, M5_Timeframe, i);
        
        if(high > swingHigh)
            swingHigh = high;
        if(low < swingLow)
            swingLow = low;
    }
    
    double currentClose = iClose(_Symbol, M5_Timeframe, 0);
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    // Check for BOS in trend direction
    bool bullishBOS = (currentClose > swingHigh) && (h4Trend == TREND_BULLISH);
    bool bearishBOS = (currentClose < swingLow) && (h4Trend == TREND_BEARISH);
    
    if(LogBOSStrategy)
    {
        LogStrategyDecision("BOS", "Break of Structure Check", bullishBOS || bearishBOS,
                           StringFormat("Swing High: %.2f, Swing Low: %.2f, Current: %.2f", 
                                       swingHigh, swingLow, currentClose));
    }
    
    if(!bullishBOS && !bearishBOS)
    {
        if(LogBOSStrategy)
            Print("========== BOS STRATEGY: NO BOS DETECTED ==========");
        return 0;
    }
    
    // Check volume expansion if required
    if(BOS_RequireVolumeExpansion)
    {
        bool hasVolumeExpansion = CheckVolumeExpansion(BOS_VolumeMultiplier);
        if(LogBOSStrategy)
            LogStrategyDecision("BOS", "Volume Expansion", hasVolumeExpansion,
                               StringFormat("Required multiplier: %.1fx", BOS_VolumeMultiplier));
        if(!hasVolumeExpansion)
            return 0;
    }
    else if(LogBOSStrategy)
    {
        LogStrategyDecision("BOS", "Volume Expansion", true, "Volume check DISABLED");
    }
    
    // Check proximity to H1 zone if required
    if(BOS_RequireProximityToZone)
    {
        bool nearZone = false;
        for(int i = 0; i < ArraySize(h1Zones); i++)
        {
            double distance = MathAbs(currentPrice - h1Zones[i].level);
            if(distance < atrH1[0] * ATR_ZoneMultiplier)
            {
                nearZone = true;
                if(LogBOSStrategy)
                    LogStrategyDecision("BOS", "H1 Zone Proximity", true,
                                       StringFormat("Distance to zone: %.2f (Max: %.2f)", 
                                                   distance, atrH1[0] * ATR_ZoneMultiplier));
                break;
            }
        }
        if(!nearZone)
        {
            if(LogBOSStrategy)
                LogStrategyDecision("BOS", "H1 Zone Proximity", false, "No zone within range");
            return 0;
        }
    }
    else if(LogBOSStrategy)
    {
        LogStrategyDecision("BOS", "H1 Zone Proximity", true, "Zone proximity check DISABLED");
    }
    
    // Check R:R ratio
    double potentialRR = CalculatePotentialRR(bullishBOS);
    if(LogBOSStrategy)
        LogStrategyDecision("BOS", "Risk/Reward Check", potentialRR >= BOS_MinRR,
                           StringFormat("R:R %.2f (Min: %.2f)", potentialRR, BOS_MinRR));
    
    if(potentialRR < BOS_MinRR)
        return 0;
    
    // Valid BOS signal
    if(LogBOSStrategy)
    {
        Print(StringFormat("========== BOS STRATEGY: %s SIGNAL CONFIRMED ==========", 
                          bullishBOS ? "BUY" : "SELL"));
    }
    return bullishBOS ? 1 : -1;
}

//+------------------------------------------------------------------+
//| HTF Zone Strategy Analysis                                        |
//| Returns: 1 (buy), -1 (sell), 0 (no signal)                       |
//+------------------------------------------------------------------+
int AnalyzeHTFZoneStrategy()
{
    if(LogHTFZoneStrategy)
        Print("========== HTF ZONE STRATEGY ANALYSIS START ==========");
    
    // Must have H4 trend alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        if(LogHTFZoneStrategy)
            LogStrategyDecision("HTF Zone", "H4 Trend is NEUTRAL", false, "Required: Bullish or Bearish trend");
        return 0;
    }
    
    if(LogHTFZoneStrategy)
        LogStrategyDecision("HTF Zone", "H4 Trend Check", true, h4Trend == TREND_BULLISH ? "BULLISH" : "BEARISH");
    
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    int zoneCount = ArraySize(h1Zones);
    
    if(zoneCount == 0)
    {
        if(LogHTFZoneStrategy)
        {
            LogStrategyDecision("HTF Zone", "Zone Detection", false, "No H1 zones found");
            Print("========== HTF ZONE STRATEGY: NO ZONES FOUND ==========");
        }
        return 0;
    }
    
    if(LogHTFZoneStrategy)
        LogStrategyDecision("HTF Zone", "Zone Detection", true, StringFormat("Found %d zone(s)", zoneCount));
    
    // Check for valid H1 zone
    for(int i = 0; i < zoneCount; i++)
    {
        double distanceToZone = MathAbs(currentPrice - h1Zones[i].level);
        double maxDistance = atrH1[0] * ATR_ZoneMultiplier;
        
        // Check if price is at zone
        if(distanceToZone < maxDistance)
        {
            if(LogHTFZoneStrategy)
                LogStrategyDecision("HTF Zone", StringFormat("Zone #%d Distance", i), true,
                                   StringFormat("Distance: %.2f (Max: %.2f)", distanceToZone, maxDistance));
            
            // Check minimum touches
            if(h1Zones[i].touches < HTFZone_MinTouches)
            {
                if(LogHTFZoneStrategy)
                    LogStrategyDecision("HTF Zone", "Minimum Touches", false,
                                       StringFormat("Touches: %d (Min: %d)", h1Zones[i].touches, HTFZone_MinTouches));
                continue;
            }
            
            if(LogHTFZoneStrategy)
                LogStrategyDecision("HTF Zone", "Minimum Touches", true,
                                   StringFormat("Touches: %d", h1Zones[i].touches));
            
            // Check zone strength
            if(h1Zones[i].strength < HTFZone_MinStrength)
            {
                if(LogHTFZoneStrategy)
                    LogStrategyDecision("HTF Zone", "Zone Strength", false,
                                       StringFormat("Strength: %.2f (Min: %.2f)", h1Zones[i].strength, HTFZone_MinStrength));
                continue;
            }
            
            if(LogHTFZoneStrategy)
                LogStrategyDecision("HTF Zone", "Zone Strength", true,
                                   StringFormat("Strength: %.2f", h1Zones[i].strength));
            
            // Check trend alignment
            bool isBullishSetup = h1Zones[i].isSupport && (h4Trend == TREND_BULLISH);
            bool isBearishSetup = !h1Zones[i].isSupport && (h4Trend == TREND_BEARISH);
            
            if(LogHTFZoneStrategy)
            {
                string zoneType = h1Zones[i].isSupport ? "Support" : "Resistance";
                string trendType = h4Trend == TREND_BULLISH ? "Bullish" : "Bearish";
                LogStrategyDecision("HTF Zone", "Trend Alignment", isBullishSetup || isBearishSetup,
                                   StringFormat("%s zone with %s trend", zoneType, trendType));
            }
            
            if(!isBullishSetup && !isBearishSetup)
                continue;
            
            // Check rejection if required
            if(HTFZone_RequireRejection)
            {
                bool hasRejection = DetectRejectionFromLevel();
                if(LogHTFZoneStrategy)
                    LogStrategyDecision("HTF Zone", "Rejection Pattern", hasRejection,
                                       hasRejection ? "Rejection candle detected" : "No rejection candle");
                if(!hasRejection)
                    continue;
            }
            else if(LogHTFZoneStrategy)
            {
                LogStrategyDecision("HTF Zone", "Rejection Pattern", true, "Rejection check DISABLED");
            }
            
            // Check R:R ratio
            double potentialRR = CalculatePotentialRR(isBullishSetup);
            if(LogHTFZoneStrategy)
                LogStrategyDecision("HTF Zone", "Risk/Reward Check", potentialRR >= HTFZone_MinRR,
                                   StringFormat("R:R %.2f (Min: %.2f)", potentialRR, HTFZone_MinRR));
            
            if(potentialRR < HTFZone_MinRR)
                continue;
            
            // Valid zone signal
            if(LogHTFZoneStrategy)
            {
                Print(StringFormat("========== HTF ZONE STRATEGY: %s SIGNAL CONFIRMED ==========", 
                                  isBullishSetup ? "BUY" : "SELL"));
            }
            return isBullishSetup ? 1 : -1;
        }
    }
    
    if(LogHTFZoneStrategy)
        Print("========== HTF ZONE STRATEGY: NO VALID SIGNAL ==========");
    
    return 0;
}

//+------------------------------------------------------------------+
//| Order Block Strategy Analysis                                     |
//| Returns: 1 (buy), -1 (sell), 0 (no signal)                       |
//+------------------------------------------------------------------+
int AnalyzeOrderBlockStrategy()
{
    if(LogOBStrategy)
        Print("========== ORDER BLOCK STRATEGY ANALYSIS START ==========");
    
    // Must have H4 trend alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        if(LogOBStrategy)
            LogStrategyDecision("OB", "H4 Trend is NEUTRAL", false, "Required: Bullish or Bearish trend");
        return 0;
    }
    
    if(LogOBStrategy)
        LogStrategyDecision("OB", "H4 Trend Check", true, h4Trend == TREND_BULLISH ? "BULLISH" : "BEARISH");
    
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    int obCount = ArraySize(h1OrderBlocks);
    
    if(obCount == 0)
    {
        if(LogOBStrategy)
        {
            LogStrategyDecision("OB", "Order Block Detection", false, "No order blocks found on H1");
            Print("========== ORDER BLOCK STRATEGY: NO ORDER BLOCKS FOUND ==========");
        }
        return 0;
    }
    
    if(LogOBStrategy)
        LogStrategyDecision("OB", "Order Block Detection", true, StringFormat("Found %d order block(s)", obCount));
    
    // Check for valid order block
    for(int i = 0; i < obCount; i++)
    {
        // Check if OB is valid and not violated (if required)
        if(OB_OnlyUntested && !h1OrderBlocks[i].isValid)
        {
            if(LogOBStrategy)
                LogStrategyDecision("OB", StringFormat("OB #%d Validity", i), false, "Block has been violated");
            continue;
        }
        
        // Check if price is within order block
        bool withinOB = (currentPrice >= h1OrderBlocks[i].low && 
                        currentPrice <= h1OrderBlocks[i].high);
        
        if(LogOBStrategy && withinOB)
            LogStrategyDecision("OB", StringFormat("OB #%d Price Check", i), true,
                               StringFormat("Price %.2f in range [%.2f - %.2f]", 
                                           currentPrice, h1OrderBlocks[i].low, h1OrderBlocks[i].high));
        
        if(withinOB)
        {
            // Check trend alignment
            bool isBullishSetup = h1OrderBlocks[i].isBullish && (h4Trend == TREND_BULLISH);
            bool isBearishSetup = !h1OrderBlocks[i].isBullish && (h4Trend == TREND_BEARISH);
            
            if(LogOBStrategy)
            {
                string obType = h1OrderBlocks[i].isBullish ? "Bullish OB" : "Bearish OB";
                string trendType = h4Trend == TREND_BULLISH ? "Bullish Trend" : "Bearish Trend";
                LogStrategyDecision("OB", "Trend Alignment", isBullishSetup || isBearishSetup,
                                   StringFormat("%s with %s", obType, trendType));
            }
            
            if(!isBullishSetup && !isBearishSetup)
                continue;
            
            // Check for FVG within OB if required
            if(OB_RequireFVG)
            {
                bool hasFVG = false;
                for(int j = 0; j < ArraySize(h1FVGs); j++)
                {
                    if(!h1FVGs[j].isFilled)
                    {
                        // Check if FVG overlaps with OB
                        if((h1FVGs[j].lowerBound >= h1OrderBlocks[i].low && 
                            h1FVGs[j].lowerBound <= h1OrderBlocks[i].high) ||
                           (h1FVGs[j].upperBound >= h1OrderBlocks[i].low && 
                            h1FVGs[j].upperBound <= h1OrderBlocks[i].high))
                        {
                            hasFVG = true;
                            if(LogOBStrategy)
                                LogStrategyDecision("OB", "FVG Within OB", true, "FVG overlaps with Order Block");
                            break;
                        }
                    }
                }
                
                if(!hasFVG)
                {
                    if(LogOBStrategy)
                        LogStrategyDecision("OB", "FVG Within OB", false, "No FVG found within Order Block");
                    continue;
                }
            }
            else if(LogOBStrategy)
            {
                LogStrategyDecision("OB", "FVG Within OB", true, "FVG check DISABLED");
            }
            
            // Check R:R ratio
            double potentialRR = CalculatePotentialRR(isBullishSetup);
            if(LogOBStrategy)
                LogStrategyDecision("OB", "Risk/Reward Check", potentialRR >= OB_MinRR,
                                   StringFormat("R:R %.2f (Min: %.2f)", potentialRR, OB_MinRR));
            
            if(potentialRR < OB_MinRR)
                continue;
            
            // Valid order block signal
            if(LogOBStrategy)
            {
                Print(StringFormat("========== ORDER BLOCK STRATEGY: %s SIGNAL CONFIRMED ==========", 
                                  isBullishSetup ? "BUY" : "SELL"));
            }
            return isBullishSetup ? 1 : -1;
        }
    }
    
    if(LogOBStrategy)
        Print("========== ORDER BLOCK STRATEGY: NO VALID SIGNAL ==========");
    
    return 0;
}

//+------------------------------------------------------------------+
//| Breakout Strategy Analysis (Asian Range)                          |
//| Returns: 1 (buy), -1 (sell), 0 (no signal)                       |
//+------------------------------------------------------------------+
int AnalyzeBreakoutStrategy()
{
    if(LogBreakoutStrategy)
        Print("========== BREAKOUT STRATEGY ANALYSIS START ==========");
    
    // Must have H4 trend alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        if(LogBreakoutStrategy)
            LogStrategyDecision("Breakout", "H4 Trend is NEUTRAL", false, "Required: Bullish or Bearish trend");
        return 0;
    }
    
    if(LogBreakoutStrategy)
        LogStrategyDecision("Breakout", "H4 Trend Check", true, h4Trend == TREND_BULLISH ? "BULLISH" : "BEARISH");
    
    // Must have valid Asian levels
    if(!UseAsianHighLow || !asianLevels.isValid)
    {
        if(LogBreakoutStrategy)
            LogStrategyDecision("Breakout", "Asian Levels", false, 
                               UseAsianHighLow ? "Asian levels not valid" : "Asian levels tracking DISABLED");
        return 0;
    }
    
    if(LogBreakoutStrategy)
        LogStrategyDecision("Breakout", "Asian Levels", true,
                           StringFormat("High: %.2f, Low: %.2f", asianLevels.high, asianLevels.low));
    
    // Must be in London or NY session
    bool validSession = (currentSession == SESSION_LONDON || currentSession == SESSION_NEWYORK);
    if(LogBreakoutStrategy)
    {
        string sessionName = currentSession == SESSION_LONDON ? "LONDON" : 
                            currentSession == SESSION_NEWYORK ? "NEW YORK" : 
                            currentSession == SESSION_ASIAN ? "ASIAN" : "CLOSED";
        LogStrategyDecision("Breakout", "Session Check", validSession,
                           StringFormat("Current: %s (Need: London or NY)", sessionName));
    }
    
    if(!validSession)
        return 0;
    
    double currentClose = iClose(_Symbol, M5_Timeframe, 0);
    
    // Check for breakout of Asian range
    bool bullishBreakout = (currentClose > asianLevels.high) && (h4Trend == TREND_BULLISH);
    bool bearishBreakout = (currentClose < asianLevels.low) && (h4Trend == TREND_BEARISH);
    
    if(LogBreakoutStrategy)
    {
        LogStrategyDecision("Breakout", "Range Breakout", bullishBreakout || bearishBreakout,
                           StringFormat("Close: %.2f, Asian High: %.2f, Asian Low: %.2f", 
                                       currentClose, asianLevels.high, asianLevels.low));
    }
    
    if(!bullishBreakout && !bearishBreakout)
    {
        if(LogBreakoutStrategy)
            Print("========== BREAKOUT STRATEGY: NO BREAKOUT DETECTED ==========");
        return 0;
    }
    
    // Check volume expansion if required
    if(Breakout_RequireVolumeExpansion)
    {
        bool hasVolumeExpansion = CheckVolumeExpansion(Breakout_VolumeMultiplier);
        if(LogBreakoutStrategy)
            LogStrategyDecision("Breakout", "Volume Expansion", hasVolumeExpansion,
                               StringFormat("Required multiplier: %.1fx", Breakout_VolumeMultiplier));
        if(!hasVolumeExpansion)
            return 0;
    }
    else if(LogBreakoutStrategy)
    {
        LogStrategyDecision("Breakout", "Volume Expansion", true, "Volume check DISABLED");
    }
    
    // Check ATR expansion if required
    if(Breakout_RequireATRExpansion)
    {
        // Copy ATR values for current and historical comparison
        double atrValues[];
        ArraySetAsSeries(atrValues, true);
        int atrBarsNeeded = Breakout_ATRAveragePeriod + 1;
        
        if(CopyBuffer(atrM5Handle, 0, 0, atrBarsNeeded, atrValues) != atrBarsNeeded)
        {
            if(LogBreakoutStrategy)
                LogStrategyDecision("Breakout", "ATR Expansion", false, "Failed to copy ATR data");
            return 0;
        }
        
        // Calculate average ATR from recent bars (excluding current)
        double avgATR = 0;
        for(int i = 1; i < atrBarsNeeded; i++)
        {
            avgATR += atrValues[i];
        }
        avgATR /= Breakout_ATRAveragePeriod;
        
        double requiredATR = avgATR * Breakout_ATRMultiplier;
        bool hasATRExpansion = (atrValues[0] >= requiredATR);
        
        if(LogBreakoutStrategy)
            LogStrategyDecision("Breakout", "ATR Expansion", hasATRExpansion,
                               StringFormat("Current ATR: %.2f, Required: %.2f (Avg: %.2f x %.1f)", 
                                           atrValues[0], requiredATR, avgATR, Breakout_ATRMultiplier));
        
        // Current ATR must be greater than avg ATR * multiplier
        if(!hasATRExpansion)
            return 0;
    }
    else if(LogBreakoutStrategy)
    {
        LogStrategyDecision("Breakout", "ATR Expansion", true, "ATR check DISABLED");
    }
    
    // Check R:R ratio
    double potentialRR = CalculatePotentialRR(bullishBreakout);
    if(LogBreakoutStrategy)
        LogStrategyDecision("Breakout", "Risk/Reward Check", potentialRR >= Breakout_MinRR,
                           StringFormat("R:R %.2f (Min: %.2f)", potentialRR, Breakout_MinRR));
    
    if(potentialRR < Breakout_MinRR)
        return 0;
    
    // Valid breakout signal
    if(LogBreakoutStrategy)
    {
        Print(StringFormat("========== BREAKOUT STRATEGY: %s SIGNAL CONFIRMED ==========", 
                          bullishBreakout ? "BUY" : "SELL"));
    }
    return bullishBreakout ? 1 : -1;
}

//+------------------------------------------------------------------+
//| Analyze entry opportunity with 11-point validation                |
//+------------------------------------------------------------------+
int AnalyzeEntryOpportunity()
{
    // Reset validation
    ZeroMemory(currentValidation);
    currentValidation.totalPoints = 0;
    currentValidation.weightedScore = 0.0;
    
    // Early filter: Daily loss limit circuit breaker (extra safety check)
    if(!CheckDailyLossLimit())
    {
        lastErrorMsg = "Daily loss limit reached - trading suspended";
        return 0;
    }
    
    // Early filter: Spread check
    if(UseSpreadFilter)
    {
        double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        double spreadPoints = spread / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        if(spreadPoints > MaxSpreadPoints)
        {
            lastErrorMsg = StringFormat("Spread too high: %.1f points (max: %.1f)", spreadPoints, MaxSpreadPoints);
            return 0;
        }
    }
    
    // Early filter: Time-of-day filter
    if(UseTimeOfDayFilter)
    {
        MqlDateTime dt;
        TimeToStruct(TimeGMT() + SessionGMTOffset * 3600, dt);
        int currentHour = dt.hour;
        
        // Check if we're in the avoid trading hours
        if(AvoidTradingHourEnd < AvoidTradingHourStart)
        {
            // Wrapped range spanning midnight (e.g., 22-1 means 22:00 to 01:00 next day)
            if(currentHour >= AvoidTradingHourStart || currentHour <= AvoidTradingHourEnd)
            {
                lastErrorMsg = StringFormat("Time-of-day filter: avoiding trading at %02d:00 GMT", currentHour);
                return 0;
            }
        }
        else
        {
            // Standard same-day range (e.g., 8-17 means 08:00 to 17:00 same day)
            if(currentHour >= AvoidTradingHourStart && currentHour <= AvoidTradingHourEnd)
            {
                lastErrorMsg = StringFormat("Time-of-day filter: avoiding trading at %02d:00 GMT", currentHour);
                return 0;
            }
        }
    }
    
    // Early filter: Check volatility conditions
    if(!IsVolatilityAcceptable())
    {
        lastErrorMsg = "Volatility outside acceptable range";
        return 0;
    }
    
    // Early filter: Check market structure
    if(!IsMarketStructureClean())
    {
        // lastErrorMsg already set in IsMarketStructureClean
        return 0;
    }
    
    // NEW: Independent Strategies System
    if(UseIndependentStrategies)
    {
        if(EnableDetailedLogging)
            Print("========== INDEPENDENT STRATEGIES MODE ACTIVE ==========");
        
        // Check if any enabled strategy produces a signal
        int signal = 0;
        
        // Check each enabled strategy
        if(Enable_FVG_Strategy || EnableAllStrategies)
        {
            if(EnableDetailedLogging)
                Print(">>> Checking FVG Strategy...");
            signal = AnalyzeFVGStrategy();
            if(signal != 0)
            {
                if(EnableDetailedLogging)
                    Print(StringFormat("*** FVG STRATEGY TRIGGERED %s SIGNAL ***", signal > 0 ? "BUY" : "SELL"));
                return signal;
            }
        }
        
        if(Enable_BOS_Strategy || EnableAllStrategies)
        {
            if(EnableDetailedLogging)
                Print(">>> Checking BOS Strategy...");
            signal = AnalyzeBOSStrategy();
            if(signal != 0)
            {
                if(EnableDetailedLogging)
                    Print(StringFormat("*** BOS STRATEGY TRIGGERED %s SIGNAL ***", signal > 0 ? "BUY" : "SELL"));
                return signal;
            }
        }
        
        if(Enable_HTFZone_Strategy || EnableAllStrategies)
        {
            if(EnableDetailedLogging)
                Print(">>> Checking HTF Zone Strategy...");
            signal = AnalyzeHTFZoneStrategy();
            if(signal != 0)
            {
                if(EnableDetailedLogging)
                    Print(StringFormat("*** HTF ZONE STRATEGY TRIGGERED %s SIGNAL ***", signal > 0 ? "BUY" : "SELL"));
                return signal;
            }
        }
        
        if(Enable_OB_Strategy || EnableAllStrategies)
        {
            if(EnableDetailedLogging)
                Print(">>> Checking Order Block Strategy...");
            signal = AnalyzeOrderBlockStrategy();
            if(signal != 0)
            {
                if(EnableDetailedLogging)
                    Print(StringFormat("*** ORDER BLOCK STRATEGY TRIGGERED %s SIGNAL ***", signal > 0 ? "BUY" : "SELL"));
                return signal;
            }
        }
        
        if(Enable_Breakout_Strategy || EnableAllStrategies)
        {
            if(EnableDetailedLogging)
                Print(">>> Checking Breakout Strategy...");
            signal = AnalyzeBreakoutStrategy();
            if(signal != 0)
            {
                if(EnableDetailedLogging)
                    Print(StringFormat("*** BREAKOUT STRATEGY TRIGGERED %s SIGNAL ***", signal > 0 ? "BUY" : "SELL"));
                return signal;
            }
        }
        
        // No independent strategy triggered
        if(EnableDetailedLogging)
            Print("========== NO STRATEGY SIGNAL FOUND ==========");
        lastErrorMsg = "Independent strategies: No valid signal from enabled strategies";
        return 0;
    }
    
    // LEGACY: 11-Point Validation System (original logic below)
    
    // 1. H4 Trend Alignment
    if(h4Trend == TREND_BULLISH || h4Trend == TREND_BEARISH)
    {
        currentValidation.h4TrendValid = true;
        currentValidation.totalPoints++;
        if(UseWeightedScoring)
            currentValidation.weightedScore += H4TrendWeight;
        else
            currentValidation.weightedScore += 1.0;
    }
    
    // 2. H1 Zone Present
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    for(int i = 0; i < ArraySize(h1Zones); i++)
    {
        if(MathAbs(currentPrice - h1Zones[i].level) < atrH1[0] * ATR_ZoneMultiplier)
        {
            currentValidation.h1ZoneValid = true;
            currentValidation.totalPoints++;
            currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
            break;
        }
    }
    
    // 3. Break of Structure (BOS) on M5
    currentValidation.bosDetected = DetectBreakOfStructure();
    if(currentValidation.bosDetected)
    {
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
    }
    
    // 4. Liquidity Sweep (Optional)
    currentValidation.liquiditySweep = DetectLiquiditySweep();
    if(currentValidation.liquiditySweep)
    {
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
    }
    
    // 5. Fair Value Gap Present (Optional)
    for(int i = 0; i < ArraySize(h1FVGs); i++)
    {
        if(!h1FVGs[i].isFilled)
        {
            if(currentPrice >= h1FVGs[i].lowerBound && 
               currentPrice <= h1FVGs[i].upperBound)
            {
                currentValidation.fvgPresent = true;
                currentValidation.totalPoints++;
                currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
                break;
            }
        }
    }
    
    // 6. Order Block Confirmation
    for(int i = 0; i < ArraySize(h1OrderBlocks); i++)
    {
        if(h1OrderBlocks[i].isValid)
        {
            if(currentPrice >= h1OrderBlocks[i].low && 
               currentPrice <= h1OrderBlocks[i].high)
            {
                currentValidation.orderBlockValid = true;
                currentValidation.totalPoints++;
                currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
                break;
            }
        }
    }
    
    // 7. ATR Zone Validation
    currentValidation.atrZoneValid = ValidateATRZone();
    if(currentValidation.atrZoneValid)
    {
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
    }
    
    // 8. Breakout Detection
    currentValidation.breakoutDetected = DetectBreakout();
    if(currentValidation.breakoutDetected)
    {
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
    }
    
    // 9. Asian Level Validation
    if(UseAsianHighLow && asianLevels.isValid)
    {
        double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
        
        // Check if price is near Asian high/low
        double distanceToHigh = MathAbs(currentPrice - asianLevels.high);
        double distanceToLow = MathAbs(currentPrice - asianLevels.low);
        
        if(distanceToHigh < atrM5[0] * AsianLevelDistanceMultiplier || 
           distanceToLow < atrM5[0] * AsianLevelDistanceMultiplier)
        {
            currentValidation.asianLevelValid = true;
            currentValidation.totalPoints++;
            currentValidation.weightedScore += (UseWeightedScoring ? ZoneWeight : 1.0);
        }
    }
    
    // 10. Valid Risk/Reward - Calculate actual potential R:R
    bool isBuySignal = (h4Trend == TREND_BULLISH);
    double potentialRR = CalculatePotentialRR(isBuySignal);
    if(potentialRR >= MinRiskRewardRatio)
    {
        currentValidation.validRiskReward = true;
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? RiskRewardWeight : 1.0);
    }
    
    // 11. Session Filter
    currentValidation.sessionActive = IsWithinTradingSession();
    if(currentValidation.sessionActive)
    {
        currentValidation.totalPoints++;
        currentValidation.weightedScore += (UseWeightedScoring ? SessionWeight : 1.0);
    }
    
    // Track validation failures for diagnostics
    if(EnableDetailedLogging)
    {
        if(!currentValidation.h4TrendValid) validationFailCount[0]++;
        if(!currentValidation.h1ZoneValid) validationFailCount[1]++;
        if(!currentValidation.bosDetected) validationFailCount[2]++;
        if(!currentValidation.liquiditySweep) validationFailCount[3]++;
        if(!currentValidation.fvgPresent) validationFailCount[4]++;
        if(!currentValidation.orderBlockValid) validationFailCount[5]++;
        if(!currentValidation.atrZoneValid) validationFailCount[6]++;
        if(!currentValidation.breakoutDetected) validationFailCount[7]++;
        if(!currentValidation.asianLevelValid) validationFailCount[8]++;
        if(!currentValidation.validRiskReward) validationFailCount[9]++;
        if(!currentValidation.sessionActive) validationFailCount[10]++;
    }
    
    // Apply strategy-specific validation (only if not UNIVERSAL)
    if(EntryStrategy == STRATEGY_BREAKOUT)
    {
        // Breakout strategy: MUST have breakout, skip zone proximity requirement
        if(!currentValidation.breakoutDetected)
        {
            lastErrorMsg = "Breakout strategy requires breakout detection";
            return 0;
        }
        // Optional: Check volume expansion for confirmation
        if(LondonNYBreakout && !SessionSpecificRulesOptional)
        {
            if(!CheckVolumeExpansion())
            {
                lastErrorMsg = "Breakout strategy prefers volume expansion";
                // Don't return 0, just note it
            }
        }
    }
    else if(EntryStrategy == STRATEGY_REVERSAL)
    {
        // Reversal strategy: MUST have zone/OB + rejection, skip breakout
        if(!currentValidation.h1ZoneValid && !currentValidation.orderBlockValid)
        {
            lastErrorMsg = "Reversal strategy requires zone or order block";
            return 0;
        }
        // Check for rejection pattern
        if(!DetectRejectionFromLevel())
        {
            lastErrorMsg = "Reversal strategy prefers rejection from level";
            // Don't return 0 if session rules are optional
            if(!SessionSpecificRulesOptional)
                return 0;
        }
    }
    else if(EntryStrategy == STRATEGY_CONTINUATION)
    {
        // Continuation strategy: MUST have trend + pullback (BOS or zone)
        if(!currentValidation.h4TrendValid)
        {
            lastErrorMsg = "Continuation strategy requires clear H4 trend";
            return 0;
        }
        if(!currentValidation.bosDetected && !currentValidation.h1ZoneValid)
        {
            lastErrorMsg = "Continuation strategy requires pullback (BOS or zone)";
            return 0;
        }
    }
    // UNIVERSAL strategy: No specific requirements, use point-based system only
    
    // Apply session-specific strategies (only if NOT optional)
    if(!SessionSpecificRulesOptional)
    {
        if(AsianRangeBound && currentSession == SESSION_ASIAN)
        {
            // In Asian session, favor range-bound setups, avoid breakouts
            if(currentValidation.breakoutDetected)
            {
                lastErrorMsg = "Asian session avoiding breakout (session rules active)";
                return 0; // Skip breakout trades during Asian session
            }
            
            // Only trade reversals from Asian high/low
            if(!currentValidation.asianLevelValid)
            {
                lastErrorMsg = "Asian session requires valid Asian level proximity (session rules active)";
                return 0;
            }
            
            // Must show rejection (wick) from level
            if(!DetectRejectionFromLevel())
            {
                lastErrorMsg = "Asian session requires rejection from level (session rules active)";
                return 0;
            }
        }
        
        if(LondonNYBreakout && (currentSession == SESSION_LONDON || currentSession == SESSION_NEWYORK))
        {
            // In London/NY sessions, favor breakout patterns
            // Require strong breakout confirmation
            if(!currentValidation.breakoutDetected)
            {
                lastErrorMsg = "London/NY session requires breakout confirmation (session rules active)";
                return 0;
            }
            
            // Must have volume expansion (use tick volume)
            if(!CheckVolumeExpansion())
            {
                lastErrorMsg = "London/NY session requires volume expansion (session rules active)";
                return 0;
            }
        }
    }
    
    // Track near-misses (setups close to minimum)
    if(TrackNearMisses && currentValidation.totalPoints >= (MinValidationPoints - 2) && 
       currentValidation.totalPoints < MinValidationPoints)
    {
        nearMissCount++;
        if(EnableDetailedLogging)
        {
            Print(StringFormat("NEAR MISS: %d/%d points. H4Trend:%s Zone:%s BOS:%s RR:%s Session:%s",
                  currentValidation.totalPoints, MinValidationPoints,
                  currentValidation.h4TrendValid ? "✓" : "✗",
                  currentValidation.h1ZoneValid ? "✓" : "✗",
                  currentValidation.bosDetected ? "✓" : "✗",
                  currentValidation.validRiskReward ? "✓" : "✗",
                  currentValidation.sessionActive ? "✓" : "✗"));
        }
    }
    
    // Check if minimum validation points met
    if(currentValidation.totalPoints < MinValidationPoints)
    {
        if(EnableDetailedLogging)
            lastErrorMsg = StringFormat("Validation points %d < minimum %d", currentValidation.totalPoints, MinValidationPoints);
        return 0; // No signal
    }
    
    // Essential-only mode: Skip individual requirement checks
    if(UseEssentialOnly)
    {
        // Only check essential requirements
        if(!currentValidation.h4TrendValid)
        {
            lastErrorMsg = "Essential mode: H4 trend required";
            return 0;
        }
        if(!currentValidation.sessionActive)
        {
            lastErrorMsg = "Essential mode: Active session required";
            return 0;
        }
        if(!currentValidation.validRiskReward)
        {
            lastErrorMsg = "Essential mode: Valid R:R required";
            return 0;
        }
        // If essentials are met, proceed
    }
    else
    {
        // Check required validations (only if their inputs are true)
        if(Require_H4_Trend && !currentValidation.h4TrendValid)
            return 0;
        if(Require_H1_Zone && !currentValidation.h1ZoneValid)
            return 0;
        if(Require_BOS && !currentValidation.bosDetected)
            return 0;
        if(Require_LiquiditySweep && !currentValidation.liquiditySweep)
            return 0;
        if(Require_FVG && !currentValidation.fvgPresent)
            return 0;
        if(Require_OrderBlock && !currentValidation.orderBlockValid)
            return 0;
        if(Require_ATR_Zone && !currentValidation.atrZoneValid)
            return 0;
        if(Require_ValidRR && !currentValidation.validRiskReward)
            return 0;
        if(Require_SessionFilter && !currentValidation.sessionActive)
            return 0;
    }
    
    // Advanced: Market regime analysis and entry grading
    if(UseMarketRegimeFilter && CheckPointer(marketAnalysis) == POINTER_DYNAMIC)
    {
        // Detect market regime
        if(ArraySize(atrH1) >= 3)
        {
            double avgATR = (atrH1[0] + atrH1[1] + atrH1[2]) / 3.0;
            int emaTrend = (h4Trend == TREND_BULLISH) ? 1 : (h4Trend == TREND_BEARISH ? -1 : 0);
            
            MARKET_REGIME regime = marketAnalysis.DetectMarketRegime(_Symbol, H4_Timeframe, atrH1[0], avgATR, emaTrend);
            
            // Filter by regime
            if(AvoidHighVolatilityRegime && regime == REGIME_HIGH_VOLATILITY)
            {
                lastErrorMsg = "Avoiding high volatility regime";
                return 0;
            }
            
            if(PreferStrongTrend && regime != REGIME_STRONG_TREND)
            {
                lastErrorMsg = "Waiting for strong trend regime";
                return 0;
            }
        }
    }
    
    // Advanced: Entry quality grading
    if(UseEntryGrading && CheckPointer(marketAnalysis) == POINTER_DYNAMIC)
    {
        // Detect confluence
        int confluenceCount = 0;
        if(UseConfluenceBonus)
        {
            confluenceCount = marketAnalysis.DetectConfluence(
                currentValidation.h4TrendValid,
                currentValidation.h1ZoneValid,
                currentValidation.bosDetected,
                currentValidation.fvgPresent,
                currentValidation.orderBlockValid,
                currentValidation.asianLevelValid,
                currentValidation.validRiskReward
            );
        }
        
        // Calculate entry grade
        MARKET_REGIME regime = marketAnalysis.GetCurrentRegime();
        ENTRY_GRADE grade = marketAnalysis.CalculateEntryGrade(currentValidation.weightedScore, confluenceCount, regime);
        
        // Skip poor quality setups
        if(SkipGradeD && grade == GRADE_D)
        {
            lastErrorMsg = StringFormat("Entry quality Grade D - skipping (Score: %.1f, Confluence: %d)",
                                       currentValidation.weightedScore, confluenceCount);
            return 0;
        }
        
        // Log entry quality
        if(EnableDetailedLogging && (grade == GRADE_A || grade == GRADE_B))
        {
            Print(StringFormat("Entry Grade %s | Score: %.1f | Confluence: %d | Regime: %s",
                             marketAnalysis.GetGradeString(grade),
                             currentValidation.weightedScore,
                             confluenceCount,
                             marketAnalysis.GetRegimeString()));
        }
    }
    
    // Determine direction based on H4 trend
    if(h4Trend == TREND_BULLISH)
        return 1; // Buy signal
    else if(h4Trend == TREND_BEARISH)
        return -1; // Sell signal
    
    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Detect Break of Structure on M5                                  |
//+------------------------------------------------------------------+
bool DetectBreakOfStructure()
{
    if(Bars(_Symbol, M5_Timeframe) < 10)
        return false;
    
    // Get recent swing points on M5
    double swingHigh = -1;
    double swingLow = 999999;
    
    for(int i = 2; i < 10; i++)
    {
        double high = iHigh(_Symbol, M5_Timeframe, i);
        double low = iLow(_Symbol, M5_Timeframe, i);
        
        if(high > swingHigh)
            swingHigh = high;
        if(low < swingLow)
            swingLow = low;
    }
    
    double currentClose = iClose(_Symbol, M5_Timeframe, 0);
    
    // Bullish BOS: Price breaks above recent swing high
    bool bullishBOS = (currentClose > swingHigh) && (h4Trend == TREND_BULLISH);
    
    // Bearish BOS: Price breaks below recent swing low
    bool bearishBOS = (currentClose < swingLow) && (h4Trend == TREND_BEARISH);
    
    return (bullishBOS || bearishBOS);
}

//+------------------------------------------------------------------+
//| Detect liquidity sweep on M5                                     |
//+------------------------------------------------------------------+
bool DetectLiquiditySweep()
{
    if(Bars(_Symbol, M5_Timeframe) < 5)
        return false;
    
    double high1 = iHigh(_Symbol, M5_Timeframe, 1);
    double low1 = iLow(_Symbol, M5_Timeframe, 1);
    double close1 = iClose(_Symbol, M5_Timeframe, 1);
    double open1 = iOpen(_Symbol, M5_Timeframe, 1);
    
    double high2 = iHigh(_Symbol, M5_Timeframe, 2);
    double low2 = iLow(_Symbol, M5_Timeframe, 2);
    
    // Bullish sweep: Breaks below previous low, then reverses up
    bool bullishSweep = (low1 < low2) && (close1 > open1) && 
                        (close1 - low1) > atrM5[0] * 0.3;
    
    // Bearish sweep: Breaks above previous high, then reverses down
    bool bearishSweep = (high1 > high2) && (close1 < open1) && 
                        (high1 - close1) > atrM5[0] * 0.3;
    
    return (bullishSweep || bearishSweep);
}

//+------------------------------------------------------------------+
//| Detect breakout using volatility expansion                       |
//+------------------------------------------------------------------+
bool DetectBreakout()
{
    if(Bars(_Symbol, M5_Timeframe) < 5)
        return false;
    
    // Get recent candle data
    double close0 = iClose(_Symbol, M5_Timeframe, 0);
    double open0 = iOpen(_Symbol, M5_Timeframe, 0);
    double high0 = iHigh(_Symbol, M5_Timeframe, 0);
    double low0 = iLow(_Symbol, M5_Timeframe, 0);
    
    double close1 = iClose(_Symbol, M5_Timeframe, 1);
    double open1 = iOpen(_Symbol, M5_Timeframe, 1);
    double high1 = iHigh(_Symbol, M5_Timeframe, 1);
    double low1 = iLow(_Symbol, M5_Timeframe, 1);
    
    // Calculate candle range
    double range0 = high0 - low0;
    double range1 = high1 - low1;
    
    // Check if range exceeds ATR threshold (volatility expansion)
    bool volatilityExpansion = (range0 > atrM5[0] * ATR_BreakoutMultiplier) ||
                               (range1 > atrM5[0] * ATR_BreakoutMultiplier);
    
    if(!volatilityExpansion)
        return false;
    
    // Check for breakout of swing points
    double swingHigh = -1;
    double swingLow = PRICE_UNSET;
    
    for(int i = 2; i < 10; i++)
    {
        double high = iHigh(_Symbol, M5_Timeframe, i);
        double low = iLow(_Symbol, M5_Timeframe, i);
        
        if(high > swingHigh)
            swingHigh = high;
        if(low < swingLow)
            swingLow = low;
    }
    
    // Bullish breakout
    bool bullishBreakout = (close0 > swingHigh) && (h4Trend == TREND_BULLISH);
    
    // Bearish breakout
    bool bearishBreakout = (close0 < swingLow) && (h4Trend == TREND_BEARISH);
    
    // Check for breakout of Asian levels if available
    if(UseAsianHighLow && asianLevels.isValid && 
       (currentSession == SESSION_LONDON || currentSession == SESSION_NEWYORK))
    {
        bool asianHighBreakout = (close0 > asianLevels.high) && (h4Trend == TREND_BULLISH);
        bool asianLowBreakout = (close0 < asianLevels.low) && (h4Trend == TREND_BEARISH);
        
        return (bullishBreakout || bearishBreakout || asianHighBreakout || asianLowBreakout);
    }
    
    return (bullishBreakout || bearishBreakout);
}

//+------------------------------------------------------------------+
//| Validate ATR-implied zones                                       |
//+------------------------------------------------------------------+
bool ValidateATRZone()
{
    // Check if current price is within acceptable ATR distance from H1 zone
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    for(int i = 0; i < ArraySize(h1Zones); i++)
    {
        double distance = MathAbs(currentPrice - h1Zones[i].level);
        if(distance <= atrH1[0] * ATR_ZoneMultiplier)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if volatility is within acceptable range                   |
//+------------------------------------------------------------------+
bool IsVolatilityAcceptable()
{
    // Ensure we have enough ATR data
    if(ArraySize(atrH1) < 3)
        return true; // Default to true if not enough data
    
    double currentATR = atrH1[0];
    double avgATR = (atrH1[0] + atrH1[1] + atrH1[2]) / 3.0;
    
    // Avoid if ATR is too high (>150% average) or too low (<50% average)
    if(currentATR > avgATR * 1.5 || currentATR < avgATR * 0.5)
        return false;
    
    // Additional check: During high volatility, verify spread is not excessively wide
    if(UseSpreadFilter && currentATR > avgATR * 1.2)
    {
        double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        double spreadPoints = spread / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        
        // During high volatility, use stricter spread limit (75% of max)
        if(spreadPoints > MaxSpreadPoints * 0.75)
        {
            lastErrorMsg = StringFormat("High volatility with wide spread: %.1f points", spreadPoints);
            return false;
        }
    }
        
    return true;
}

//+------------------------------------------------------------------+
//| Check if market structure is clean for entry                     |
//+------------------------------------------------------------------+
bool IsMarketStructureClean()
{
    // Avoid entries during choppy consolidation
    if(Bars(_Symbol, H1_Timeframe) < 20)
        return false;
    
    // Find highest high and lowest low in recent H1 bars
    int highestBar = iHighest(_Symbol, H1_Timeframe, MODE_HIGH, 20, 0);
    int lowestBar = iLowest(_Symbol, H1_Timeframe, MODE_LOW, 20, 0);
    
    double highestHigh = iHigh(_Symbol, H1_Timeframe, highestBar);
    double lowestLow = iLow(_Symbol, H1_Timeframe, lowestBar);
    
    double range = highestHigh - lowestLow;
    
    // Too narrow range indicates consolidation
    if(range < atrH1[0] * 2.0)
    {
        lastErrorMsg = "Market structure too choppy - narrow range";
        return false;
    }
    
    // Check for multiple timeframe alignment
    if(h4Trend == TREND_NEUTRAL)
    {
        lastErrorMsg = "H4 trend is neutral - no clear structure";
        return false;
    }
        
    return true;
}

//+------------------------------------------------------------------+
//| Detect rejection from key levels (Asian high/low, zones)        |
//+------------------------------------------------------------------+
bool DetectRejectionFromLevel()
{
    if(Bars(_Symbol, M5_Timeframe) < 3)
        return false;
    
    double currentPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / 2.0;
    
    // Check recent candles for wick rejection pattern
    for(int i = 0; i < 3; i++)
    {
        double open = iOpen(_Symbol, M5_Timeframe, i);
        double close = iClose(_Symbol, M5_Timeframe, i);
        double high = iHigh(_Symbol, M5_Timeframe, i);
        double low = iLow(_Symbol, M5_Timeframe, i);
        
        double bodySize = MathAbs(close - open);
        double upperWick = high - MathMax(open, close);
        double lowerWick = MathMin(open, close) - low;
        
        // Bullish rejection: large lower wick (at least 2x body size)
        bool bullishRejection = (lowerWick > bodySize * 2.0) && 
                                (lowerWick > atrM5[0] * 0.3);
        
        // Bearish rejection: large upper wick (at least 2x body size)
        bool bearishRejection = (upperWick > bodySize * 2.0) && 
                                (upperWick > atrM5[0] * 0.3);
        
        // Check if rejection occurred near a level
        if(bullishRejection || bearishRejection)
        {
            // Check Asian levels
            if(UseAsianHighLow && asianLevels.isValid)
            {
                double distanceToHigh = MathAbs(low - asianLevels.high);
                double distanceToLow = MathAbs(low - asianLevels.low);
                
                if(distanceToHigh < atrM5[0] * 0.5 || distanceToLow < atrM5[0] * 0.5)
                    return true;
            }
            
            // Check H1 zones
            for(int j = 0; j < ArraySize(h1Zones); j++)
            {
                double distanceToZone = MathAbs(low - h1Zones[j].level);
                if(distanceToZone < atrM5[0] * 0.5)
                    return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for volume expansion (using tick volume)                   |
//+------------------------------------------------------------------+
bool CheckVolumeExpansion(double multiplier = 1.5)
{
    if(Bars(_Symbol, M5_Timeframe) < 5)
        return false;
    
    // Get recent tick volumes
    long currentVolume = iVolume(_Symbol, M5_Timeframe, 0);
    long prevVolume1 = iVolume(_Symbol, M5_Timeframe, 1);
    long prevVolume2 = iVolume(_Symbol, M5_Timeframe, 2);
    long prevVolume3 = iVolume(_Symbol, M5_Timeframe, 3);
    long prevVolume4 = iVolume(_Symbol, M5_Timeframe, 4);
    
    // Calculate average volume
    long avgVolume = (prevVolume1 + prevVolume2 + prevVolume3 + prevVolume4) / 4;
    
    // Volume expansion: current volume is at least multiplier% of average
    if(currentVolume > avgVolume * multiplier)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Find nearest swing point for stop-loss                           |
//+------------------------------------------------------------------+
double FindSwingPointSL(bool isBuyOrder, double entryPrice)
{
    if(!UseSwingPointSL)
        return 0.0;
    
    double swingPoint = 0.0;
    
    if(isBuyOrder)
    {
        // For buy orders, find recent swing low
        double lowestLow = PRICE_UNSET;
        for(int i = 1; i < SwingLookback; i++)
        {
            double low = iLow(_Symbol, M5_Timeframe, i);
            if(low < lowestLow && low < entryPrice)
                lowestLow = low;
        }
        
        if(lowestLow < PRICE_UNSET)
            swingPoint = lowestLow;
    }
    else
    {
        // For sell orders, find recent swing high
        double highestHigh = -1;
        for(int i = 1; i < SwingLookback; i++)
        {
            double high = iHigh(_Symbol, M5_Timeframe, i);
            if(high > highestHigh && high > entryPrice)
                highestHigh = high;
        }
        
        if(highestHigh > 0)
            swingPoint = highestHigh;
    }
    
    // Also check H1 zones for better stop placement
    for(int i = 0; i < ArraySize(h1Zones); i++)
    {
        if(isBuyOrder && h1Zones[i].isSupport && h1Zones[i].level < entryPrice)
        {
            // Use support zone as stop if it's closer than swing point
            if(swingPoint == 0.0 || h1Zones[i].level > swingPoint)
                swingPoint = h1Zones[i].level;
        }
        else if(!isBuyOrder && !h1Zones[i].isSupport && h1Zones[i].level > entryPrice)
        {
            // Use resistance zone as stop if it's closer than swing point
            if(swingPoint == 0.0 || h1Zones[i].level < swingPoint)
                swingPoint = h1Zones[i].level;
        }
    }
    
    return swingPoint;
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate initial SL and TP
    double slDistance = atrM5[0] * ATR_StopLossMultiplier;
    double tpDistance = atrM5[0] * ATR_TakeProfitMultiplier;
    
    // Apply dynamic R:R if enabled
    if(UseDynamicRR)
    {
        double avgATR = (atrH4[0] + atrH1[0] + atrM5[0]) / 3.0;
        
        // Prevent division by zero - use epsilon for floating point comparison
        if(MathAbs(avgATR) > DBL_EPSILON)
        {
            double volatilityRatio = atrM5[0] / avgATR;
            tpDistance = atrM5[0] * ATR_TakeProfitMultiplier * volatilityRatio * DynamicRR_Multiplier;
        }
    }
    
    // Check for swing point SL
    double swingPointSL = FindSwingPointSL(true, ask);
    if(swingPointSL > 0.0)
    {
        double swingDistance = ask - swingPointSL;
        // Use swing point if it provides better (wider) stop
        if(swingDistance > slDistance && swingDistance < slDistance * 2.0)
        {
            slDistance = swingDistance;
            lastErrorMsg = "Using swing point SL";
        }
    }
    
    // Ensure minimum RR ratio
    if(tpDistance < slDistance * MinRiskRewardRatio)
        tpDistance = slDistance * MinRiskRewardRatio;
    
    double sl = ask - slDistance;
    double tp = ask + tpDistance;
    
    // Calculate lot size
    double slPoints = slDistance / point;
    double lotSize = CalculateLotSize(slPoints);
    
    // Apply partial position scaling if enabled
    if(UsePartialPositions)
    {
        lotSize = lotSize * (PartialEntry_Percent / 100.0);
    }
    
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
    {
        lastErrorMsg = "Lot size too small";
        return;
    }
    
    // Execute trade
    trade.SetDeviationInPoints(10);
    
    string comment = "Simba Sniper Buy";
    if(UsePartialPositions)
        comment += StringFormat(" (%.0f%%)", PartialEntry_Percent);
    
    if(trade.Buy(lotSize, _Symbol, ask, sl, tp, comment))
    {
        dailyTrades++;
        ulong ticket = trade.ResultOrder();
        
        Print(StringFormat("BUY order executed at %.2f, SL: %.2f, TP: %.2f, Lot: %.2f, Validation: %d/11", 
              ask, sl, tp, lotSize, currentValidation.totalPoints));
        
        // Notify risk manager of new trade
        if(CheckPointer(riskManager) == POINTER_DYNAMIC)
            riskManager.OnTradeOpen();
        
        // Start tracking position in performance tracker
        if(EnablePerformanceTracking && CheckPointer(perfTracker) == POINTER_DYNAMIC)
        {
            perfTracker.StartTrackingPosition(ticket, ask, sl, tp, TimeCurrent());
        }
        
        // Start tracking in trade executor for advanced exit management
        if(CheckPointer(tradeExecutor) == POINTER_DYNAMIC && (UsePartialExits || UseSmartTrailing))
        {
            tradeExecutor.StartTracking(ticket, ask, sl, tp);
        }
    }
    else
    {
        lastErrorMsg = "Failed to execute BUY order: " + IntegerToString(trade.ResultRetcode());
        Print(lastErrorMsg);
    }
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrder()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate initial SL and TP
    double slDistance = atrM5[0] * ATR_StopLossMultiplier;
    double tpDistance = atrM5[0] * ATR_TakeProfitMultiplier;
    
    // Apply dynamic R:R if enabled
    if(UseDynamicRR)
    {
        double avgATR = (atrH4[0] + atrH1[0] + atrM5[0]) / 3.0;
        
        // Prevent division by zero - use epsilon for floating point comparison
        if(MathAbs(avgATR) > DBL_EPSILON)
        {
            double volatilityRatio = atrM5[0] / avgATR;
            tpDistance = atrM5[0] * ATR_TakeProfitMultiplier * volatilityRatio * DynamicRR_Multiplier;
        }
    }
    
    // Check for swing point SL
    double swingPointSL = FindSwingPointSL(false, bid);
    if(swingPointSL > 0.0)
    {
        double swingDistance = swingPointSL - bid;
        // Use swing point if it provides better (wider) stop
        if(swingDistance > slDistance && swingDistance < slDistance * 2.0)
        {
            slDistance = swingDistance;
            lastErrorMsg = "Using swing point SL";
        }
    }
    
    // Ensure minimum RR ratio
    if(tpDistance < slDistance * MinRiskRewardRatio)
        tpDistance = slDistance * MinRiskRewardRatio;
    
    double sl = bid + slDistance;
    double tp = bid - tpDistance;
    
    // Calculate lot size
    double slPoints = slDistance / point;
    double lotSize = CalculateLotSize(slPoints);
    
    // Apply partial position scaling if enabled
    if(UsePartialPositions)
    {
        lotSize = lotSize * (PartialEntry_Percent / 100.0);
    }
    
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
    {
        lastErrorMsg = "Lot size too small";
        return;
    }
    
    // Execute trade
    trade.SetDeviationInPoints(10);
    
    string comment = "Simba Sniper Sell";
    if(UsePartialPositions)
        comment += StringFormat(" (%.0f%%)", PartialEntry_Percent);
    
    if(trade.Sell(lotSize, _Symbol, bid, sl, tp, comment))
    {
        dailyTrades++;
        ulong ticket = trade.ResultOrder();
        
        Print(StringFormat("SELL order executed at %.2f, SL: %.2f, TP: %.2f, Lot: %.2f, Validation: %d/11", 
              bid, sl, tp, lotSize, currentValidation.totalPoints));
        
        // Notify risk manager of new trade
        if(CheckPointer(riskManager) == POINTER_DYNAMIC)
            riskManager.OnTradeOpen();
        
        // Start tracking position in performance tracker
        if(EnablePerformanceTracking && CheckPointer(perfTracker) == POINTER_DYNAMIC)
        {
            perfTracker.StartTrackingPosition(ticket, bid, sl, tp, TimeCurrent());
        }
        
        // Start tracking in trade executor for advanced exit management
        if(CheckPointer(tradeExecutor) == POINTER_DYNAMIC && (UsePartialExits || UseSmartTrailing))
        {
            tradeExecutor.StartTracking(ticket, bid, sl, tp);
        }
    }
    else
    {
        lastErrorMsg = "Failed to execute SELL order: " + IntegerToString(trade.ResultRetcode());
        Print(lastErrorMsg);
    }
}

//+------------------------------------------------------------------+
//| Calculate potential risk/reward ratio for entry validation       |
//+------------------------------------------------------------------+
double CalculatePotentialRR(bool isBuySignal)
{
    double currentPrice;
    double slDistance = atrM5[0] * ATR_StopLossMultiplier;
    double tpDistance = atrM5[0] * ATR_TakeProfitMultiplier;
    
    // Apply dynamic R:R based on volatility if enabled
    if(UseDynamicRR)
    {
        // Calculate volatility ratio (current ATR vs average)
        double avgATR = (atrH4[0] + atrH1[0] + atrM5[0]) / 3.0;
        
        // Prevent division by zero - use epsilon for floating point comparison
        if(MathAbs(avgATR) > DBL_EPSILON)
        {
            double volatilityRatio = atrM5[0] / avgATR;
            
            // Adjust TP distance based on volatility
            // Higher volatility = wider targets
            tpDistance = atrM5[0] * ATR_TakeProfitMultiplier * volatilityRatio * DynamicRR_Multiplier;
        }
        else
        {
            // Fallback to standard TP if avgATR is zero
            tpDistance = atrM5[0] * ATR_TakeProfitMultiplier;
        }
    }
    
    if(isBuySignal)
    {
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // Check for swing point SL
        double swingPointSL = FindSwingPointSL(true, currentPrice);
        if(swingPointSL > 0.0)
        {
            double swingDistance = currentPrice - swingPointSL;
            // Use swing point if it provides better (wider) stop
            if(swingDistance > slDistance && swingDistance < slDistance * 2.0)
            {
                slDistance = swingDistance;
            }
        }
    }
    else
    {
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        // Check for swing point SL
        double swingPointSL = FindSwingPointSL(false, currentPrice);
        if(swingPointSL > 0.0)
        {
            double swingDistance = swingPointSL - currentPrice;
            // Use swing point if it provides better (wider) stop
            if(swingDistance > slDistance && swingDistance < slDistance * 2.0)
            {
                slDistance = swingDistance;
            }
        }
    }
    
    // Ensure minimum RR ratio
    if(tpDistance < slDistance * MinRiskRewardRatio)
        tpDistance = slDistance * MinRiskRewardRatio;
    
    if(slDistance > 0)
        return tpDistance / slDistance;
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Calculate dynamic risk based on recent performance               |
//+------------------------------------------------------------------+
double CalculateDynamicRisk()
{
    // Need at least 3 trades for meaningful adjustment
    if(dailyTrades < 3)
        return RiskPercentage; // Not enough data
    
    double winRate = (double)dailyWins / dailyTrades;
    
    if(winRate < 0.4) // Losing streak
        return RiskPercentage * 0.5; // Reduce risk by half
    else if(winRate > 0.6) // Winning streak
        return RiskPercentage * 1.2; // Increase risk by 20% (capped)
    
    return RiskPercentage;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPoints)
{
    // Use RiskManager for dynamic position sizing
    if(CheckPointer(riskManager) == POINTER_DYNAMIC)
    {
        double stopLossDistance = stopLossPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        double lotSize = riskManager.CalculatePositionSize(stopLossDistance, _Symbol);
        
        // Ensure lot size is valid
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        if(lotSize < minLot)
            lotSize = minLot;
        
        return lotSize;
    }
    
    // Fallback to original calculation if risk manager not available
    double balance = accountInfo.Balance();
    
    // Use dynamic risk adjustment
    double dynamicRisk = CalculateDynamicRisk();
    double riskAmount = balance * (dynamicRisk / 100.0);
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(tickSize == 0 || point == 0)
        return 0.0;
    
    double moneyPerPoint = (tickValue / tickSize) * point;
    double lotSize = riskAmount / (stopLossPoints * moneyPerPoint);
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() != _Symbol)
                continue;
            
            // Implement break-even stop-loss
            if(UseBreakEvenStop)
            {
                double openPrice = positionInfo.PriceOpen();
                double currentSL = positionInfo.StopLoss();
                double currentTP = positionInfo.TakeProfit();
                double currentPrice = positionInfo.PriceCurrent();
                
                if(positionInfo.Type() == POSITION_TYPE_BUY)
                {
                    double tpDistance = currentTP - openPrice;
                    double triggerPrice = openPrice + (tpDistance * BreakEvenTriggerRatio);
                    
                    // Move SL to break-even + small buffer when price reaches trigger
                    if(currentPrice >= triggerPrice && currentSL < openPrice)
                    {
                        double newSL = openPrice + (atrM5[0] * 0.1); // Small buffer above entry
                        if(trade.PositionModify(positionInfo.Ticket(), newSL, currentTP))
                        {
                            Print(StringFormat("Break-even SL set for BUY #%d at %.2f", 
                                  positionInfo.Ticket(), newSL));
                        }
                    }
                }
                else if(positionInfo.Type() == POSITION_TYPE_SELL)
                {
                    double tpDistance = openPrice - currentTP;
                    double triggerPrice = openPrice - (tpDistance * BreakEvenTriggerRatio);
                    
                    // Move SL to break-even - small buffer when price reaches trigger
                    // Check if SL hasn't been moved to break-even yet
                    if(currentPrice <= triggerPrice && currentSL > openPrice)
                    {
                        double newSL = openPrice - (atrM5[0] * 0.1); // Small buffer below entry
                        if(trade.PositionModify(positionInfo.Ticket(), newSL, currentTP))
                        {
                            Print(StringFormat("Break-even SL set for SELL #%d at %.2f", 
                                  positionInfo.Ticket(), newSL));
                        }
                    }
                }
            }
            
            // Implement trailing stop-loss
            if(UseTrailingStop)
            {
                double openPrice = positionInfo.PriceOpen();
                double currentSL = positionInfo.StopLoss();
                double currentTP = positionInfo.TakeProfit();
                double currentPrice = positionInfo.PriceCurrent();
                double trailingDistance = atrM5[0] * TrailingStopATRMultiplier;
                
                if(positionInfo.Type() == POSITION_TYPE_BUY)
                {
                    double newSL = currentPrice - trailingDistance;
                    // Only move SL up, never down, and only if it's above break-even
                    if(newSL > currentSL && newSL > openPrice)
                    {
                        if(trade.PositionModify(positionInfo.Ticket(), newSL, currentTP))
                        {
                            Print(StringFormat("Trailing SL updated for BUY #%d to %.2f", 
                                  positionInfo.Ticket(), newSL));
                        }
                    }
                }
                else if(positionInfo.Type() == POSITION_TYPE_SELL)
                {
                    double newSL = currentPrice + trailingDistance;
                    // Only move SL down, never up, and only if it's below break-even
                    if(newSL < currentSL && newSL < openPrice)
                    {
                        if(trade.PositionModify(positionInfo.Ticket(), newSL, currentTP))
                        {
                            Print(StringFormat("Trailing SL updated for SELL #%d to %.2f", 
                                  positionInfo.Ticket(), newSL));
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == _Symbol)
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Update current trading session                                   |
//+------------------------------------------------------------------+
void UpdateCurrentSession()
{
    datetime now = TimeCurrent();
    MqlDateTime tm;
    TimeToStruct(now, tm);
    int currentHour = tm.hour;
    
    // Apply GMT offset
    currentHour = ((currentHour + SessionGMTOffset) % 24 + 24) % 24;
    
    // Determine current session
    if(currentHour >= AsianStartHour && currentHour < AsianEndHour)
        currentSession = SESSION_ASIAN;
    else if(currentHour >= LondonStartHour && currentHour < LondonEndHour)
        currentSession = SESSION_LONDON;
    else if(currentHour >= NewYorkStartHour && currentHour < NewYorkEndHour)
        currentSession = SESSION_NEWYORK;
    else
        currentSession = SESSION_NONE;
}

//+------------------------------------------------------------------+
//| Update Asian session high and low levels                         |
//+------------------------------------------------------------------+
void UpdateAsianSessionLevels()
{
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    
    // Check if we need to reset for a new day
    MqlDateTime sessionTime;
    TimeToStruct(asianLevels.sessionDate, sessionTime);
    
    if(currentTime.day != sessionTime.day || !asianLevels.isValid)
    {
        // New day - reset Asian levels
        asianLevels.high = 0;
        asianLevels.low = PRICE_UNSET;
        asianLevels.sessionDate = TimeCurrent();
        asianLevels.isValid = false;
    }
    
    // During Asian session, track high and low
    if(currentSession == SESSION_ASIAN)
    {
        double currentHigh = iHigh(_Symbol, PERIOD_M5, 0);
        double currentLow = iLow(_Symbol, PERIOD_M5, 0);
        
        if(currentHigh > asianLevels.high || asianLevels.high == 0)
            asianLevels.high = currentHigh;
        
        if(currentLow < asianLevels.low || asianLevels.low == PRICE_UNSET)
            asianLevels.low = currentLow;
        
        asianLevels.isValid = true;
    }
}

//+------------------------------------------------------------------+
//| Check if within trading session                                  |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
    datetime now = TimeCurrent();
    MqlDateTime tm;
    TimeToStruct(now, tm);
    int currentHour = tm.hour;
    
    // Apply GMT offset
    currentHour = ((currentHour + SessionGMTOffset) % 24 + 24) % 24;
    
    bool inAsian = false;
    bool inLondon = false;
    bool inNewYork = false;
    
    if(TradeAsianSession)
        inAsian = (currentHour >= AsianStartHour && currentHour < AsianEndHour);
    
    if(TradeLondonSession)
        inLondon = (currentHour >= LondonStartHour && currentHour < LondonEndHour);
    
    if(TradeNewYorkSession)
        inNewYork = (currentHour >= NewYorkStartHour && currentHour < NewYorkEndHour);
    
    return (inAsian || inLondon || inNewYork);
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
{
    double currentBalance = accountInfo.Balance();
    double dailyPL = currentBalance - dailyStartBalance;
    double maxLoss = dailyStartBalance * (MaxDailyLossPercent / 100.0);
    
    return (dailyPL >= -maxLoss);
}

//+------------------------------------------------------------------+
//| Check for new day and reset counters                             |
//+------------------------------------------------------------------+
void CheckNewDay()
{
    MqlDateTime currentTime, startTime;
    TimeToStruct(TimeCurrent(), currentTime);
    TimeToStruct(dailyStartTime, startTime);
    
    if(currentTime.day != startTime.day)
    {
        // Reset for new day
        dailyStartTime = TimeCurrent();
        dailyStartBalance = accountInfo.Balance();
        dailyTrades = 0;
        dailyWins = 0;
        dailyLosses = 0;
        tradingPaused = false;
        
        Print("New trading day started");
    }
}

//+------------------------------------------------------------------+
//| Create dashboard                                                 |
//+------------------------------------------------------------------+
void CreateDashboard()
{
    string prefix = "SimbaSniper_";
    
    // Background - using constants for maintainability
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, DashboardX);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, DashboardY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, DASHBOARD_WIDTH);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, DASHBOARD_HEIGHT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, DashboardBGColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    
    // Create labels
    CreateLabel(prefix + "Title", "SIMBA SNIPER EA", DashboardX + 10, DashboardY + 10, 11, clrGold);
    CreateLabel(prefix + "Strategy", "Multi-Timeframe Institutional", DashboardX + 10, DashboardY + 35, 8, clrSilver);
    CreateLabel(prefix + "H4Trend", "H4 Trend: Analyzing...", DashboardX + 10, DashboardY + 60, 9, DashboardTextColor);
    CreateLabel(prefix + "H1Zones", "H1 Zones: 0", DashboardX + 10, DashboardY + 85, 9, DashboardTextColor);
    CreateLabel(prefix + "OrderBlocks", "Order Blocks: 0", DashboardX + 10, DashboardY + 110, 9, DashboardTextColor);
    CreateLabel(prefix + "FVGs", "Fair Value Gaps: 0", DashboardX + 10, DashboardY + 135, 9, DashboardTextColor);
    CreateLabel(prefix + "AsianLevels", "Asian High/Low: N/A", DashboardX + 10, DashboardY + 160, 9, DashboardTextColor);
    CreateLabel(prefix + "Validation", "Entry Validation: 0/11", DashboardX + 10, DashboardY + 185, 9, DashboardTextColor);
    CreateLabel(prefix + "Points", "Points Met: None", DashboardX + 10, DashboardY + 210, 8, clrYellow);
    CreateLabel(prefix + "NearMiss", "Near-Misses: 0", DashboardX + 10, DashboardY + 235, 8, clrOrange);
    CreateLabel(prefix + "Session", "Session: Closed", DashboardX + 10, DashboardY + 260, 9, DashboardTextColor);
    CreateLabel(prefix + "Balance", "Balance: 0.00", DashboardX + 10, DashboardY + 290, 9, DashboardTextColor);
    CreateLabel(prefix + "DailyPL", "Daily P/L: 0.00", DashboardX + 10, DashboardY + 315, 9, DashboardTextColor);
    CreateLabel(prefix + "Trades", "Trades: 0", DashboardX + 10, DashboardY + 340, 9, DashboardTextColor);
    CreateLabel(prefix + "Positions", "Open Positions: 0", DashboardX + 10, DashboardY + 365, 9, DashboardTextColor);
    CreateLabel(prefix + "ATRH4", "ATR H4: 0.00", DashboardX + 10, DashboardY + 395, 8, DashboardTextColor);
    CreateLabel(prefix + "ATRH1", "ATR H1: 0.00", DashboardX + 10, DashboardY + 420, 8, DashboardTextColor);
    CreateLabel(prefix + "ATRM5", "ATR M5: 0.00", DashboardX + 10, DashboardY + 445, 8, DashboardTextColor);
    CreateLabel(prefix + "Status", "Status: Active", DashboardX + 10, DashboardY + 470, 9, clrLime);
    CreateLabel(prefix + "RiskInfo", "Risk: Loading...", DashboardX + 10, DashboardY + 495, 8, clrAqua);
    CreateLabel(prefix + "PerfInfo", "Performance: Loading...", DashboardX + 10, DashboardY + 520, 8, clrAqua);
    CreateLabel(prefix + "LondonStats", "", DashboardX + 10, DashboardY + 545, 7, DashboardTextColor);
    CreateLabel(prefix + "NYStats", "", DashboardX + 10, DashboardY + 565, 7, DashboardTextColor);
    CreateLabel(prefix + "Error", "", DashboardX + 10, DashboardY + 590, 7, clrRed);
}

//+------------------------------------------------------------------+
//| Create label helper                                              |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int fontSize, color clr)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Update dashboard                                                 |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    string prefix = "SimbaSniper_";
    
    // H4 Trend
    string trendText = "H4 Trend: ";
    color trendColor = DashboardTextColor;
    
    if(h4Trend == TREND_BULLISH)
    {
        trendText += "BULLISH";
        trendColor = clrLime;
    }
    else if(h4Trend == TREND_BEARISH)
    {
        trendText += "BEARISH";
        trendColor = clrRed;
    }
    else
    {
        trendText += "NEUTRAL";
        trendColor = clrYellow;
    }
    
    // Add trend mode indicator
    if(H4TrendMode == TREND_SIMPLE)
        trendText += " (Simple)";
    else
        trendText += " (Strict)";
    
    ObjectSetString(0, prefix + "H4Trend", OBJPROP_TEXT, trendText);
    ObjectSetInteger(0, prefix + "H4Trend", OBJPROP_COLOR, trendColor);
    
    // H1 Zones
    ObjectSetString(0, prefix + "H1Zones", OBJPROP_TEXT, 
                    StringFormat("H1 Zones: %d", ArraySize(h1Zones)));
    
    // Order Blocks
    ObjectSetString(0, prefix + "OrderBlocks", OBJPROP_TEXT, 
                    StringFormat("Order Blocks: %d", ArraySize(h1OrderBlocks)));
    
    // FVGs
    ObjectSetString(0, prefix + "FVGs", OBJPROP_TEXT, 
                    StringFormat("Fair Value Gaps: %d", ArraySize(h1FVGs)));
    
    // Asian Levels
    string asianText = "Asian High/Low: ";
    if(asianLevels.isValid)
        asianText += StringFormat("H:%.2f L:%.2f", asianLevels.high, asianLevels.low);
    else
        asianText += "N/A";
    ObjectSetString(0, prefix + "AsianLevels", OBJPROP_TEXT, asianText);
    
    // Validation with strategy mode
    string validationText = StringFormat("Validation: %d/11 (Min:%d)", 
                                         currentValidation.totalPoints, MinValidationPoints);
    if(UseWeightedScoring)
        validationText += StringFormat(" [Score:%.1f]", currentValidation.weightedScore);
    if(UseEssentialOnly)
        validationText += " [Essential Only]";
    else if(EntryStrategy == STRATEGY_BREAKOUT)
        validationText += " [Breakout]";
    else if(EntryStrategy == STRATEGY_REVERSAL)
        validationText += " [Reversal]";
    else if(EntryStrategy == STRATEGY_CONTINUATION)
        validationText += " [Continuation]";
    else
        validationText += " [Universal]";
    
    ObjectSetString(0, prefix + "Validation", OBJPROP_TEXT, validationText);
    
    // Validation Points Details
    string pointsText = "Points: ";
    if(currentValidation.h4TrendValid) pointsText += "H4 ";
    if(currentValidation.h1ZoneValid) pointsText += "Zone ";
    if(currentValidation.bosDetected) pointsText += "BOS ";
    if(currentValidation.liquiditySweep) pointsText += "Sweep ";
    if(currentValidation.fvgPresent) pointsText += "FVG ";
    if(currentValidation.orderBlockValid) pointsText += "OB ";
    if(currentValidation.atrZoneValid) pointsText += "ATR ";
    if(currentValidation.breakoutDetected) pointsText += "Breakout ";
    if(currentValidation.asianLevelValid) pointsText += "Asian ";
    if(currentValidation.validRiskReward) pointsText += "RR ";
    if(currentValidation.sessionActive) pointsText += "Session";
    
    if(currentValidation.totalPoints == 0) pointsText = "Points: None";
    
    ObjectSetString(0, prefix + "Points", OBJPROP_TEXT, pointsText);
    
    // Near-miss tracking
    if(TrackNearMisses && ShowValidationDetails)
    {
        string nearMissText = StringFormat("Near-Misses: %d", nearMissCount);
        ObjectSetString(0, prefix + "NearMiss", OBJPROP_TEXT, nearMissText);
    }
    
    // Session
    string sessionText = "Session: ";
    if(currentSession == SESSION_ASIAN) sessionText += "ASIAN";
    else if(currentSession == SESSION_LONDON) sessionText += "LONDON";
    else if(currentSession == SESSION_NEWYORK) sessionText += "NEW YORK";
    else sessionText += "CLOSED";
    
    if(SessionSpecificRulesOptional)
        sessionText += " (Rules: Optional)";
    
    color sessionColor = (currentSession != SESSION_NONE) ? clrLime : clrOrange;
    ObjectSetString(0, prefix + "Session", OBJPROP_TEXT, sessionText);
    ObjectSetInteger(0, prefix + "Session", OBJPROP_COLOR, sessionColor);
    
    // Balance
    ObjectSetString(0, prefix + "Balance", OBJPROP_TEXT, 
                    StringFormat("Balance: %.2f", accountInfo.Balance()));
    
    // Daily P/L
    double dailyPL = accountInfo.Balance() - dailyStartBalance;
    color plColor = dailyPL >= 0 ? clrLime : clrRed;
    ObjectSetString(0, prefix + "DailyPL", OBJPROP_TEXT, 
                    StringFormat("Daily P/L: %.2f", dailyPL));
    ObjectSetInteger(0, prefix + "DailyPL", OBJPROP_COLOR, plColor);
    
    // Trades
    ObjectSetString(0, prefix + "Trades", OBJPROP_TEXT, 
                    StringFormat("Trades: %d", dailyTrades));
    
    // Open Positions
    ObjectSetString(0, prefix + "Positions", OBJPROP_TEXT, 
                    StringFormat("Open Positions: %d", CountOpenPositions()));
    
    // ATR values
    ObjectSetString(0, prefix + "ATRH4", OBJPROP_TEXT, 
                    StringFormat("ATR H4: %.2f", atrH4[0]));
    ObjectSetString(0, prefix + "ATRH1", OBJPROP_TEXT, 
                    StringFormat("ATR H1: %.2f", atrH1[0]));
    ObjectSetString(0, prefix + "ATRM5", OBJPROP_TEXT, 
                    StringFormat("ATR M5: %.2f", atrM5[0]));
    
    // Status
    string statusText = tradingPaused ? "Status: PAUSED" : "Status: ACTIVE";
    color statusColor = tradingPaused ? clrRed : clrLime;
    ObjectSetString(0, prefix + "Status", OBJPROP_TEXT, statusText);
    ObjectSetInteger(0, prefix + "Status", OBJPROP_COLOR, statusColor);
    
    // Risk Manager Info
    if(CheckPointer(riskManager) == POINTER_DYNAMIC)
    {
        string riskInfo = StringFormat("Risk: %.2f%% | DD: %.1f%% | Streak: W%d L%d",
                                       riskManager.GetAdjustedRiskPercent(),
                                       riskManager.GetCurrentDrawdown(),
                                       riskManager.GetConsecutiveWins(),
                                       riskManager.GetConsecutiveLosses());
        ObjectSetString(0, prefix + "RiskInfo", OBJPROP_TEXT, riskInfo);
    }
    
    // Performance Tracker Info
    if(EnablePerformanceTracking && CheckPointer(perfTracker) == POINTER_DYNAMIC)
    {
        ObjectSetString(0, prefix + "PerfInfo", OBJPROP_TEXT, perfTracker.GetDiagnosticSummary());
        
        if(ShowSessionStats)
        {
            ObjectSetString(0, prefix + "LondonStats", OBJPROP_TEXT, perfTracker.GetSessionSummary("LONDON"));
            ObjectSetString(0, prefix + "NYStats", OBJPROP_TEXT, perfTracker.GetSessionSummary("NEWYORK"));
        }
    }
    
    // Error
    ObjectSetString(0, prefix + "Error", OBJPROP_TEXT, lastErrorMsg);
}

//+------------------------------------------------------------------+
//| Delete dashboard                                                 |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
    string prefix = "SimbaSniper_";
    
    ObjectDelete(0, prefix + "BG");
    ObjectDelete(0, prefix + "Title");
    ObjectDelete(0, prefix + "Strategy");
    ObjectDelete(0, prefix + "H4Trend");
    ObjectDelete(0, prefix + "H1Zones");
    ObjectDelete(0, prefix + "OrderBlocks");
    ObjectDelete(0, prefix + "FVGs");
    ObjectDelete(0, prefix + "AsianLevels");
    ObjectDelete(0, prefix + "Validation");
    ObjectDelete(0, prefix + "Points");
    ObjectDelete(0, prefix + "Session");
    ObjectDelete(0, prefix + "Balance");
    ObjectDelete(0, prefix + "DailyPL");
    ObjectDelete(0, prefix + "Trades");
    ObjectDelete(0, prefix + "Positions");
    ObjectDelete(0, prefix + "ATRH4");
    ObjectDelete(0, prefix + "ATRH1");
    ObjectDelete(0, prefix + "ATRM5");
    ObjectDelete(0, prefix + "Status");
    ObjectDelete(0, prefix + "RiskInfo");
    ObjectDelete(0, prefix + "PerfInfo");
    ObjectDelete(0, prefix + "LondonStats");
    ObjectDelete(0, prefix + "NYStats");
    ObjectDelete(0, prefix + "NearMiss");
    ObjectDelete(0, prefix + "Error");
}
//+------------------------------------------------------------------+
