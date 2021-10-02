//BBand Inputs

int       bb_period = 70;
int       bb_deviation = 2;
int       bb_shift = 0;

double    upBB = 0;
double    loBB = 0;
double    miBB = 0;

//////////////////////////////////////

double StartLotSize = 0.01;

double BuyGap = 30;
double BuyTakeProfit = 30;
double BuyLotIncrement = 1.55;

double SellGap = 30;
double SellTakeProfit = 30;
double SellLotIncrement = 1.55;
double MaxBBandLength = 15000;
int StartHour = 0;
int EndHour = 23;

enum BuySellTrade 
  {
   BS=0,     // BOTH
   B=1,     // BUY
   S=2,    // SELL
  };
//--- input parameters
input BuySellTrade TradeType = BS;

double BBandLength = 0;
double BuyLotSize = 0;
double SellLotSize = 0;
int Ticket = 0;
int GridMagic = 12345;

int CurrentBuyBar = 0;
int CurrentSellBar = 0;

double LastBuyPrice = 0;
double LastSellPrice = 0;
double NextBuyPrice = 0;
double NextSellPrice = 0;

double LastBuyLotSize = 0;
double LastSellLotSize = 0;
double NextBuyLotSize = 0;
double NextSellLotSize = 0;

double LastBuyTime = 0;
double LastSellTime = 0;

double TempPrice = 0;
double BuyTP = 0;
double SellTP = 0;
double TotalBuyPrice = 0;
double TotalBuyLotSize = 0;
double TotalSellPrice = 0;
double TotalSellLotSize = 0;

int TotalOpenBuy = 0;
int TotalOpenSell = 0;
double TotalBuyProfit = 0;
double TotalSellProfit = 0;
double BuyStartProfit = 0;
double SellStartProfit = 0;

int i = 0;
int cnt = 0;
int z = 0;
int Total = 0;
double pp = 0;
double DecimalPoints = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   CurrentBuyBar = Bars;
   CurrentSellBar = Bars;
   
   if(Symbol() == "EURUSD" || Symbol() == "GBPUSD" || Symbol() == "AUDUSD" || Symbol() == "EURGBP" || Symbol() == "EURCAD" || Symbol() == "USDCAD" || Symbol() == "AUDCAD" || Symbol() == "GBPCAD" || Symbol() == "EURNZD" || Symbol() == "EURAUD" || Symbol() == "GBPAUD")
   {
   
      DecimalPoints = 100000;
   
   }
   else if(Symbol() == "USDJPY" || Symbol() == "GBPJPY" || Symbol() == "EURJPY" || Symbol() == "CADJPY" || Symbol() == "AUDJPY" || Symbol() == "NZDJPY")
   {
   
      DecimalPoints = 1000;
   
   }
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
   pp = MarketInfo(Symbol(), MODE_POINT);      
   
   upBB=iBands(Symbol(),0,bb_period,bb_deviation,0,PRICE_CLOSE,MODE_UPPER,bb_shift);
   loBB=iBands(Symbol(),0,bb_period,bb_deviation,0,PRICE_CLOSE,MODE_LOWER,bb_shift);
   miBB = iMA(Symbol(),0,bb_period,0,MODE_SMA,PRICE_CLOSE,bb_shift);
   
   BBandLength = (upBB - loBB) * DecimalPoints;
   
   ScanOrders();
   
   
   //if(Hour() >= StartHour && Hour() <= EndHour && BBandLength <= MaxBBandLength)
   if(Hour() >= StartHour && Hour() <= EndHour)
   {
   
      //if(TotalOpenBuy == 0 && CurrentBuyBar != Bars && Bid < loBB && (TradeType == BS || TradeType == B))  
      if(TotalOpenBuy == 0 && CurrentBuyBar != Bars && Close[1] > Open[1] && (TradeType == BS || TradeType == B))  
      {
   
         BuyLotSize = StartLotSize;
     
         BuyEntry();
         CurrentBuyBar = Bars;
         BuyStartProfit = StartLotSize * BuyTakeProfit;
         SetBuyTakeProfit();
      
   
      }
      //if(TotalOpenSell == 0 && CurrentSellBar != Bars && Bid > upBB && (TradeType == BS || TradeType == S))  
      if(TotalOpenSell == 0 && CurrentSellBar != Bars && Close[1] < Open[1] && (TradeType == BS || TradeType == S))
      {
   
         SellLotSize = StartLotSize;
   
         SellEntry();      
         CurrentSellBar = Bars;
         SellStartProfit = StartLotSize * SellTakeProfit;
         SetSellTakeProfit();
         
      }
      
   
   }
   if(CurrentBuyBar != Bars && Bid <= NextBuyPrice && TotalOpenBuy > 0 && (TradeType == BS || TradeType == B))
   {
   
      BuyLotSize = NextBuyLotSize;
      
      BuyEntry();
      CurrentBuyBar = Bars;
      ModifyTakeProfit();
         
   }
   if(CurrentSellBar != Bars && Bid >= NextSellPrice && TotalOpenSell > 0 && (TradeType == BS || TradeType == S))
   {
         
      SellLotSize = NextSellLotSize;
      
      SellEntry();
      CurrentSellBar = Bars;
      ModifyTakeProfit();
        
   }
   if(CurrentBuyBar != Bars && Bid > NextBuyPrice && TotalOpenBuy > 0 && (TradeType == BS || TradeType == B))
   {
   
      CurrentBuyBar = Bars;
         
   }
   if(CurrentSellBar != Bars && Bid < NextSellPrice && TotalOpenSell > 0 && (TradeType == BS || TradeType == S))
   {
         
      CurrentSellBar = Bars;
        
   }
   
   if(TotalOpenBuy == 1 && TotalBuyProfit > BuyStartProfit && (TradeType == BS || TradeType == B))
   {
   
      CloseAllBuy();
   
   }
   if(TotalOpenSell == 1 && TotalSellProfit > SellStartProfit && (TradeType == BS || TradeType == S))
   {
   
      CloseAllSell();
   
   }
   
}
//+------------------------------------------------------------------+


int SetBuyTakeProfit()
{
   
   for (i = 0 ; i < OrdersTotal() ; i++)         
   {
   
      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
                  
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY)
      {
            
         z = OrderModify(OrderTicket(),OrderOpenPrice(),0.0,OrderOpenPrice() + BuyTakeProfit * Point,0,CLR_NONE);
            
      }
            
   }

   return(0);

}


int SetSellTakeProfit()
{
   
   for (i = 0 ; i < OrdersTotal() ; i++)
   {
   
      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
          
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_SELL)
      {
            
         z = OrderModify(OrderTicket(),OrderOpenPrice(),0.0,OrderOpenPrice() -  SellTakeProfit * Point,0,CLR_NONE);
            
      }
         
   }

   return(0);

}
int ModifyTakeProfit()
{
   
   BuyTP = 0;
   SellTP = 0;
   TempPrice = 0;   
   TotalBuyPrice = 0;
   TotalBuyLotSize = 0;
   TotalSellPrice = 0;
   TotalSellLotSize = 0;
   TotalOpenBuy = 0;
   TotalOpenSell = 0;
      
   for (i = 0 ; i < OrdersTotal() ; i++)
   {
   
      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
          
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY)
      {
            
         TempPrice = OrderOpenPrice() * OrderLots();
         TotalBuyPrice = TotalBuyPrice + TempPrice;
         TotalBuyLotSize = TotalBuyLotSize + OrderLots();
         TotalOpenBuy++;
            
            
      }
      else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_SELL)
      {
            
         TempPrice = OrderOpenPrice() * OrderLots();
         TotalSellPrice = TotalSellPrice + TempPrice;
         TotalSellLotSize = TotalSellLotSize + OrderLots();
         TotalOpenSell++;
            
      }
            
   }
     
   if(TotalOpenBuy > 0)
   {
            
      BuyTP = (TotalBuyPrice / TotalBuyLotSize) ;
      BuyTP = BuyTP + BuyTakeProfit * Point;
      
   }
   if(TotalOpenSell > 0)
   {
      
      SellTP = (TotalSellPrice / TotalSellLotSize) ;
      SellTP = SellTP - SellTakeProfit * Point;
      
   }
   
   for (i = 0 ; i < OrdersTotal() ; i++)         
   {
      
      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         
      //if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_SELL && TotalOpenSell > 0 && OrderTakeProfit() < SellTP)
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_SELL && TotalOpenSell > 0)
      {
      
         z = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),SellTP,0,CLR_NONE);
            
      }
      
      //else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY && TotalOpenBuy > 0 && OrderTakeProfit() > BuyTP)
      else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY && TotalOpenBuy > 0)
      {
         
         z = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),BuyTP,0,CLR_NONE);
            
      }
           
   }
   
   return(0);
      
}

int CloseAllBuy()
{
   Total = OrdersTotal();
   cnt = 0;

   for (i = 0 ; i < Total ; cnt++,i++)
   {
            
      z = OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
        
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY)
      {
           
         CloseOrder(OrderTicket(),0,5,5,500);                      
         cnt--;
          
      }  
          
      else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && (OrderType()== OP_SELLSTOP || OrderType() == OP_BUYSTOP || OrderType()== OP_SELLLIMIT || OrderType()== OP_BUYLIMIT))
      {
           
         z = OrderDelete(OrderTicket());
         cnt--;
          
      } 
          
   }
   
   return(0);

}

int CloseAllSell()
{
   Total = OrdersTotal();
   cnt = 0;

   for (i = 0 ; i < Total ; cnt++,i++)
   {
            
      z = OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
        
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType()== OP_SELL)
      {
           
         CloseOrder(OrderTicket(),0,5,5,500);                      
         cnt--;
          
      }  
          
      else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && (OrderType()== OP_SELLSTOP || OrderType() == OP_BUYSTOP || OrderType()== OP_SELLLIMIT || OrderType()== OP_BUYLIMIT))
      {
           
         z = OrderDelete(OrderTicket());
         cnt--;
          
      } 
          
   }
   
   return(0);

}


//+------------------------------------------------------------------+
bool CloseOrder(int ticket, double lots, int slippage, int tries, int pause)
{
   bool result=false;
   double ask , bid;
 
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
   {
      RefreshRates();
      ask = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),MarketInfo(OrderSymbol(),MODE_DIGITS));
      bid = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),MarketInfo(OrderSymbol(),MODE_DIGITS));
    
      if(OrderType()==OP_BUY)
      {
         for(int c = 0 ; c < tries ; c++)
         {
            if(lots==0) result = OrderClose(OrderTicket(),OrderLots(),bid,slippage,Violet);
            else result = OrderClose(OrderTicket(),lots,bid,slippage,Violet);
          
            if(result==true) break;
            else
            {
               Sleep(pause);
               RefreshRates();
               ask = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),MarketInfo(OrderSymbol(),MODE_DIGITS));
               bid = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),MarketInfo(OrderSymbol(),MODE_DIGITS));    
               continue;
            }
         }
      }
      if(OrderType()==OP_SELL)
      {
         for(c = 0 ; c < tries ; c++)
         {
            if(lots==0) result = OrderClose(OrderTicket(),OrderLots(),ask,slippage,Violet);
            else result = OrderClose(OrderTicket(),lots,ask,slippage,Violet);
            if(result==true) break;
            else
            {
               Sleep(pause);
               RefreshRates();
               ask = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),MarketInfo(OrderSymbol(),MODE_DIGITS));
               bid = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),MarketInfo(OrderSymbol(),MODE_DIGITS));
               continue;
            }
         }
      }
   }
 
   return(result);
}

//+------------------------------------------------------------------+--------------------------------------------------+
//Buy Entry

int BuyEntry()
{
   
   Ticket = OrderSend(Symbol(), 0, BuyLotSize, Ask , 3,0.0, 0.0, "Blessing",GridMagic,0,Green);
   
   return(0);
   
}

//Sell Entry

int SellEntry()
{
    
   Ticket = OrderSend(Symbol(), 1, SellLotSize, Bid , 3,0.0, 0.0, "Blessing",GridMagic,0,Green); 
    
   return(0);   
    
}

//+------------------------------------------------------------------+

int ScanOrders()
{

   TotalOpenBuy = 0;
   TotalOpenSell = 0;
   
   LastBuyPrice = 0;
   LastSellPrice = 0;
   NextBuyPrice = 0;
   NextSellPrice = 0;
   
   LastBuyLotSize = 0;
   LastSellLotSize = 0;
   NextBuyLotSize = 0;
   NextSellLotSize = 0;
   
   LastBuyTime = 0;
   LastSellTime = 0;
   
   TotalBuyProfit = 0;
   TotalSellProfit = 0;
   
   //This is for counting Buy and Sell Open Trades

   for(i = 0; i < OrdersTotal(); i++)
   {

      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
   
      if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_BUY) 
      {
 
        TotalOpenBuy++;
        TotalBuyProfit = TotalBuyProfit + OrderProfit();
        
        if(OrderOpenTime() > LastBuyTime)
        {
        
           LastBuyPrice = OrderOpenPrice();
           LastBuyLotSize = OrderLots();
           LastBuyTime = OrderOpenTime();
           
        }
      
      }
      else if(OrderSymbol() == Symbol() && OrderComment() == "Blessing" && OrderType() == OP_SELL) 
      {
 
        TotalOpenSell++;
        TotalSellProfit = TotalSellProfit + OrderProfit();
        
        if(OrderOpenTime() > LastSellTime)
        {
        
           LastSellPrice = OrderOpenPrice();
           LastSellLotSize = OrderLots();
           LastSellTime = OrderOpenTime();
           
        }
      
 
      }
 
   } //end of for loop
   
   if(TotalOpenBuy > 0)
   {
   
      NextBuyPrice = LastBuyPrice - BuyGap * Point;
      NextBuyLotSize = BuyLotSize * BuyLotIncrement;
      
      if(BuyLotSize == 0)
      {
      
         NextBuyLotSize = LastBuyLotSize * BuyLotIncrement;
      
      }
      
         
   }
   
   if(TotalOpenSell > 0)
   {
   
      NextSellPrice = LastSellPrice + SellGap * Point;
      NextSellLotSize = SellLotSize * SellLotIncrement;
      
      if(SellLotSize == 0)
      {
      
         NextSellLotSize = LastSellLotSize * SellLotIncrement;
      
      }
      
         
   }
   

   return (0);

}

