//+------------------------------------------------------------------+
//|                                          XAUUSDScalpingEA.mq5    |
//|                                  Advanced XAUUSD Scalping EA     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "XAUUSD Scalping EA"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Input Parameters
//--- Risk Management
input group "=== Risk Management ==="
input double RiskPercentage = 1.0;           // Risk per trade (%)
input double MaxDailyLossPercent = 5.0;      // Maximum daily loss (%)
input double MaxSpreadPoints = 50;           // Maximum spread in points

//--- Indicator Settings
input group "=== Indicator Settings ==="
input int MACD_Fast = 12;                    // MACD Fast EMA
input int MACD_Slow = 26;                    // MACD Slow EMA
input int MACD_Signal = 9;                   // MACD Signal
input int BB_Period = 20;                    // Bollinger Bands Period
input double BB_Deviation = 2.0;             // Bollinger Bands Deviation
input int ATR_Period = 14;                   // ATR Period for volatility
input bool UseRSI = true;                    // Use RSI filter
input int RSI_Period = 14;                   // RSI Period
input double RSI_Overbought = 70.0;          // RSI Overbought Level
input double RSI_Oversold = 30.0;            // RSI Oversold Level

//--- Take Profit and Stop Loss
input group "=== Trade Settings ==="
input double TP_ATR_Multiplier = 1.5;        // Take Profit ATR Multiplier
input double SL_ATR_Multiplier = 1.0;        // Stop Loss ATR Multiplier
input double MinStopLossPoints = 30;         // Minimum Stop Loss in points
input double MinRiskRewardRatio = 1.5;       // Minimum Risk/Reward Ratio
input bool UseTrailingStop = true;           // Use Trailing Stop
input double TrailingStopATR = 1.0;          // Trailing Stop ATR Multiplier
input double TrailingStepATR = 0.5;          // Trailing Step ATR Multiplier

//--- Trading Sessions
input group "=== Trading Sessions ==="
input bool TradeLondonSession = true;        // Trade London Session (08:00-17:00 GMT)
input bool TradeNewYorkSession = true;       // Trade New York Session (13:00-22:00 GMT)
input int LondonStartHour = 8;               // London Session Start Hour
input int LondonEndHour = 17;                // London Session End Hour
input int NewYorkStartHour = 13;             // New York Session Start Hour
input int NewYorkEndHour = 22;               // New York Session End Hour

//--- News Filter
input group "=== News Filter ==="
input bool UseNewsFilter = true;             // Use News Filter
input int NewsBufferMinutes = 30;            // Minutes before/after news to avoid trading

//--- Scalping Settings
input group "=== Scalping Settings ==="
input int MinProfitPoints = 20;              // Minimum profit in points to consider exit
input bool UseMeanReversion = true;          // Use mean reversion exits
input int MaxPositions = 1;                  // Maximum concurrent positions

//--- GUI Settings
input group "=== GUI Settings ==="
input bool ShowPanel = true;                 // Show Information Panel
input int PanelX = 20;                       // Panel X Position
input int PanelY = 50;                       // Panel Y Position
input color PanelColor = clrNavy;            // Panel Background Color
input color TextColor = clrWhite;            // Panel Text Color

//--- Global Variables
CTrade trade;
CPositionInfo positionInfo;
CAccountInfo accountInfo;

int macdHandle;
int bbHandle;
int atrHandle;
int rsiHandle;

double macdMain[], macdSignal[];
double bbUpper[], bbMiddle[], bbLower[];
double atrBuffer[];
double rsiBuffer[];

datetime lastBarTime;
datetime dailyStartTime;
double dailyStartBalance;
double dailyProfit = 0.0;
int dailyTrades = 0;
int dailyWins = 0;
int dailyLosses = 0;

bool tradingPaused = false;
string lastErrorMsg = "";

//--- Track processed deals to avoid counting same deal multiple times
ulong lastProcessedDeal = 0;

//--- News time arrays (simplified approach - user should update these)
datetime newsEvents[];
int newsEventsCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize indicators
    macdHandle = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    bbHandle = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    
    if(macdHandle == INVALID_HANDLE || bbHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }
    
    // Set array as series
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbMiddle, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(atrBuffer, true);
    ArraySetAsSeries(rsiBuffer, true);
    
    // Initialize daily tracking
    dailyStartTime = TimeCurrent();
    dailyStartBalance = accountInfo.Balance();
    
    // Create GUI panel
    if(ShowPanel)
        CreateInfoPanel();
    
    Print("XAUUSD Scalping EA initialized successfully");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicators
    IndicatorRelease(macdHandle);
    IndicatorRelease(bbHandle);
    IndicatorRelease(atrHandle);
    IndicatorRelease(rsiHandle);
    
    // Remove GUI objects
    DeleteInfoPanel();
    
    Print("XAUUSD Scalping EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new day
    CheckNewDay();
    
    // Update daily statistics from closed deals
    UpdateDailyStatistics();
    
    // Update indicators
    if(!UpdateIndicators())
        return;
    
    // Update GUI
    if(ShowPanel)
        UpdateInfoPanel();
    
    // Check if trading is paused
    if(tradingPaused)
    {
        ManageOpenPositions();
        return;
    }
    
    // Check daily loss limit
    if(!CheckDailyLossLimit())
    {
        tradingPaused = true;
        SendEANotification("Trading paused: Daily loss limit reached");
        return;
    }
    
    // Check trading session
    if(!IsWithinTradingSession())
        return;
    
    // Check news filter
    if(UseNewsFilter && IsNewsTime())
        return;
    
    // Check spread
    if(!CheckSpread())
        return;
    
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != lastBarTime);
    
    if(isNewBar)
    {
        lastBarTime = currentBarTime;
        
        // Check for entry signals
        if(CountOpenPositions() < MaxPositions)
        {
            int signal = GetEntrySignal();
            
            if(signal == 1) // Buy signal
            {
                ExecuteBuyOrder();
            }
            else if(signal == -1) // Sell signal
            {
                ExecuteSellOrder();
            }
        }
    }
    
    // Manage open positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Update indicator buffers                                         |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    // Copy MACD
    if(CopyBuffer(macdHandle, 0, 0, 3, macdMain) <= 0 ||
       CopyBuffer(macdHandle, 1, 0, 3, macdSignal) <= 0)
    {
        lastErrorMsg = "Failed to copy MACD data";
        return false;
    }
    
    // Copy Bollinger Bands
    if(CopyBuffer(bbHandle, 0, 0, 3, bbUpper) <= 0 ||
       CopyBuffer(bbHandle, 1, 0, 3, bbMiddle) <= 0 ||
       CopyBuffer(bbHandle, 2, 0, 3, bbLower) <= 0)
    {
        lastErrorMsg = "Failed to copy Bollinger Bands data";
        return false;
    }
    
    // Copy ATR
    if(CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) <= 0)
    {
        lastErrorMsg = "Failed to copy ATR data";
        return false;
    }
    
    // Copy RSI
    if(CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) <= 0)
    {
        lastErrorMsg = "Failed to copy RSI data";
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get entry signal based on indicators and price action            |
//+------------------------------------------------------------------+
int GetEntrySignal()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentPrice = (ask + bid) / 2.0;
    
    // Check for liquidity sweep and early entry
    bool bullishSweep = DetectLiquiditySweep(true);
    bool bearishSweep = DetectLiquiditySweep(false);
    
    // MACD conditions
    bool macdBullish = (macdMain[0] > macdSignal[0]) && (macdMain[1] <= macdSignal[1]);
    bool macdBearish = (macdMain[0] < macdSignal[0]) && (macdMain[1] >= macdSignal[1]);
    
    // Bollinger Bands conditions
    bool priceBelowLowerBB = currentPrice < bbLower[0];
    bool priceAboveUpperBB = currentPrice > bbUpper[0];
    bool priceNearLowerBB = (currentPrice - bbLower[0]) < (atrBuffer[0] * 0.5);
    bool priceNearUpperBB = (bbUpper[0] - currentPrice) < (atrBuffer[0] * 0.5);
    
    // RSI conditions
    bool rsiOversold = rsiBuffer[0] < RSI_Oversold;
    bool rsiOverbought = rsiBuffer[0] > RSI_Overbought;
    bool rsiNeutral = (rsiBuffer[0] >= RSI_Oversold && rsiBuffer[0] <= RSI_Overbought);
    
    // Volatility check - prefer trading in higher volatility
    bool highVolatility = atrBuffer[0] > atrBuffer[1] * 1.1;
    
    // Buy signal conditions
    // RSI filter: Only buy when RSI is oversold or neutral (not overbought)
    bool rsiBuyCondition = UseRSI ? (rsiOversold || rsiNeutral) : true;
    
    if((bullishSweep || (macdBullish && priceBelowLowerBB)) && 
       (priceNearLowerBB || priceBelowLowerBB) &&
       (highVolatility || bullishSweep) && // Prefer high volatility or strong sweep
       rsiBuyCondition) // RSI confirmation
    {
        return 1; // Buy
    }
    
    // Sell signal conditions
    // RSI filter: Only sell when RSI is overbought or neutral (not oversold)
    bool rsiSellCondition = UseRSI ? (rsiOverbought || rsiNeutral) : true;
    
    if((bearishSweep || (macdBearish && priceAboveUpperBB)) && 
       (priceNearUpperBB || priceAboveUpperBB) &&
       (highVolatility || bearishSweep) && // Prefer high volatility or strong sweep
       rsiSellCondition) // RSI confirmation
    {
        return -1; // Sell
    }
    
    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Detect liquidity sweep (stop hunt)                               |
//+------------------------------------------------------------------+
bool DetectLiquiditySweep(bool bullish)
{
    double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
    double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
    double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
    
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    
    double atr = atrBuffer[0];
    
    if(bullish)
    {
        // Look for bullish sweep: price breaks below previous low then reverses up
        bool brokeLow = low1 < low2;
        bool closedAbove = close1 > open1;
        bool strongReversal = (close1 - low1) > atr * 0.3;
        
        return (brokeLow && closedAbove && strongReversal);
    }
    else
    {
        // Look for bearish sweep: price breaks above previous high then reverses down
        bool brokeHigh = high1 > high2;
        bool closedBelow = close1 < open1;
        bool strongReversal = (high1 - close1) > atr * 0.3;
        
        return (brokeHigh && closedBelow && strongReversal);
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPoints)
{
    double balance = accountInfo.Balance();
    double riskAmount = balance * (RiskPercentage / 100.0);
    
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
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double atr = atrBuffer[0];
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate SL and TP with minimum distance validation
    double slDistance = atr * SL_ATR_Multiplier;
    double minSlDistance = MinStopLossPoints * point;
    
    // Ensure stop loss is not too tight
    if(slDistance < minSlDistance)
    {
        slDistance = minSlDistance;
        Print("Warning: ATR-based SL too tight, using minimum SL distance: ", MinStopLossPoints, " points");
    }
    
    double tpDistance = atr * TP_ATR_Multiplier;
    
    // Ensure TP is at least MinRiskRewardRatio times SL for good risk/reward
    if(tpDistance < slDistance * MinRiskRewardRatio)
    {
        tpDistance = slDistance * MinRiskRewardRatio;
        Print("Warning: Adjusting TP to maintain ", MinRiskRewardRatio, ":1 reward/risk ratio");
    }
    
    double sl = ask - slDistance;
    double tp = ask + tpDistance;
    
    // Calculate lot size
    double slPoints = slDistance / point;
    double lotSize = CalculateLotSize(slPoints);
    
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
    {
        lastErrorMsg = "Lot size too small";
        return;
    }
    
    // Execute trade
    trade.SetDeviationInPoints(10);
    
    if(trade.Buy(lotSize, _Symbol, ask, sl, tp, "XAUUSD Scalp Buy"))
    {
        dailyTrades++;
        Print(StringFormat("BUY order #%I64u executed at %.2f, SL: %.2f (%.1f pts), TP: %.2f (%.1f pts), Lot: %.2f", 
              trade.ResultOrder(), ask, sl, slDistance/point, tp, tpDistance/point, lotSize));
        SendEANotification(StringFormat("BUY order executed at %.2f, Lot: %.2f", ask, lotSize));
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
    double atr = atrBuffer[0];
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate SL and TP with minimum distance validation
    double slDistance = atr * SL_ATR_Multiplier;
    double minSlDistance = MinStopLossPoints * point;
    
    // Ensure stop loss is not too tight
    if(slDistance < minSlDistance)
    {
        slDistance = minSlDistance;
        Print("Warning: ATR-based SL too tight, using minimum SL distance: ", MinStopLossPoints, " points");
    }
    
    double tpDistance = atr * TP_ATR_Multiplier;
    
    // Ensure TP is at least MinRiskRewardRatio times SL for good risk/reward
    if(tpDistance < slDistance * MinRiskRewardRatio)
    {
        tpDistance = slDistance * MinRiskRewardRatio;
        Print("Warning: Adjusting TP to maintain ", MinRiskRewardRatio, ":1 reward/risk ratio");
    }
    
    double sl = bid + slDistance;
    double tp = bid - tpDistance;
    
    // Calculate lot size
    double slPoints = slDistance / point;
    double lotSize = CalculateLotSize(slPoints);
    
    if(lotSize < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
    {
        lastErrorMsg = "Lot size too small";
        return;
    }
    
    // Execute trade
    trade.SetDeviationInPoints(10);
    
    if(trade.Sell(lotSize, _Symbol, bid, sl, tp, "XAUUSD Scalp Sell"))
    {
        dailyTrades++;
        Print(StringFormat("SELL order #%I64u executed at %.2f, SL: %.2f (%.1f pts), TP: %.2f (%.1f pts), Lot: %.2f", 
              trade.ResultOrder(), bid, sl, slDistance/point, tp, tpDistance/point, lotSize));
        SendEANotification(StringFormat("SELL order executed at %.2f, Lot: %.2f", bid, lotSize));
    }
    else
    {
        lastErrorMsg = "Failed to execute SELL order: " + IntegerToString(trade.ResultRetcode());
        Print(lastErrorMsg);
    }
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, mean reversion exit)       |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() != _Symbol)
                continue;
            
            ulong ticket = positionInfo.Ticket();
            double openPrice = positionInfo.PriceOpen();
            double currentSL = positionInfo.StopLoss();
            double currentTP = positionInfo.TakeProfit();
            ENUM_POSITION_TYPE posType = positionInfo.PositionType();
            
            double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                                  SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            double profit = positionInfo.Profit();
            double profitPoints = 0;
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            
            if(posType == POSITION_TYPE_BUY)
            {
                profitPoints = (currentPrice - openPrice) / point;
            }
            else
            {
                profitPoints = (openPrice - currentPrice) / point;
            }
            
            // Trailing stop
            if(UseTrailingStop && profitPoints > MinProfitPoints)
            {
                ApplyTrailingStop(ticket, posType, currentPrice, currentSL);
            }
            
            // Mean reversion exit - only apply if sufficient profit
            if(UseMeanReversion && profitPoints > MinProfitPoints * 1.5)
            {
                if(CheckMeanReversionExit(posType))
                {
                    if(trade.PositionClose(ticket))
                    {
                        Print(StringFormat("Position #%I64u closed by mean reversion. Entry: %.2f, Exit: %.2f, Profit: %.2f points, $%.2f", 
                              ticket, openPrice, currentPrice, profitPoints, profit));
                        SendEANotification(StringFormat("Position #%I64u closed by mean reversion at profit: %.2f points", ticket, profitPoints));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE posType, double currentPrice, double currentSL)
{
    double atr = atrBuffer[0];
    double trailDistance = atr * TrailingStopATR;
    double trailStep = atr * TrailingStepATR;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Ensure minimum trailing distances to prevent too-tight trailing
    double minTrailDistance = MinStopLossPoints * point;
    if(trailDistance < minTrailDistance)
    {
        trailDistance = minTrailDistance;
    }
    
    double newSL = 0;
    
    if(posType == POSITION_TYPE_BUY)
    {
        newSL = currentPrice - trailDistance;
        
        // Only move SL up, never down, and only if improvement is significant
        if(newSL > currentSL + trailStep || currentSL == 0)
        {
            if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
            {
                Print(StringFormat("Position #%I64u: Trailing stop updated to %.2f (moved %.1f pts)", 
                      ticket, newSL, (newSL - currentSL)/point));
            }
        }
    }
    else // SELL
    {
        newSL = currentPrice + trailDistance;
        
        // Only move SL down, never up, and only if improvement is significant
        if(newSL < currentSL - trailStep || currentSL == 0)
        {
            if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
            {
                Print(StringFormat("Position #%I64u: Trailing stop updated to %.2f (moved %.1f pts)", 
                      ticket, newSL, (currentSL - newSL)/point));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check mean reversion exit condition                              |
//+------------------------------------------------------------------+
bool CheckMeanReversionExit(ENUM_POSITION_TYPE posType)
{
    double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Check if price is reverting to mean (middle BB)
    double bbMid = bbMiddle[0];
    double bbUpr = bbUpper[0];
    double bbLwr = bbLower[0];
    
    // Use larger threshold to avoid premature exits
    // Exit only when price crosses beyond the middle BB, not just approaches it
    double threshold = atrBuffer[0] * 0.3;
    
    if(posType == POSITION_TYPE_BUY)
    {
        // Exit buy only if price is significantly above middle BB or approaching upper BB
        // This prevents premature mean reversion exits
        bool crossedMiddle = (currentPrice > bbMid + threshold);
        bool nearUpperBB = (currentPrice > bbUpr - threshold);
        
        return (crossedMiddle || nearUpperBB);
    }
    else
    {
        // Exit sell only if price is significantly below middle BB or approaching lower BB
        // This prevents premature mean reversion exits
        bool crossedMiddle = (currentPrice < bbMid - threshold);
        bool nearLowerBB = (currentPrice < bbLwr + threshold);
        
        return (crossedMiddle || nearLowerBB);
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
//| Check if within trading session                                  |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeGMT(), timeStruct);
    int currentHour = timeStruct.hour;
    
    bool inLondon = false;
    bool inNewYork = false;
    
    if(TradeLondonSession)
    {
        inLondon = (currentHour >= LondonStartHour && currentHour < LondonEndHour);
    }
    
    if(TradeNewYorkSession)
    {
        inNewYork = (currentHour >= NewYorkStartHour && currentHour < NewYorkEndHour);
    }
    
    return (inLondon || inNewYork);
}

//+------------------------------------------------------------------+
//| Check if it's news time                                          |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    datetime currentTime = TimeCurrent();
    
    // Check against scheduled news events
    for(int i = 0; i < newsEventsCount; i++)
    {
        datetime newsTime = newsEvents[i];
        int diffMinutes = (int)((MathAbs(currentTime - newsTime)) / 60);
        
        if(diffMinutes <= NewsBufferMinutes)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check spread                                                      |
//+------------------------------------------------------------------+
bool CheckSpread()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    double spreadPoints = (ask - bid) / point;
    
    return (spreadPoints <= MaxSpreadPoints);
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
{
    double currentBalance = accountInfo.Balance();
    double dailyPL = currentBalance - dailyStartBalance;
    double maxLoss = dailyStartBalance * (MaxDailyLossPercent / 100.0);
    
    if(dailyPL < -maxLoss)
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update daily statistics from history                             |
//+------------------------------------------------------------------+
void UpdateDailyStatistics()
{
    // Check history for new closed deals
    HistorySelect(dailyStartTime, TimeCurrent());
    
    int totalDeals = HistoryDealsTotal();
    
    for(int i = 0; i < totalDeals; i++)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        
        if(dealTicket <= 0)
            continue;
            
        // Skip if already processed
        if(dealTicket <= lastProcessedDeal)
            continue;
            
        // Check if this is our EA's deal
        string symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
        if(symbol != _Symbol)
            continue;
            
        // Check if this is an exit deal (not entry)
        ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        if(dealEntry != DEAL_ENTRY_OUT)
            continue;
        
        // Get profit
        double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
        double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
        double totalProfit = profit + swap + commission;
        
        // Update statistics
        if(totalProfit > 0)
            dailyWins++;
        else
            dailyLosses++;
        
        // Update last processed deal
        lastProcessedDeal = dealTicket;
    }
}

//+------------------------------------------------------------------+
//| Check for new day and reset daily counters                       |
//+------------------------------------------------------------------+
void CheckNewDay()
{
    MqlDateTime currentTime, startTime;
    TimeToStruct(TimeCurrent(), currentTime);
    TimeToStruct(dailyStartTime, startTime);
    
    if(currentTime.day != startTime.day)
    {
        // Update daily statistics
        dailyProfit = accountInfo.Balance() - dailyStartBalance;
        
        // Reset for new day
        dailyStartTime = TimeCurrent();
        dailyStartBalance = accountInfo.Balance();
        dailyTrades = 0;
        dailyWins = 0;
        dailyLosses = 0;
        lastProcessedDeal = 0;
        tradingPaused = false;
        
        Print("New trading day started. Previous day profit: ", dailyProfit);
    }
}

//+------------------------------------------------------------------+
//| Send EA notification                                              |
//+------------------------------------------------------------------+
void SendEANotification(string message)
{
    Print(message);
    
    // Send alert
    Alert(message);
    
    // Optionally send MT5 push notification to mobile (requires configuration in Tools > Options)
    // Uncomment and use MT5's built-in SendNotification() after setup:
    // if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
    //     SendNotification(message);
}

//+------------------------------------------------------------------+
//| Create information panel                                          |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
    string prefix = "XAU_Panel_";
    
    // Background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, PanelX);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, PanelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, 300);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, 375);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, PanelColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    
    // Create labels
    CreateLabel(prefix + "Title", "XAUUSD SCALPING EA", PanelX + 10, PanelY + 10, 10, clrGold);
    CreateLabel(prefix + "Status", "Status: Active", PanelX + 10, PanelY + 35, 8, TextColor);
    CreateLabel(prefix + "Balance", "Balance: 0.00", PanelX + 10, PanelY + 60, 8, TextColor);
    CreateLabel(prefix + "DailyPL", "Daily P/L: 0.00", PanelX + 10, PanelY + 85, 8, TextColor);
    CreateLabel(prefix + "Trades", "Trades Today: 0", PanelX + 10, PanelY + 110, 8, TextColor);
    CreateLabel(prefix + "WinRate", "Win Rate: 0%", PanelX + 10, PanelY + 135, 8, TextColor);
    CreateLabel(prefix + "Positions", "Open Positions: 0", PanelX + 10, PanelY + 160, 8, TextColor);
    CreateLabel(prefix + "Spread", "Spread: 0.0", PanelX + 10, PanelY + 185, 8, TextColor);
    CreateLabel(prefix + "Session", "Session: Closed", PanelX + 10, PanelY + 210, 8, TextColor);
    CreateLabel(prefix + "ATR", "ATR: 0.00", PanelX + 10, PanelY + 235, 8, TextColor);
    CreateLabel(prefix + "MACD", "MACD: Neutral", PanelX + 10, PanelY + 260, 8, TextColor);
    CreateLabel(prefix + "RSI", "RSI: 50.0", PanelX + 10, PanelY + 285, 8, TextColor);
    CreateLabel(prefix + "Signal", "Signal: None", PanelX + 10, PanelY + 310, 8, TextColor);
    CreateLabel(prefix + "Error", "", PanelX + 10, PanelY + 335, 7, clrRed);
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
//| Update information panel                                          |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    string prefix = "XAU_Panel_";
    
    // Status
    string status = tradingPaused ? "Paused" : "Active";
    color statusColor = tradingPaused ? clrRed : clrLime;
    ObjectSetString(0, prefix + "Status", OBJPROP_TEXT, "Status: " + status);
    ObjectSetInteger(0, prefix + "Status", OBJPROP_COLOR, statusColor);
    
    // Balance
    ObjectSetString(0, prefix + "Balance", OBJPROP_TEXT, 
                    StringFormat("Balance: %.2f", accountInfo.Balance()));
    
    // Daily P/L
    double currentDailyPL = accountInfo.Balance() - dailyStartBalance;
    color plColor = currentDailyPL >= 0 ? clrLime : clrRed;
    ObjectSetString(0, prefix + "DailyPL", OBJPROP_TEXT, 
                    StringFormat("Daily P/L: %.2f", currentDailyPL));
    ObjectSetInteger(0, prefix + "DailyPL", OBJPROP_COLOR, plColor);
    
    // Trades
    ObjectSetString(0, prefix + "Trades", OBJPROP_TEXT, 
                    StringFormat("Trades Today: %d", dailyTrades));
    
    // Win Rate
    double winRate = dailyTrades > 0 ? (double)dailyWins / dailyTrades * 100.0 : 0.0;
    ObjectSetString(0, prefix + "WinRate", OBJPROP_TEXT, 
                    StringFormat("Win Rate: %.1f%%", winRate));
    
    // Open Positions
    int openPos = CountOpenPositions();
    ObjectSetString(0, prefix + "Positions", OBJPROP_TEXT, 
                    StringFormat("Open Positions: %d", openPos));
    
    // Spread
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double spread = (ask - bid) / point;
    ObjectSetString(0, prefix + "Spread", OBJPROP_TEXT, 
                    StringFormat("Spread: %.1f", spread));
    
    // Session
    string sessionStatus = IsWithinTradingSession() ? "Open" : "Closed";
    color sessionColor = IsWithinTradingSession() ? clrLime : clrOrange;
    ObjectSetString(0, prefix + "Session", OBJPROP_TEXT, 
                    "Session: " + sessionStatus);
    ObjectSetInteger(0, prefix + "Session", OBJPROP_COLOR, sessionColor);
    
    // ATR
    ObjectSetString(0, prefix + "ATR", OBJPROP_TEXT, 
                    StringFormat("ATR: %.2f", atrBuffer[0]));
    
    // MACD
    string macdStatus = macdMain[0] > macdSignal[0] ? "Bullish" : "Bearish";
    color macdColor = macdMain[0] > macdSignal[0] ? clrLime : clrRed;
    ObjectSetString(0, prefix + "MACD", OBJPROP_TEXT, "MACD: " + macdStatus);
    ObjectSetInteger(0, prefix + "MACD", OBJPROP_COLOR, macdColor);
    
    // RSI
    string rsiStatus = "Neutral";
    color rsiColor = clrGray;
    
    if(rsiBuffer[0] > RSI_Overbought)
    {
        rsiStatus = "Overbought";
        rsiColor = clrRed;
    }
    else if(rsiBuffer[0] < RSI_Oversold)
    {
        rsiStatus = "Oversold";
        rsiColor = clrLime;
    }
    
    ObjectSetString(0, prefix + "RSI", OBJPROP_TEXT, 
                    StringFormat("RSI: %.1f (%s)", rsiBuffer[0], rsiStatus));
    ObjectSetInteger(0, prefix + "RSI", OBJPROP_COLOR, rsiColor);
    
    // Signal
    int signal = GetEntrySignal();
    string signalText = signal == 1 ? "BUY" : (signal == -1 ? "SELL" : "None");
    color signalColor = signal == 1 ? clrLime : (signal == -1 ? clrRed : clrGray);
    ObjectSetString(0, prefix + "Signal", OBJPROP_TEXT, "Signal: " + signalText);
    ObjectSetInteger(0, prefix + "Signal", OBJPROP_COLOR, signalColor);
    
    // Error message
    ObjectSetString(0, prefix + "Error", OBJPROP_TEXT, lastErrorMsg);
}

//+------------------------------------------------------------------+
//| Delete information panel                                          |
//+------------------------------------------------------------------+
void DeleteInfoPanel()
{
    string prefix = "XAU_Panel_";
    
    ObjectDelete(0, prefix + "BG");
    ObjectDelete(0, prefix + "Title");
    ObjectDelete(0, prefix + "Status");
    ObjectDelete(0, prefix + "Balance");
    ObjectDelete(0, prefix + "DailyPL");
    ObjectDelete(0, prefix + "Trades");
    ObjectDelete(0, prefix + "WinRate");
    ObjectDelete(0, prefix + "Positions");
    ObjectDelete(0, prefix + "Spread");
    ObjectDelete(0, prefix + "Session");
    ObjectDelete(0, prefix + "ATR");
    ObjectDelete(0, prefix + "MACD");
    ObjectDelete(0, prefix + "RSI");
    ObjectDelete(0, prefix + "Signal");
    ObjectDelete(0, prefix + "Error");
}
//+------------------------------------------------------------------+
