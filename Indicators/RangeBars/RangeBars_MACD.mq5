//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Moving Average Convergence/Divergence"
#property description "Adapted for use with TickChart by Artur Zas."

#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_LINE
#property indicator_color1  Lime
#property indicator_color2  Red
#property indicator_color3  Red
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_label1  "MACD Up"
#property indicator_label2  "MACD Down"
#property indicator_label3  "MACD Signal"
//--- input parameters
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
//--- indicator buffers
double                   ExtMacdBufferUp[];
double                   ExtMacdBufferDn[];
double                   ExtSignalBuffer[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
double                   ExtMacdBuffer[];

#include <AZ-INVEST/SDK/RangeBarIndicator.mqh>
RangeBarIndicator customChartIndicator;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBufferUp,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMacdBufferDn,INDICATOR_DATA);
   SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtMacdBuffer,INDICATOR_CALCULATIONS);
   
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSignalSMA-1);
//--- name for Dindicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalSMA)+")");
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);

   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   int _rates_total = customChartIndicator.GetRatesTotal();
   
   

//--- check for data
   if(_rates_total<InpSignalSMA)
      return(0);
//--- we can copy not all data
   int to_copy;
   if(_prev_calculated>_rates_total || _prev_calculated<0) to_copy=_rates_total;
   else
     {
      to_copy=_rates_total-_prev_calculated;
      if(_prev_calculated>0) to_copy++;
     }
       
//--- get Fast EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag   
   ExponentialMAOnBuffer(_rates_total,_prev_calculated,0,InpFastEMA,customChartIndicator.Close,ExtFastMaBuffer);
//--- get SlowSMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   ExponentialMAOnBuffer(_rates_total,_prev_calculated,0,InpSlowEMA,customChartIndicator.Close,ExtSlowMaBuffer);
//---
   int limit;
   if(_prev_calculated==0)
      limit=0;
   else limit=_prev_calculated-1;
//--- calculate MACD

   for(int i=limit;i<_rates_total && !IsStopped();i++)
   {
      ExtMacdBuffer[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
      if(ExtMacdBuffer[i] > 0)
      {
         ExtMacdBufferUp[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
         ExtMacdBufferDn[i] = 0;
      }
      else if(ExtMacdBuffer[i] < 0)
      {
         ExtMacdBufferDn[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
         ExtMacdBufferUp[i] = 0;
      }
   }
//--- calculate Signal
   SimpleMAOnBuffer(_rates_total,_prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- OnCalculate done. Return new _prev_calculated.

   return(rates_total);
  }
//+------------------------------------------------------------------+
