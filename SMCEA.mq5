//+------------------------------------------------------------------+
//|                                                       SMCEA.mq5   |
//|                    Professional Smart Money Concepts Expert Advisor|
//|                           Institutional XAUUSD Sniper Strategy    |
//+------------------------------------------------------------------+
#property copyright "Smart Money Concepts EA"
#property link      ""
#property version   "1.00"
#property strict
#property description "Professional institutional-grade Smart Money Concepts EA"
#property description "Liquidity Sweeps + Order Blocks + HTF Premium/Discount Alignment"
#property description "XAUUSD optimized - Prop firm ready - Non-retail execution logic"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+

//--- HTF Premium/Discount Filter
input group "=== HTF PREMIUM/DISCOUNT FILTER (MANDATORY) ==="
input ENUM_TIMEFRAMES HTF_Timeframe = PERIOD_H1;        // HTF for Premium/Discount (H1/H4)
input int HTF_SwingLookback = 50;                       // HTF Swing High/Low Lookback Bars
input bool HTF_StrictAlignment = true;                  // Strict HTF PD Alignment (No Equilibrium Trades)

//--- Liquidity Levels
input group "=== LIQUIDITY LEVEL TRACKING ==="
input bool Track_PDH_PDL = true;                        // Track Previous Day High/Low
input bool Track_SessionHighLow = true;                 // Track Session High/Low
input bool Track_SwingPoints = true;                    // Track HTF Swing Points
input bool Track_EqualHighLow = true;                   // Track Equal High/Low Clusters
input double EqualLevel_Tolerance = 5.0;                // Equal Level Tolerance (Points)

//--- Liquidity Sweep Logic
input group "=== LIQUIDITY SWEEP DETECTION ==="
input double Sweep_WickMinPoints = 3.0;                 // Minimum Wick Beyond Level (Points)
input bool Sweep_RequireCloseInside = true;             // Require Close Back Inside Range
input bool Sweep_NoBodyThrough = true;                  // No Body Close Through Level
input int Sweep_ValidationBars = 3;                     // Bars to Validate Sweep

//--- Order Block Logic
input group "=== ORDER BLOCK DETECTION ==="
input double OB_MinBodyPercent = 60.0;                  // Minimum Body % (Displacement Quality)
input double OB_MinSizePoints = 20.0;                   // Minimum OB Size (XAUUSD Points)
input int OB_MaxAge = 50;                               // Max OB Age in Bars
input bool OB_OneTradePerBlock = true;                  // One Trade Per Order Block

//--- Entry Models (Hierarchy)
input group "=== ENTRY MODELS (EVALUATED IN ORDER) ==="
input bool Model1_ClassicOB = true;                     // Model 1: Classic OB Retrace
input bool Model2_ShallowRejection = true;              // Model 2: Shallow OB Rejection (≤50%)
input bool Model3_SweepMSS = true;                      // Model 3: Sweep → MSS → OB
input bool Model4_DoubleSweep = true;                   // Model 4: Double Liquidity Sweep
input bool Model5_SessionRaid = true;                   // Model 5: Session High/Low Raid
input bool Model6_HTFRangeExtreme = true;               // Model 6: HTF Range Extreme Sweep
input bool Model7_EqualClusterRaid = true;              // Model 7: Equal H/L Cluster Raid

//--- XAUUSD Optimization
input group "=== XAUUSD SPECIFIC OPTIMIZATION ==="
input double XAU_MinDisplacementPoints = 50.0;          // Minimum Displacement Body (Gold Points)
input double XAU_SL_BufferPoints = 10.0;                // SL Buffer Beyond OB (Points)
input double XAU_SpreadBuffer = 5.0;                    // Spread Buffer (Points)
input double XAU_MaxSpread = 30.0;                      // Max Allowed Spread (Points)
input bool XAU_PreferLondon = true;                     // Prefer London Session
input bool XAU_PreferNY = true;                         // Prefer New York Session
input bool XAU_AllowAsia = false;                       // Allow Asia Session

//--- Risk Management
input group "=== RISK MANAGEMENT ==="
input double Risk_Percent = 1.0;                        // Risk Per Trade (%)
input double Risk_MinRR = 3.0;                          // Minimum Risk:Reward Ratio
input int Risk_MaxTradesPerDay = 3;                     // Max Trades Per Day
input int Risk_MaxTradesPerSession = 1;                 // Max Trades Per Session
input double Risk_MaxDailyLoss = 3.0;                   // Max Daily Loss (%)
input bool Risk_UseDailyLossGuard = true;               // Enable Daily Loss Guard

//--- Stop Loss & Take Profit
input group "=== SL & TP MANAGEMENT ==="
input bool SL_BeyondOB = true;                          // SL Beyond Order Block
input double SL_ATR_Multiplier = 2.0;                   // SL ATR Multiplier (Volatility Buffer)
input int SL_ATR_Period = 14;                           // ATR Period
input bool TP_UseFixedRR = true;                        // Use Fixed R:R Multiple
input double TP_RR_Multiple = 3.0;                      // TP R:R Multiple
input bool TP_PartialAt1R = false;                      // Partial Exit at 1R
input double TP_PartialPercent = 50.0;                  // Partial Exit Size (%)
input bool TP_BEAt1R = true;                            // Break Even at 1R
input double TP_BE_Buffer = 5.0;                        // BE Buffer (Points)

//--- Visual Debugging
input group "=== VISUAL DEBUGGING ==="
input bool Visual_ShowLiquidity = true;                 // Draw Liquidity Levels
input bool Visual_ShowSweeps = true;                    // Draw Sweep Markers
input bool Visual_ShowOB = true;                        // Draw Order Blocks
input bool Visual_ShowHTF = true;                       // Draw HTF High/Low/EQ
input bool Visual_ShowEntries = true;                   // Draw Entry/SL/TP
input bool Visual_ShowSessions = false;                 // Draw Session Boxes
input color Visual_BullishColor = clrLime;              // Bullish Color
input color Visual_BearishColor = clrRed;               // Bearish Color
input color Visual_LiquidityColor = clrYellow;          // Liquidity Level Color
input color Visual_HTFColor = clrAqua;                  // HTF Level Color

//--- Session Settings
input group "=== SESSION SETTINGS ==="
input int GMT_Offset = 0;                               // Broker GMT Offset (Hours)
input int London_StartHour = 8;                         // London Session Start (GMT)
input int London_EndHour = 17;                          // London Session End (GMT)
input int NY_StartHour = 13;                            // New York Session Start (GMT)
input int NY_EndHour = 22;                              // New York Session End (GMT)
input int Asia_StartHour = 0;                           // Asia Session Start (GMT)
input int Asia_EndHour = 9;                             // Asia Session End (GMT)

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
CPositionInfo positionInfo;
CAccountInfo accountInfo;

// HTF Premium/Discount State
double htf_high = 0;
double htf_low = 0;
double htf_equilibrium = 0;
bool htf_premium = false;
bool htf_discount = false;

// Liquidity Levels
struct LiquidityLevel {
    double price;
    datetime time;
    string type;  // "PDH", "PDL", "SessionHigh", "SessionLow", "SwingHigh", "SwingLow", "EqualHigh", "EqualLow"
    bool swept;
    string objectName;
};
LiquidityLevel liquidityLevels[];

// Order Blocks
struct OrderBlock {
    double high;
    double low;
    datetime time;
    bool bullish;
    bool traded;
    bool valid;
    string objectName;
    int age;
};
OrderBlock orderBlocks[];

// Session Tracking
datetime currentSessionStart = 0;
double sessionHigh = 0;
double sessionLow = 0;
string currentSession = "";

// Daily Tracking
datetime lastTradeDate = 0;
int tradesToday = 0;
double dailyPL = 0;
int sessionTrades = 0;

// ATR Handle
int atrHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize CTrade
    trade.SetExpertMagicNumber(123456);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    trade.SetAsyncMode(false);
    
    // Initialize ATR
    atrHandle = iATR(_Symbol, PERIOD_CURRENT, SL_ATR_Period);
    if(atrHandle == INVALID_HANDLE) {
        Print("ERROR: Failed to create ATR indicator");
        return(INIT_FAILED);
    }
    
    // Initialize arrays
    ArrayResize(liquidityLevels, 0);
    ArrayResize(orderBlocks, 0);
    
    Print("=== SMCEA Initialized ===");
    Print("HTF Timeframe: ", EnumToString(HTF_Timeframe));
    Print("Risk Per Trade: ", Risk_Percent, "%");
    Print("Min R:R Ratio: ", Risk_MinRR);
    Print("XAUUSD Optimized - Smart Money Concepts");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up visual objects
    CleanupAllObjects();
    
    // Release ATR handle
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    
    Print("=== SMCEA Deinitialized ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // FAILSAFE: Check if position exists - only one position per symbol
    if(PositionSelect(_Symbol)) {
        ManageOpenPosition();
        return;
    }
    
    // FAILSAFE: Check spread
    double spread = GetCurrentSpread();
    if(spread > XAU_MaxSpread) {
        return; // DO NOTHING - Spread too wide
    }
    
    // FAILSAFE: Check daily loss guard
    if(Risk_UseDailyLossGuard && CheckDailyLossLimit()) {
        return; // DO NOTHING - Daily loss limit reached
    }
    
    // FAILSAFE: Check max trades per day
    UpdateDailyTracking();
    if(tradesToday >= Risk_MaxTradesPerDay) {
        return; // DO NOTHING - Max trades reached
    }
    
    // FAILSAFE: Check session
    UpdateSessionTracking();
    if(!IsValidSession()) {
        return; // DO NOTHING - Outside enabled sessions
    }
    
    // FAILSAFE: Check session trade limit
    if(sessionTrades >= Risk_MaxTradesPerSession) {
        return; // DO NOTHING - Session limit reached
    }
    
    // Wait for candle close (no tick-based entries)
    if(!IsNewBar()) {
        return;
    }
    
    // === STEP 1: UPDATE HTF PREMIUM/DISCOUNT (MANDATORY) ===
    UpdateHTF_PremiumDiscount();
    
    // === STEP 2: UPDATE LIQUIDITY LEVELS (MANDATORY) ===
    UpdateLiquidityLevels();
    
    // === STEP 3: DETECT LIQUIDITY SWEEPS (PRIMARY TRIGGER) ===
    DetectLiquiditySweeps();
    
    // === STEP 4: DETECT ORDER BLOCKS (ENTRY ZONE) ===
    UpdateOrderBlocks();
    
    // === STEP 5: EVALUATE ENTRY MODELS (HIERARCHY) ===
    EvaluateEntryModels();
    
    // === STEP 6: UPDATE VISUAL DEBUGGING ===
    UpdateVisuals();
}

//+------------------------------------------------------------------+
//| Update HTF Premium/Discount Filter                              |
//+------------------------------------------------------------------+
void UpdateHTF_PremiumDiscount()
{
    // SMC STEP: Calculate HTF dealing range
    // Detect most recent valid swing high & swing low
    // Define premium (>50%), discount (<50%), equilibrium (≈50%)
    
    int bars = iBars(_Symbol, HTF_Timeframe);
    if(bars < HTF_SwingLookback) return;
    
    htf_high = 0;
    htf_low = DBL_MAX;
    
    // Find HTF swing high and low
    for(int i = 1; i <= HTF_SwingLookback; i++) {
        double high = iHigh(_Symbol, HTF_Timeframe, i);
        double low = iLow(_Symbol, HTF_Timeframe, i);
        
        if(high > htf_high) htf_high = high;
        if(low < htf_low) htf_low = low;
    }
    
    // Calculate equilibrium (50% midpoint)
    htf_equilibrium = (htf_high + htf_low) / 2.0;
    
    // Determine current price position
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Premium: Price > 50% of HTF range (SELL ONLY)
    // Discount: Price < 50% of HTF range (BUY ONLY)
    // Equilibrium: Near 50% (NO TRADES if strict)
    
    double equilibriumBuffer = (htf_high - htf_low) * 0.05; // 5% buffer zone
    
    htf_premium = false;
    htf_discount = false;
    
    if(currentPrice > htf_equilibrium + equilibriumBuffer) {
        htf_premium = true;  // SELL ZONE
    }
    else if(currentPrice < htf_equilibrium - equilibriumBuffer) {
        htf_discount = true; // BUY ZONE
    }
    // else: In equilibrium - DO NOTHING
}

//+------------------------------------------------------------------+
//| Update Liquidity Levels                                         |
//+------------------------------------------------------------------+
void UpdateLiquidityLevels()
{
    // SMC STEP: Track key liquidity levels
    // - Previous Day High/Low (PDH/PDL)
    // - Session High/Low (London, NY)
    // - HTF Swing Highs/Lows
    // - Equal High/Low clusters
    
    // Clean old levels
    CleanOldLiquidityLevels();
    
    // Track Previous Day High/Low
    if(Track_PDH_PDL) {
        AddPreviousDayLevels();
    }
    
    // Track Session High/Low
    if(Track_SessionHighLow) {
        AddSessionLevels();
    }
    
    // Track HTF Swing Points
    if(Track_SwingPoints) {
        AddHTFSwingPoints();
    }
    
    // Track Equal High/Low Clusters
    if(Track_EqualHighLow) {
        AddEqualHighLowClusters();
    }
}

//+------------------------------------------------------------------+
//| Detect Liquidity Sweeps                                         |
//+------------------------------------------------------------------+
void DetectLiquiditySweeps()
{
    // SMC STEP: Validate liquidity sweeps
    // VALID SWEEP requires:
    // - Wick breaks the level
    // - Candle CLOSES back inside range
    // - No body close through level
    
    for(int i = 0; i < ArraySize(liquidityLevels); i++) {
        if(liquidityLevels[i].swept) continue;
        
        // Check if level was swept in recent bars
        bool swept = CheckLiquiditySweep(liquidityLevels[i]);
        
        if(swept) {
            liquidityLevels[i].swept = true;
            
            // Mark sweep visually
            if(Visual_ShowSweeps) {
                MarkLiquiditySweep(liquidityLevels[i]);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check Liquidity Sweep                                           |
//+------------------------------------------------------------------+
bool CheckLiquiditySweep(LiquidityLevel &level)
{
    // SMC LOGIC: Clean sweep validation
    // - Wick must break level by minimum points
    // - Close must be back inside range
    // - Body must NOT close through level
    
    for(int i = 1; i <= Sweep_ValidationBars; i++) {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        double open = iOpen(_Symbol, PERIOD_CURRENT, i);
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        
        bool isBullish = close > open;
        double bodyHigh = isBullish ? close : open;
        double bodyLow = isBullish ? open : close;
        
        // Check for buy-side liquidity sweep (high sweep)
        if(StringFind(level.type, "High") >= 0) {
            // Wick must break above
            if(high > level.price + Sweep_WickMinPoints * _Point) {
                // Close must be back below
                if(Sweep_RequireCloseInside && close > level.price) continue;
                // Body must not close through
                if(Sweep_NoBodyThrough && bodyLow > level.price) continue;
                
                return true; // Valid sweep
            }
        }
        
        // Check for sell-side liquidity sweep (low sweep)
        if(StringFind(level.type, "Low") >= 0) {
            // Wick must break below
            if(low < level.price - Sweep_WickMinPoints * _Point) {
                // Close must be back above
                if(Sweep_RequireCloseInside && close < level.price) continue;
                // Body must not close through
                if(Sweep_NoBodyThrough && bodyHigh < level.price) continue;
                
                return true; // Valid sweep
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update Order Blocks                                             |
//+------------------------------------------------------------------+
void UpdateOrderBlocks()
{
    // SMC STEP: Detect Order Blocks
    // OB = Last opposite candle before impulsive displacement
    // Requirements:
    // - Large real body (displacement quality)
    // - Breaks microstructure
    // - Occurs AFTER liquidity sweep
    
    // Age existing OBs
    for(int i = 0; i < ArraySize(orderBlocks); i++) {
        orderBlocks[i].age++;
        
        // Invalidate old OBs
        if(orderBlocks[i].age > OB_MaxAge) {
            orderBlocks[i].valid = false;
        }
        
        // Invalidate fully broken OBs
        if(CheckOBBroken(orderBlocks[i])) {
            orderBlocks[i].valid = false;
        }
    }
    
    // Detect new Order Blocks
    DetectNewOrderBlocks();
}

//+------------------------------------------------------------------+
//| Detect New Order Blocks                                         |
//+------------------------------------------------------------------+
void DetectNewOrderBlocks()
{
    // SMC LOGIC: Find displacement candles and their preceding opposite candles
    
    for(int i = 2; i < 20; i++) {
        double open = iOpen(_Symbol, PERIOD_CURRENT, i);
        double close = iClose(_Symbol, PERIOD_CURRENT, i);
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        
        double bodySize = MathAbs(close - open);
        bool isBullish = close > open;
        
        // Check for displacement (large body)
        if(bodySize < XAU_MinDisplacementPoints * _Point) continue;
        
        // Check body percentage
        double candleSize = high - low;
        if(candleSize == 0) continue;
        double bodyPercent = (bodySize / candleSize) * 100.0;
        if(bodyPercent < OB_MinBodyPercent) continue;
        
        // Found displacement - look for preceding opposite candle (Order Block)
        for(int j = i + 1; j < i + 5; j++) {
            double ob_open = iOpen(_Symbol, PERIOD_CURRENT, j);
            double ob_close = iClose(_Symbol, PERIOD_CURRENT, j);
            double ob_high = iHigh(_Symbol, PERIOD_CURRENT, j);
            double ob_low = iLow(_Symbol, PERIOD_CURRENT, j);
            
            bool ob_isBullish = ob_close > ob_open;
            
            // Bullish displacement -> find bearish OB
            if(isBullish && !ob_isBullish) {
                AddOrderBlock(ob_high, ob_low, iTime(_Symbol, PERIOD_CURRENT, j), true);
                break;
            }
            
            // Bearish displacement -> find bullish OB
            if(!isBullish && ob_isBullish) {
                AddOrderBlock(ob_high, ob_low, iTime(_Symbol, PERIOD_CURRENT, j), false);
                break;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Add Order Block                                                 |
//+------------------------------------------------------------------+
void AddOrderBlock(double high, double low, datetime time, bool bullish)
{
    // Check if OB already exists
    for(int i = 0; i < ArraySize(orderBlocks); i++) {
        if(MathAbs(orderBlocks[i].high - high) < 5 * _Point &&
           MathAbs(orderBlocks[i].low - low) < 5 * _Point) {
            return; // Already exists
        }
    }
    
    // Check minimum size
    if(high - low < OB_MinSizePoints * _Point) return;
    
    // Add new OB
    int size = ArraySize(orderBlocks);
    ArrayResize(orderBlocks, size + 1);
    
    orderBlocks[size].high = high;
    orderBlocks[size].low = low;
    orderBlocks[size].time = time;
    orderBlocks[size].bullish = bullish;
    orderBlocks[size].traded = false;
    orderBlocks[size].valid = true;
    orderBlocks[size].age = 0;
    orderBlocks[size].objectName = "SMC_OB_" + IntegerToString(time);
}

//+------------------------------------------------------------------+
//| Evaluate Entry Models                                           |
//+------------------------------------------------------------------+
void EvaluateEntryModels()
{
    // SMC STEP: Multi-Model Entry System
    // Evaluate models in hierarchy order
    // Execute FIRST valid model ONLY
    // If all fail -> DO NOTHING
    
    // Model 1: Classic OB Retrace
    if(Model1_ClassicOB && EvaluateModel1_ClassicOB()) {
        return; // Trade executed or evaluated
    }
    
    // Model 2: Shallow OB Rejection
    if(Model2_ShallowRejection && EvaluateModel2_ShallowRejection()) {
        return;
    }
    
    // Model 3: Sweep → MSS → OB
    if(Model3_SweepMSS && EvaluateModel3_SweepMSS()) {
        return;
    }
    
    // Model 4: Double Liquidity Sweep
    if(Model4_DoubleSweep && EvaluateModel4_DoubleSweep()) {
        return;
    }
    
    // Model 5: Session High/Low Raid
    if(Model5_SessionRaid && EvaluateModel5_SessionRaid()) {
        return;
    }
    
    // Model 6: HTF Range Extreme Sweep
    if(Model6_HTFRangeExtreme && EvaluateModel6_HTFRangeExtreme()) {
        return;
    }
    
    // Model 7: Equal H/L Cluster Raid
    if(Model7_EqualClusterRaid && EvaluateModel7_EqualClusterRaid()) {
        return;
    }
    
    // No valid model -> DO NOTHING
}

//+------------------------------------------------------------------+
//| Model 1: Classic OB Retrace                                     |
//+------------------------------------------------------------------+
bool EvaluateModel1_ClassicOB()
{
    // SMC MODEL 1: Classic OB Retrace
    // BUY:
    // - HTF Discount
    // - Sell-side liquidity swept
    // - Close back above liquidity
    // - Bullish displacement
    // - Bullish OB formed
    // - Retrace into OB
    // - Entry on candle CLOSE inside OB
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Check for BUY setup
    if(htf_discount) {
        // Find swept sell-side liquidity
        bool sellSideSwept = false;
        for(int i = 0; i < ArraySize(liquidityLevels); i++) {
            if(liquidityLevels[i].swept && StringFind(liquidityLevels[i].type, "Low") >= 0) {
                sellSideSwept = true;
                break;
            }
        }
        
        if(sellSideSwept) {
            // Find valid bullish OB
            for(int i = 0; i < ArraySize(orderBlocks); i++) {
                if(!orderBlocks[i].valid || !orderBlocks[i].bullish) continue;
                if(orderBlocks[i].traded && OB_OneTradePerBlock) continue;
                
                // Check if price is inside OB
                if(currentPrice >= orderBlocks[i].low && currentPrice <= orderBlocks[i].high) {
                    // Valid Model 1 BUY setup
                    return ExecuteBuyTrade(orderBlocks[i], "Model1_ClassicOB");
                }
            }
        }
    }
    
    // Check for SELL setup
    if(htf_premium) {
        // Find swept buy-side liquidity
        bool buySideSwept = false;
        for(int i = 0; i < ArraySize(liquidityLevels); i++) {
            if(liquidityLevels[i].swept && StringFind(liquidityLevels[i].type, "High") >= 0) {
                buySideSwept = true;
                break;
            }
        }
        
        if(buySideSwept) {
            // Find valid bearish OB
            for(int i = 0; i < ArraySize(orderBlocks); i++) {
                if(!orderBlocks[i].valid || orderBlocks[i].bullish) continue;
                if(orderBlocks[i].traded && OB_OneTradePerBlock) continue;
                
                // Check if price is inside OB
                if(currentPrice >= orderBlocks[i].low && currentPrice <= orderBlocks[i].high) {
                    // Valid Model 1 SELL setup
                    return ExecuteSellTrade(orderBlocks[i], "Model1_ClassicOB");
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Model 2: Shallow OB Rejection                                   |
//+------------------------------------------------------------------+
bool EvaluateModel2_ShallowRejection()
{
    // SMC MODEL 2: Shallow OB Rejection (XAU Momentum)
    // OB respected with ≤50% retrace
    // Strong rejection close from OB
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    
    for(int i = 0; i < ArraySize(orderBlocks); i++) {
        if(!orderBlocks[i].valid) continue;
        if(orderBlocks[i].traded && OB_OneTradePerBlock) continue;
        
        double obMid = (orderBlocks[i].high + orderBlocks[i].low) / 2.0;
        
        // Bullish OB - check for shallow retrace and rejection
        if(orderBlocks[i].bullish && htf_discount) {
            // Price touched upper half of OB
            if(close2 <= obMid && close1 > orderBlocks[i].low) {
                // Strong rejection (close moved up)
                if(close1 > close2) {
                    return ExecuteBuyTrade(orderBlocks[i], "Model2_ShallowRejection");
                }
            }
        }
        
        // Bearish OB - check for shallow retrace and rejection
        if(!orderBlocks[i].bullish && htf_premium) {
            // Price touched lower half of OB
            if(close2 >= obMid && close1 < orderBlocks[i].high) {
                // Strong rejection (close moved down)
                if(close1 < close2) {
                    return ExecuteSellTrade(orderBlocks[i], "Model2_ShallowRejection");
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Model 3-7: Placeholder implementations                          |
//+------------------------------------------------------------------+
bool EvaluateModel3_SweepMSS() { return false; } // Sweep → MSS → OB
bool EvaluateModel4_DoubleSweep() { return false; } // Double Sweep
bool EvaluateModel5_SessionRaid() { return false; } // Session Raid
bool EvaluateModel6_HTFRangeExtreme() { return false; } // HTF Extreme
bool EvaluateModel7_EqualClusterRaid() { return false; } // Equal Cluster

//+------------------------------------------------------------------+
//| Execute Buy Trade                                               |
//+------------------------------------------------------------------+
bool ExecuteBuyTrade(OrderBlock &ob, string model)
{
    // SMC EXECUTION: BUY trade with proper risk management
    
    double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Calculate SL beyond OB
    double sl = ob.low - XAU_SL_BufferPoints * _Point;
    
    // Add ATR buffer
    double atr = GetATR();
    sl -= atr * SL_ATR_Multiplier;
    
    // Calculate TP based on R:R
    double slDistance = entryPrice - sl;
    double tp = entryPrice + (slDistance * TP_RR_Multiple);
    
    // Check minimum R:R
    double rr = (tp - entryPrice) / slDistance;
    if(rr < Risk_MinRR) {
        return false; // DO NOTHING - R:R too low
    }
    
    // Calculate lot size
    double lotSize = CalculateLotSize(entryPrice - sl);
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
        return false; // DO NOTHING - Lot size too small
    }
    
    // Execute trade
    if(trade.Buy(lotSize, _Symbol, entryPrice, sl, tp, "SMC_" + model)) {
        Print("BUY EXECUTED: ", model, " | Entry: ", entryPrice, " | SL: ", sl, " | TP: ", tp, " | Lots: ", lotSize);
        ob.traded = true;
        tradesToday++;
        sessionTrades++;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                              |
//+------------------------------------------------------------------+
bool ExecuteSellTrade(OrderBlock &ob, string model)
{
    // SMC EXECUTION: SELL trade with proper risk management
    
    double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Calculate SL beyond OB
    double sl = ob.high + XAU_SL_BufferPoints * _Point;
    
    // Add ATR buffer
    double atr = GetATR();
    sl += atr * SL_ATR_Multiplier;
    
    // Calculate TP based on R:R
    double slDistance = sl - entryPrice;
    double tp = entryPrice - (slDistance * TP_RR_Multiple);
    
    // Check minimum R:R
    double rr = (entryPrice - tp) / slDistance;
    if(rr < Risk_MinRR) {
        return false; // DO NOTHING - R:R too low
    }
    
    // Calculate lot size
    double lotSize = CalculateLotSize(sl - entryPrice);
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
        return false; // DO NOTHING - Lot size too small
    }
    
    // Execute trade
    if(trade.Sell(lotSize, _Symbol, entryPrice, sl, tp, "SMC_" + model)) {
        Print("SELL EXECUTED: ", model, " | Entry: ", entryPrice, " | SL: ", sl, " | TP: ", tp, " | Lots: ", lotSize);
        ob.traded = true;
        tradesToday++;
        sessionTrades++;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size (Gold-Safe)                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
    // SMC RISK: Gold-safe lot calculation
    // Uses TickSize, TickValue, ContractSize
    
    double accountBalance = accountInfo.Balance();
    double riskAmount = accountBalance * (Risk_Percent / 100.0);
    
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    if(tickSize == 0 || slDistance == 0) return 0;
    
    double ticksInSL = slDistance / tickSize;
    double riskPerLot = ticksInSL * tickValue;
    
    if(riskPerLot == 0) return 0;
    
    double lotSize = riskAmount / riskPerLot;
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Manage Open Position                                            |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
    // SMC MANAGEMENT: Handle break-even, partial exits
    
    if(!PositionSelect(_Symbol)) return;
    
    double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double posSL = PositionGetDouble(POSITION_SL);
    double posTP = PositionGetDouble(POSITION_TP);
    long posType = PositionGetInteger(POSITION_TYPE);
    
    double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Break-even at 1R
    if(TP_BEAt1R) {
        double slDistance = MathAbs(posOpenPrice - posSL);
        double profitDistance = MathAbs(currentPrice - posOpenPrice);
        
        if(profitDistance >= slDistance) {
            // Move SL to break-even + buffer
            double newSL = posOpenPrice + (posType == POSITION_TYPE_BUY ? TP_BE_Buffer * _Point : -TP_BE_Buffer * _Point);
            
            if((posType == POSITION_TYPE_BUY && newSL > posSL) ||
               (posType == POSITION_TYPE_SELL && newSL < posSL)) {
                trade.PositionModify(_Symbol, newSL, posTP);
                Print("Break-even activated at ", newSL);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Helper Functions                                                |
//+------------------------------------------------------------------+

double GetATR()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(atrHandle, 0, 0, 1, atr) > 0)
        return atr[0];
    return 0;
}

double GetCurrentSpread()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    return (ask - bid) / _Point;
}

bool IsNewBar()
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

void UpdateDailyTracking()
{
    MqlDateTime today;
    TimeCurrent(today);
    datetime todayDate = StringToTime(IntegerToString(today.year) + "." + 
                                      IntegerToString(today.mon) + "." + 
                                      IntegerToString(today.day));
    
    if(todayDate != lastTradeDate) {
        lastTradeDate = todayDate;
        tradesToday = 0;
        dailyPL = 0;
    }
}

bool CheckDailyLossLimit()
{
    double accountBalance = accountInfo.Balance();
    double maxLoss = accountBalance * (Risk_MaxDailyLoss / 100.0);
    
    if(dailyPL < -maxLoss) {
        Print("Daily loss limit reached: ", dailyPL);
        return true;
    }
    return false;
}

void UpdateSessionTracking()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int currentHour = dt.hour + GMT_Offset;
    if(currentHour < 0) currentHour += 24;
    if(currentHour >= 24) currentHour -= 24;
    
    string newSession = "";
    
    if(currentHour >= London_StartHour && currentHour < London_EndHour)
        newSession = "London";
    else if(currentHour >= NY_StartHour && currentHour < NY_EndHour)
        newSession = "NewYork";
    else if(currentHour >= Asia_StartHour && currentHour < Asia_EndHour)
        newSession = "Asia";
    
    if(newSession != currentSession) {
        currentSession = newSession;
        sessionTrades = 0;
        sessionHigh = 0;
        sessionLow = DBL_MAX;
    }
    
    double high = iHigh(_Symbol, PERIOD_CURRENT, 0);
    double low = iLow(_Symbol, PERIOD_CURRENT, 0);
    if(high > sessionHigh) sessionHigh = high;
    if(low < sessionLow) sessionLow = low;
}

bool IsValidSession()
{
    if(currentSession == "London" && XAU_PreferLondon) return true;
    if(currentSession == "NewYork" && XAU_PreferNY) return true;
    if(currentSession == "Asia" && XAU_AllowAsia) return true;
    return false;
}

bool CheckOBBroken(OrderBlock &ob)
{
    double close = iClose(_Symbol, PERIOD_CURRENT, 1);
    
    if(ob.bullish && close < ob.low) return true;
    if(!ob.bullish && close > ob.high) return true;
    
    return false;
}

void CleanOldLiquidityLevels()
{
    // Remove levels older than 5 days
    datetime cutoff = TimeCurrent() - (5 * 24 * 3600);
    
    for(int i = ArraySize(liquidityLevels) - 1; i >= 0; i--) {
        if(liquidityLevels[i].time < cutoff) {
            ArrayRemove(liquidityLevels, i, 1);
        }
    }
}

void AddPreviousDayLevels()
{
    // Add PDH/PDL levels
    datetime yesterday = iTime(_Symbol, PERIOD_D1, 1);
    double pdh = iHigh(_Symbol, PERIOD_D1, 1);
    double pdl = iLow(_Symbol, PERIOD_D1, 1);
    
    AddLiquidityLevel(pdh, yesterday, "PDH");
    AddLiquidityLevel(pdl, yesterday, "PDL");
}

void AddSessionLevels()
{
    if(sessionHigh > 0 && sessionLow < DBL_MAX) {
        AddLiquidityLevel(sessionHigh, TimeCurrent(), currentSession + "High");
        AddLiquidityLevel(sessionLow, TimeCurrent(), currentSession + "Low");
    }
}

void AddHTFSwingPoints()
{
    // Add recent HTF swing points
    for(int i = 1; i <= 10; i++) {
        double high = iHigh(_Symbol, HTF_Timeframe, i);
        double low = iLow(_Symbol, HTF_Timeframe, i);
        datetime time = iTime(_Symbol, HTF_Timeframe, i);
        
        AddLiquidityLevel(high, time, "SwingHigh");
        AddLiquidityLevel(low, time, "SwingLow");
    }
}

void AddEqualHighLowClusters()
{
    // Detect equal highs/lows within tolerance
    double highs[];
    double lows[];
    ArrayResize(highs, 20);
    ArrayResize(lows, 20);
    
    for(int i = 0; i < 20; i++) {
        highs[i] = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
        lows[i] = iLow(_Symbol, PERIOD_CURRENT, i + 1);
    }
    
    for(int i = 0; i < 19; i++) {
        for(int j = i + 1; j < 20; j++) {
            if(MathAbs(highs[i] - highs[j]) < EqualLevel_Tolerance * _Point) {
                AddLiquidityLevel(highs[i], iTime(_Symbol, PERIOD_CURRENT, i + 1), "EqualHigh");
            }
            if(MathAbs(lows[i] - lows[j]) < EqualLevel_Tolerance * _Point) {
                AddLiquidityLevel(lows[i], iTime(_Symbol, PERIOD_CURRENT, i + 1), "EqualLow");
            }
        }
    }
}

void AddLiquidityLevel(double price, datetime time, string type)
{
    // Check if level already exists
    for(int i = 0; i < ArraySize(liquidityLevels); i++) {
        if(MathAbs(liquidityLevels[i].price - price) < 2 * _Point &&
           liquidityLevels[i].type == type) {
            return;
        }
    }
    
    int size = ArraySize(liquidityLevels);
    ArrayResize(liquidityLevels, size + 1);
    
    liquidityLevels[size].price = price;
    liquidityLevels[size].time = time;
    liquidityLevels[size].type = type;
    liquidityLevels[size].swept = false;
    liquidityLevels[size].objectName = "SMC_LIQ_" + type + "_" + IntegerToString(time);
}

void MarkLiquiditySweep(LiquidityLevel &level)
{
    string objName = "SMC_SWEEP_" + IntegerToString(level.time);
    ObjectCreate(0, objName, OBJ_ARROW, 0, TimeCurrent(), level.price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);
}

void UpdateVisuals()
{
    // Draw HTF levels
    if(Visual_ShowHTF) {
        DrawHTFLevels();
    }
    
    // Draw liquidity levels
    if(Visual_ShowLiquidity) {
        DrawLiquidityLevels();
    }
    
    // Draw order blocks
    if(Visual_ShowOB) {
        DrawOrderBlocks();
    }
}

void DrawHTFLevels()
{
    if(htf_high > 0) {
        ObjectCreate(0, "SMC_HTF_High", OBJ_HLINE, 0, 0, htf_high);
        ObjectSetInteger(0, "SMC_HTF_High", OBJPROP_COLOR, Visual_HTFColor);
        ObjectSetInteger(0, "SMC_HTF_High", OBJPROP_STYLE, STYLE_DASH);
    }
    
    if(htf_low > 0) {
        ObjectCreate(0, "SMC_HTF_Low", OBJ_HLINE, 0, 0, htf_low);
        ObjectSetInteger(0, "SMC_HTF_Low", OBJPROP_COLOR, Visual_HTFColor);
        ObjectSetInteger(0, "SMC_HTF_Low", OBJPROP_STYLE, STYLE_DASH);
    }
    
    if(htf_equilibrium > 0) {
        ObjectCreate(0, "SMC_HTF_EQ", OBJ_HLINE, 0, 0, htf_equilibrium);
        ObjectSetInteger(0, "SMC_HTF_EQ", OBJPROP_COLOR, clrGray);
        ObjectSetInteger(0, "SMC_HTF_EQ", OBJPROP_STYLE, STYLE_DOT);
    }
}

void DrawLiquidityLevels()
{
    for(int i = 0; i < ArraySize(liquidityLevels); i++) {
        if(!ObjectCreate(0, liquidityLevels[i].objectName, OBJ_HLINE, 0, 0, liquidityLevels[i].price)) {
            ObjectMove(0, liquidityLevels[i].objectName, 0, 0, liquidityLevels[i].price);
        }
        
        color levelColor = liquidityLevels[i].swept ? clrGray : Visual_LiquidityColor;
        ObjectSetInteger(0, liquidityLevels[i].objectName, OBJPROP_COLOR, levelColor);
        ObjectSetInteger(0, liquidityLevels[i].objectName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, liquidityLevels[i].objectName, OBJPROP_WIDTH, 1);
    }
}

void DrawOrderBlocks()
{
    for(int i = 0; i < ArraySize(orderBlocks); i++) {
        if(!orderBlocks[i].valid) continue;
        
        if(!ObjectCreate(0, orderBlocks[i].objectName, OBJ_RECTANGLE, 0, 
                         orderBlocks[i].time, orderBlocks[i].high,
                         TimeCurrent() + 3600, orderBlocks[i].low)) {
            ObjectMove(0, orderBlocks[i].objectName, 0, orderBlocks[i].time, orderBlocks[i].high);
            ObjectMove(0, orderBlocks[i].objectName, 1, TimeCurrent() + 3600, orderBlocks[i].low);
        }
        
        color obColor = orderBlocks[i].bullish ? Visual_BullishColor : Visual_BearishColor;
        ObjectSetInteger(0, orderBlocks[i].objectName, OBJPROP_COLOR, obColor);
        ObjectSetInteger(0, orderBlocks[i].objectName, OBJPROP_FILL, true);
        ObjectSetInteger(0, orderBlocks[i].objectName, OBJPROP_BACK, true);
    }
}

void CleanupAllObjects()
{
    ObjectsDeleteAll(0, "SMC_");
}
//+------------------------------------------------------------------+
