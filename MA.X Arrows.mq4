//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|                                                     NIBIN BABU   |
//+------------------------------------------------------------------+

/*
STATERGY DISCRIPTION :
                       When the given two moving averages crosses each other we consider as it is an indication for a trade
                       We consoder it as an buy or sell signal accoding to the current market condition
                       Then we take trade
                       And the STOP LOSS AND TAKE PROFIT trailed according to the input
                               -------------------------
                       When the order hit it's SL then the lot doubled until it reaches the profit
                       When then order hit it's tp and not reached its last equity price then same lot will repeat until it hit it's stop loss
                       When the order hit it's TP and the toatl profit is above last profited equity price the lot will remain inital lot
                       closeing the order according to the DILY TARGET and DRAW DOWN

*/
#property strict
enum on_0ff_veriable {ON = True, OFF = False};


//common veriables
int i;
int mdfy;
int tickett ;
int orderselect;
int currentcandle = 0;
int current_buy_sel_candle = 0;


// declaration of calculation veriables in sellorder() & buyOrder()
double buy_sl  ;
double sell_sl ;



// declaration of  veriables and inputs in :                buy_order_sl_mdfy(), buy_order_sl_mdfy(), buy_order_tp_mdfy(), sell_order_tp_mdfy()
extern double Lot = 0.01;
double initial_lot = Lot;
extern int Slipage = 3;
extern int Magic_Number = 99;                       //Magic Number
extern double Stop_loss = 200;                     //Stop Loss
extern double Take_Profit = 200;                  //Take Profit
input on_0ff_veriable Trailing_SL_ON_OFF = OFF;    //Trailing SL ON OFF
extern double Trailing_SL = 100;                //Trailing SL
input on_0ff_veriable Trailing_TP_ON_OFF = OFF;  //Trailing TP ON OFF
extern double Trailing_TP = 100;              //Trailing TP
double trltp = Trailing_TP;                  //Trailing TP


// declaration of calculation veriables in :               buy_order_sl_mdfy() & sell_order_sl_mdfy()
double m_buy_sl = 0 ;
double m_sell_sl = 0 ;
double bu_sl;
double buy_open;
double sl_sl;
double sell_open;
double buy_diffrance ;
double sell_diffrance;
double buy_D;
double sell_D;


// declaration of calculation veriables in :              buy_order_tp_mdfy() & sell_order_tp_mdfy()
double buy_diffrance_tp;
double bu_tp;
double m_buy_tp;
double sell_diffrance_tp;
double sl_tp;
double m_sell_tp;


//declaration of calculation veriables in :                Orders_History_Total() ( Orderstotal()), lot_repitation()
double profit;
double total_PnL;
double closetime;
double last_order_pnl;
double last_order_lot;
double lst_cls_time ;
double ticket_num;
int ticketnumber = 0 ;
extern double profit_input = 5 ;// Dollar Target

//declaration of calculation veriables in :               start hour and end hour()
extern int Start_Hour = 3; //Start Hour
extern int End_Hour = 23; //End Hour


//declaration of calculation veriables in :                dailytarget_and_drowdown();

input on_0ff_veriable Daily_Target = OFF;         //Daily Target
extern double Daily_Target_In_Doller = 5;      //Daily Target In Dollar
double today_history_proft;
double orderprofit;
string day = 0;
bool day_flag = false ;

//declaration for draw down
input on_0ff_veriable drawdown_on_off = OFF;         //Draw Down
enum drow_down_type {Dollar = True, Percentage = False};
input drow_down_type drowdown_type = true;         //Type Of Drow Down In
extern double draw_down = 5;                      // Draw Down In Dollar
extern double Daily_Drwdown_in_percentage = 2 ;  //Draw Down In Percentage
bool drawflag ;
double equity = AccountEquity();



input string u = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" ;  //INDICATOR


//____________________________________________________________________
// declaration of  veriables and inputs in MAX indicator
double MA1;
double MA2;
double MA1prev;
double MA2prev;
extern int MA1_Period = 50;  //MA1 Period
extern int MA2_Period = 100;//MA2 Period
extern int Method = 3;
extern int PriceType = 4;
extern bool ReverseSignal = True;



//declaration of calculation veriables in  CloseAllBuy_and_sell()
int z;
int cnt;
int Total ;




//+------------------------------------------------------------------+
//|   ON Tick                                                        |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(day !=  TimeToString(TimeCurrent(),TIME_DATE))
     {
      day = TimeToString(TimeCurrent(),TIME_DATE) ;
      day_flag = True;
     }
   if(OrdersTotal() > 0 && current_buy_sel_candle != Bars)
      current_buy_sel_candle = Bars;


   if(currentcandle != Bars  &&  current_buy_sel_candle != Bars  &&  OrdersTotal() == 0  &&  Hour() > Start_Hour  &&  Hour() < End_Hour  &&  day_flag == True)    // picking indicator value
     {
      MA1=iMA(NULL,0,MA1_Period,0,Method,PriceType,1);
      MA2=iMA(NULL,0,MA2_Period,0,Method,PriceType,1);
      MA1prev=iMA(NULL,0,MA1_Period,0,Method,PriceType,2);
      MA2prev=iMA(NULL,0,MA2_Period,0,Method,PriceType,2);
      if(ReverseSignal)                                 // sending buy and sell orders according to the indicator reading

        {
         if(MA1 > MA2 && MA1prev < MA2prev)
            sellorder();
         if(MA1 < MA2 && MA1prev > MA2prev)
            buyOrder();
        }
      if(!ReverseSignal)                          // sending buy and sell orders according to the indicator reading in (reversal direction)
        {
         if(MA1 > MA2 && MA1prev < MA2prev)
            buyOrder();
         if(MA1 < MA2 && MA1prev > MA2prev)
            sellorder();
        }
      currentcandle = Bars;
     }

   orderstotal_zero();                    //setting trailing calculation value to zero

   if(OrdersTotal() > 0)
     {
      if(Trailing_TP_ON_OFF  == True)
        {
         buy_order_tp_mdfy();        //triling tp modification buy order
         sell_order_tp_mdfy();      //triling tp modification buy order
        }
      if(Trailing_SL_ON_OFF == True)
        {
         sell_order_sl_mdfy();  //triling sl modification sell order
         buy_order_sl_mdfy();  //triling sl modification buy order
        }
     }

   lot_repitation();                                          // lot calculation acoording to the profit
   lot_repitation_dailytarget_on();                          // if daily target is in on condition
   lot_repitation_daily_target_off_Profitinput_zero();      // when the daily target of and profit input ZERO
   dailytarget_and_drowdown();
  }




//+------------------------------------------------------------------+
//|  buy order                                                       |
//+------------------------------------------------------------------+
void buyOrder()
  {
   buy_sl = Ask - (Stop_loss * Point);
   tickett = OrderSend(Symbol(), OP_BUY, Lot, Ask, Slipage, buy_sl, Ask + Take_Profit*Point, NULL, Magic_Number, 0, clrLime);
  }


//+------------------------------------------------------------------+
//|  sell order                                                      |
//+------------------------------------------------------------------+
void sellorder()
  {
   sell_sl = Bid + (Stop_loss * Point);
   tickett = OrderSend(Symbol(), OP_SELL,Lot, Bid, Slipage,sell_sl, Bid - Take_Profit*Point, NULL, Magic_Number, 0,clrYellow);
  }


//+------------------------------------------------------------------+
//|  stop loss modification of buy order                             |
//+------------------------------------------------------------------+
void buy_order_sl_mdfy()
  {
   bu_sl = 0;
   buy_open = 0;
   for(i=OrdersTotal()-1 ; i >= 0; i--)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_BUY && OrderMagicNumber() == Magic_Number)
        {
         bu_sl = OrderStopLoss();
         buy_open = OrderOpenPrice();

         buy_sl_modfy();



         if(m_buy_sl>0)
           {

            mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),m_buy_sl,OrderTakeProfit(),0,clrChartreuse);
           }
        }
     }
  }


// calculation of BUY order stop loss mofication (trailing)
//+--------------------------------------------------------
int buy_sl_modfy()
  {
   buy_diffrance = Ask - buy_open ;
   if(buy_diffrance >= (Trailing_SL*Point))
     {
      if(bu_sl < buy_open)
        {
         m_buy_sl = bu_sl + ((Stop_loss*Point));
        }
      if(bu_sl >= buy_open)
        {
         buy_D = Ask-bu_sl;
         if(buy_D >= Trailing_SL*Point)
           {
            m_buy_sl = bu_sl +(buy_D - (Trailing_SL*Point));
           }
        }
     }
   return(0);
  }


//+------------------------------------------------------------------+
//|    stop loss modification of sell order                          |
//+------------------------------------------------------------------+
void sell_order_sl_mdfy()
  {
   sl_sl =0;
   sell_open =0;
   for(i=0 ; i<OrdersTotal(); i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_SELL && OrderMagicNumber() == Magic_Number)
        {
         sl_sl = OrderStopLoss();
         sell_open = OrderOpenPrice();
         sell_sl_modfy();
         if(m_sell_sl > 0)
           {
            //Alert("   "+m_sell_sl);
            mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),m_sell_sl,OrderTakeProfit(),0,clrChartreuse);
           }
        }
     }
  }


// calculation of sell order stop loss mofication (trailing)
//+---------------------------------------------------------
int sell_sl_modfy()
  {
   m_sell_sl = 0 ;
   sell_diffrance = sell_open -  Bid  ;
   if(sell_diffrance >= (Trailing_SL*Point))
     {
      if(sl_sl > sell_open)
        {
         m_sell_sl = sl_sl - (Stop_loss*Point);
        }
      if(sl_sl <= sell_open)
        {
         sell_D = sl_sl - Bid;
         if(sell_D > Trailing_SL*Point)
           {
            m_sell_sl = sl_sl - (sell_D - (Trailing_SL*Point));
           }
        }
     }
   return(0);
  }


//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|          picking of orders count and lot size from history total                                                                        |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Orders_History_Total()
  {
   for(i=0; i  < OrdersTotal() ; i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number)
        {
         if(OrderLots() == initial_lot)
           {
            ticketnumber = OrderTicket();
            drawflag = False;
           }
        }
     }

   total_PnL = 0 ;
   profit =0;
   closetime = 0 ;
   lst_cls_time = 0 ;
   last_order_lot = 0 ;
   last_order_pnl =0;

   for(i=OrdersHistoryTotal()-1 ; i >= 0 ; i--)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
      if(OrderMagicNumber() == Magic_Number && OrderTicket() >= ticketnumber)
        {
         profit = OrderProfit()  + OrderCommission() + OrderSwap();
         total_PnL = total_PnL + profit ;
        }
      if(OrderCloseTime() > closetime)
        {
         closetime = OrderCloseTime();
         last_order_pnl = OrderProfit() + OrderCommission() + OrderSwap();
         last_order_lot = OrderLots();
        }
      //if(OrderLots() == initial_lot && OrderCloseTime() > lst_cls_time)
      //  {
      //   lst_cls_time = OrderCloseTime();
      //   ticket_num = OrderTicket();
      //  }
     }
  }


//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|     calculation for lot repitation, lot increment and recurecting lot to inital lot                                                     |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void lot_repitation()
  {
   Orders_History_Total();
   if(Daily_Target == False && profit_input > 0)
     {
      if(total_PnL + orderprofit > profit_input + .03 && OrdersTotal() > 0)
        {
         CloseAllBuy_and_sell();
         Lot = initial_lot;
        }
      if(total_PnL > profit_input && OrdersTotal() == 0)
        {
         Lot = initial_lot;
        }
      if(total_PnL <= profit_input && last_order_pnl >= 0 && last_order_lot > 0 && OrdersTotal() == 0)
        {
         Lot = last_order_lot;
        }
      if(total_PnL < 0 && last_order_pnl < 0 &&  drawflag == False)
        {
         Lot = last_order_lot * 2;
        }
     }
  }


//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|     calculation for lot repitation  when daily target off and profit input ZERO lot increment and recurecting lot to inital lot                                                     |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void lot_repitation_daily_target_off_Profitinput_zero()
  {
   Orders_History_Total();
   if(Daily_Target == False && profit_input == 0)
     {
      if(total_PnL + orderprofit > profit_input && OrdersTotal()>0)
        {
         Lot = initial_lot;
        }
      if(total_PnL > profit_input && OrdersTotal() == 0)
        {
         Lot = initial_lot;
        }
      if(total_PnL <= profit_input && last_order_pnl >= 0 && last_order_lot > 0 && OrdersTotal() == 0)
        {
         Lot = last_order_lot;
        }
      if(total_PnL < 0 && last_order_pnl < 0 &&  drawflag == False)
        {
         Lot = last_order_lot * 2;
        }
     }
  }
//+------------------------------------------------------------------
void lot_repitation_dailytarget_on()
  {
   Orders_History_Total();
   if(Daily_Target == True)
     {
      if(total_PnL  > 0 && last_order_pnl > 0)
        {
         Lot = initial_lot;
        }
      if(total_PnL <= 0 && last_order_pnl >= 0 && last_order_lot > 0 && OrdersTotal() == 0)
        {
         Lot = last_order_lot;
        }
      if(total_PnL < 0 && last_order_pnl < 0 &&  drawflag == False)
        {
         Lot = last_order_lot * 2;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void orderstotal_zero()
  {
   if(OrdersTotal() == 0)                   //setting trailing calculation value to zero
     {
      Trailing_TP = trltp ;

      sl_tp =0;
      bu_tp =0;
      buy_D = 0 ;
      sell_D = 0;
      m_buy_tp =0 ;
      m_sell_tp = 0 ;
      m_sell_sl = 0 ;
      m_buy_sl = 0 ;
      sell_diffrance = 0;
      buy_diffrance = 0 ;
     }
  }

//+------------------------------------------------------------------+
//|  take profit  modification of buy order                          |
//+------------------------------------------------------------------+
void buy_order_tp_mdfy()
  {
   for(i=0 ; i  < OrdersTotal(); i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_BUY && OrderMagicNumber() == Magic_Number)
        {
         bu_tp = OrderTakeProfit();
         buy_tp_modfy();
         if(m_buy_tp > 0)
           {
            mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),m_buy_tp,0,clrChartreuse);
           }
        }
     }
  }


// calculation of BUY order take profit mofication (trailing)
//+--------------------------------------------------------
int buy_tp_modfy()
  {
   buy_diffrance = bu_tp - Ask ;
   if(buy_diffrance >= ((Take_Profit+Trailing_TP)*Point))
     {
      m_buy_tp = bu_tp - (buy_diffrance - (Take_Profit*Point));
      Trailing_TP = 0;
     }
   return(0);
  }

//+------------------------------------------------------------------+
//|    take profit modification of sell order                        |
//+------------------------------------------------------------------+
void sell_order_tp_mdfy()
  {
   for(i=0 ; i < OrdersTotal(); i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_SELL && OrderMagicNumber() == Magic_Number)
        {
         sl_tp = OrderTakeProfit();
         sell_tp_modfy();
         if(m_sell_tp >0)
           {
            mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),m_sell_tp,0,clrChartreuse);
           }
        }
     }
  }


// calculation of sell order take profit mofication (trailing)
//+---------------------------------------------------------
int sell_tp_modfy()
  {
   sell_diffrance_tp = Bid - sl_tp ;
   if(sell_diffrance_tp >= ((Take_Profit+Trailing_TP)*Point))
     {
      m_sell_tp = sl_tp + (sell_diffrance_tp - (Take_Profit*Point));
      Trailing_TP = 0;
     }
   return(0);
  }

//+------------------------------------------------------------------+
//|   daily trget and drow down                                      |
//+------------------------------------------------------------------+
void dailytarget_and_drowdown()
  {
   today_history_proft = 0 ;
   for(i=OrdersHistoryTotal()-1 ; i >= 0 ; i--)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
      if(OrderMagicNumber() == Magic_Number && Symbol() == Symbol() && TimeToString(TimeCurrent(),TIME_DATE) == TimeToString(OrderCloseTime(),TIME_DATE))
        {
         today_history_proft = today_history_proft+ OrderProfit()  + OrderCommission() + OrderSwap();
        }
     }
//+------------------------------------------------------------------+
   orderprofit = 0 ;

   for(i=0 ; i < OrdersTotal(); i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number)
        {
         orderprofit = OrderProfit()  + OrderCommission() + OrderSwap();
        }
     }
   Orders_History_Total();
   if(orderprofit + today_history_proft >=  Daily_Target_In_Doller && orderprofit +  total_PnL >= Daily_Target_In_Doller && Daily_Target == True)
     {
      CloseAllBuy_and_sell();
      day_flag = False;
      Lot = initial_lot;
     }
   if(drawdown_on_off == True && MathAbs(orderprofit + total_PnL) > draw_down && (orderprofit + total_PnL) < 0 && drowdown_type == true)
     {
      CloseAllBuy_and_sell();
      Lot = initial_lot;
      drawflag = true;
     }

   double input_percentage_ = equity *(.01*Daily_Drwdown_in_percentage);
   if(drawdown_on_off == True && MathAbs(orderprofit + total_PnL) > input_percentage_ && (orderprofit + total_PnL) < 0 && drowdown_type == False)
     {
      CloseAllBuy_and_sell();
      Lot = initial_lot;
      drawflag = true;
     }
  }



//+------------------------------------------------------------------+
//|    function for closing the open orders and pending orders       |
//+------------------------------------------------------------------+
int CloseAllBuy_and_sell()
  {
   Total = OrdersTotal();
   cnt = 0;
   for(i = (Total - 1) ; i >= 0 ; cnt++,i--)
     {
      z = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol() == Symbol()  && (OrderType() == OP_BUY || OrderType() == OP_SELL))
        {
         CloseOrder(OrderTicket(),0,5,5,500);
         cnt--;
        }
      else
         if(OrderSymbol() == Symbol()  && (OrderType()== OP_SELLSTOP || OrderType() == OP_BUYSTOP || OrderType()== OP_SELLLIMIT || OrderType()== OP_BUYLIMIT))
           {
            z = OrderDelete(OrderTicket());
            cnt--;
           }
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|// close order function                                           |
//+------------------------------------------------------------------+
bool CloseOrder(int ticket, double lots, int slippage, int tries, int pause)
  {
   bool result=false;
   double ask, bid;
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      RefreshRates();
      ask = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),MarketInfo(OrderSymbol(),MODE_DIGITS));
      bid = NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),MarketInfo(OrderSymbol(),MODE_DIGITS));
      if(OrderType()==OP_BUY)
        {
         for(int c = 0 ; c < tries ; c++)
           {
            if(lots==0)
               result = OrderClose(OrderTicket(),OrderLots(),bid,slippage,Violet);
            else
               result = OrderClose(OrderTicket(),lots,bid,slippage,Violet);
            if(result==true)
               break;
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
         for(int c = 0 ; c < tries ; c++)
           {
            if(lots==0)
               result = OrderClose(OrderTicket(),OrderLots(),ask,slippage,Violet);
            else
               result = OrderClose(OrderTicket(),lots,ask,slippage,Violet);
            if(result==true)
               break;
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
