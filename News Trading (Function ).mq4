//+------------------------------------------------------------------+
//|  NIBIN BABU            News Trading                              |
//+------------------------------------------------------------------+
/* 
Strategy Dscription

   placing pending orders from the ask and bid by the given input gap
   the pending orders are modifyed according to the given time delay
   when an order exicuted and it close at it's stop loss all pending orders deleted and doubling the lot
   when the the doubling close at it's tp and cheaking the current equity 
   if it is not reached the expacted equity (it is the total profit that we need to be obtaind by the inital lot orders) 
   continueing the same lot when it reaches our expacted equity 
   after that reducing the lot to inital lot.
*/

// inputs
extern double Lot =  0.01 ;
double initial_lot = Lot  ;
extern double Time_delay_in_seconds = 60;
extern double buy_stop_loss = 50  ;
extern double buy_take_profit = 50;
extern double sell_stop_loss = 50   ;
extern double sell_take_profit = 50 ;
extern double buystop_Gap = 50 ;
extern double sellstop_Gap = 50;


//common declaration
int tickett;
int i;
int mdfy;
int orderselect;
int order;
double initial_equity = AccountEquity();

// declaring veriables in                                           Orders_History_Total()
bool flag = True ;

double s_tp ;
double c_tp ;
double buy_lot;
double sell_lot;
double s_stop_loss;
double c_ticket_num;
double c_close_price ;
double s_close_price ;

datetime c_close_time ;
datetime s_close_time ;
datetime last_buy_lot_close_time;
datetime last_sell_lot_close_time;

int s_ticket_num ;
int buy_count_of_initial_lot_orders_in_order_history_stotal;
int sell_count_of_initial_lot_orders_in_order_history_stotal;


// declaring veriables in                                            Orders_Total()
int sellcount;
int buycount ;
int sell_stop_cunt;
int buy_stop_cunt ;
int last_inital_lot_ticket_num ;
int buy_count_of_initial_lot_orders_in_orderstotal ;
int sell_count_of_initial_lot_orders_in_orderstotal;


// declaring veriables in                                            ExpactedEquity_Calculation()
int nubmer_of_buy_orders_in_first_lots ;
int nubmer_of_sell_orders_in_first_lots;
double estimated_buy_order_profit  ;
double estimated_sell_order_profit ;
double expected_total_profit ;
double expected_total_equity ;
double current_account_equity;


// declaring veriables in                                             Lot_Decrementing()
bool lot_decrement = True;


// declaring veriables in                                             Lot_Repetation()
int before_b_ticket;
int before_s_ticket;


// declaring veriables in                                              Order_Send()
int Count;
int last_buy_trided_time ;
int last_sell_trided_time;


// declaring veriables in                                             TimeDelay()
double buy_open_mdfy ;
double sell_open_mdfy;


//for close all function
int z;
int cnt;
int Total ;


//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|                                               On Tick                                                                                   |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void OnTick()
  {
   Orders_Total();

   Orders_History_Total();

   ExpactedEquity_Calculation();

   Lot_Decrementing();

   Lot_Repetation();

   Order_Send();

   TimeDelay();

   TP_SL_modification();

  }






//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|          picking of orders count and lot size from history total and                                                                            |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Orders_History_Total()
  {


   s_tp = 0 ;
   c_tp = 0 ;
   s_stop_loss = 0;
   c_close_time = 0;
   s_close_time = 0;
   s_ticket_num = 0;
   c_close_price = 0;
   s_close_price = 0;
   c_ticket_num  = 0;
   last_buy_lot_close_time = 0 ;
   last_sell_lot_close_time = 0 ;
   buy_count_of_initial_lot_orders_in_order_history_stotal = 0 ;
   sell_count_of_initial_lot_orders_in_order_history_stotal = 0;

   for(i=OrdersHistoryTotal()-1 ; i >= 0 ; i--)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);

      if(OrderType() == OP_BUY && OrderClosePrice() == OrderStopLoss() && OrderCloseTime() > last_buy_lot_close_time && OrderTicket() >= last_inital_lot_ticket_num)
        {
         buy_lot = OrderLots();
         last_buy_lot_close_time = OrderCloseTime();
        }
      if(OrderType() == OP_SELL && OrderClosePrice() == OrderStopLoss() && OrderCloseTime() > last_sell_lot_close_time && OrderTicket() >= last_inital_lot_ticket_num)
        {
         sell_lot = OrderLots();
         last_sell_lot_close_time = OrderCloseTime();
        }
      if(OrderType() == OP_BUY   && OrderLots() == initial_lot)
        {
         buy_count_of_initial_lot_orders_in_order_history_stotal ++;
        }
      if(OrderType() == OP_SELL && OrderLots() == initial_lot)
        {
         sell_count_of_initial_lot_orders_in_order_history_stotal ++;
        }
      if(OrderType() == OP_SELL || OrderType() == OP_BUY)
        {
         if(OrderCloseTime() > s_close_time)
           {
            //these below veriables are for both buysorders and sellorders
            s_tp          = OrderTakeProfit();
            s_close_time  = OrderCloseTime();
            s_ticket_num  = OrderTicket();
            s_stop_loss   = OrderStopLoss();
            s_close_price = OrderClosePrice();
           }
        }
      if((OrderType() == OP_BUY || OrderType() == OP_SELL)  && OrderClosePrice() == OrderTakeProfit())
        {
         if(OrderCloseTime() > c_close_time)
           {
            c_close_time  = OrderCloseTime();
            c_tp          = OrderTakeProfit();
            c_close_price = OrderClosePrice();
            c_ticket_num  = OrderTicket();
           }
        }
     }
  }





//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|   picking individual count from orders total                                                                                            |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Orders_Total()
  {
   sellcount = 0;
   buycount = 0 ;
   buy_stop_cunt = 0  ;
   sell_stop_cunt = 0 ;
   buy_count_of_initial_lot_orders_in_orderstotal = 0  ;
   sell_count_of_initial_lot_orders_in_orderstotal = 0 ;

// initial two pending order

   for(i=0 ; i < OrdersTotal(); i++)
     {
      orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

      if(OrderType() == OP_BUYSTOP)
        {
         buy_stop_cunt++;
        }
      if(OrderType() == OP_SELLSTOP)
        {
         sell_stop_cunt++;
        }
      if(OrderType() == OP_BUY)
        {
         buycount ++ ;
        }
      if(OrderType() == OP_SELL)
        {
         sellcount ++ ;
        }
      if(OrderType() == OP_BUY  && OrderLots() == initial_lot)
        {
         buy_count_of_initial_lot_orders_in_orderstotal ++;
        }
      if(OrderType() == OP_SELL && OrderLots() == initial_lot)
        {
         sell_count_of_initial_lot_orders_in_orderstotal ++;
        }
      if((OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderLots() == initial_lot && flag == True)
        {
         last_inital_lot_ticket_num = OrderTicket();
         flag = False;
        }
     }
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|     function for calculating the initial lot order number and estimated profit                                                          |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void ExpactedEquity_Calculation()
  {
   nubmer_of_buy_orders_in_first_lots = buy_count_of_initial_lot_orders_in_orderstotal + buy_count_of_initial_lot_orders_in_order_history_stotal;
   estimated_buy_order_profit =((nubmer_of_buy_orders_in_first_lots*initial_lot)*(buy_take_profit));


   nubmer_of_sell_orders_in_first_lots = sell_count_of_initial_lot_orders_in_orderstotal + sell_count_of_initial_lot_orders_in_order_history_stotal;
   estimated_sell_order_profit =((nubmer_of_sell_orders_in_first_lots*initial_lot)*(sell_take_profit));


   expected_total_profit = estimated_sell_order_profit + estimated_buy_order_profit ;
   expected_total_equity = expected_total_profit + initial_equity;
   current_account_equity =  AccountEquity() ;
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|        function for recorrecting the doubling lot to inital lot when the expacted equity reaches                                        |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Lot_Decrementing()
  {
   if(current_account_equity < expected_total_equity)
     {
      lot_decrement = True;
     }
   if(current_account_equity >= expected_total_equity &&  lot_decrement == True)
     {
      CloseAllBuy_and_sell();
      Lot = initial_lot;
      buy_lot = initial_lot;
      sell_lot = initial_lot;
      lot_decrement = False;
      flag = True;
     }
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|   function for repeating the same lot when  any of orders reaches it's target and expacted equity is not reached                        |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Lot_Repetation()
  {
   if((s_close_price > 0)   && (s_stop_loss ==  s_close_price)   && (before_s_ticket != s_ticket_num))
     {
      before_s_ticket = s_ticket_num ;
      CloseAll();
      if(buy_lot > sell_lot && (buy_lot != 0 || sell_lot != 0))
        {
         Lot = buy_lot;
        }
      else
        {
         Lot = sell_lot;
        }
      Lot = Lot*2 ;
     }
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|       functon for sending buystop and sell stop in the given gap from ask and bid                                                       |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void Order_Send()
  {
//     for buy orders

   if(buy_stop_cunt == 0 && buycount == 0)
     {
      tickett = -1;
      Count = 0 ;
      while((tickett == -1) && (Count < 100))
        {
         tickett = OrderSend(Symbol(),OP_BUYSTOP,Lot,Ask +buystop_Gap*Point,3,0,0,NULL,888,0,clrBeige);
         Count++;
        }
      last_buy_trided_time = TimeCurrent();

     }

// for sell orders

   if(sell_stop_cunt == 0 && sellcount ==0)
     {
      tickett = -1;
      Count = 0 ;
      while((tickett == -1) && (Count < 100))
        {
         tickett = OrderSend(Symbol(),OP_SELLSTOP,Lot,Bid-sellstop_Gap*Point,3,0,0,NULL,999,0,clrForestGreen);
         Count++;
        }
      last_sell_trided_time = TimeCurrent();


     }

  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|          modifying order with the given time in seconds                                                                                 |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void TimeDelay()
  {
//   modifying buy stop

   if(last_buy_trided_time +Time_delay_in_seconds <= TimeCurrent())
     {
      buycount = 0 ;
      for(i=0 ; i<OrdersTotal(); i++)
        {
         orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

         if(OrderType() == OP_BUYSTOP && OrderMagicNumber() == 888 && buycount == 0)
           {
            buy_open_mdfy = Ask+buystop_Gap*Point;
            mdfy = OrderModify(OrderTicket(),buy_open_mdfy,0,0,0,clrChartreuse);
            last_buy_trided_time = TimeCurrent();
           }
        }
     }

//   modifying sell stop

   if(last_sell_trided_time +Time_delay_in_seconds <= TimeCurrent())
     {
      sellcount = 0 ;
      for(i=0 ; i<OrdersTotal(); i++)
        {
         orderselect =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

         if(OrderType() == OP_SELLSTOP && OrderMagicNumber() == 999 && sellcount == 0)
           {
            sell_open_mdfy = Bid-sellstop_Gap*Point;
            mdfy = OrderModify(OrderTicket(),sell_open_mdfy,0,0,0,clrChartreuse);
            last_sell_trided_time = TimeCurrent();
           }

        }
     }
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|     function for modifying the Tp and SL for exicuted buystop and sell stop                                                             |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
void TP_SL_modification()
  {
   for(i=0 ; i < OrdersTotal() ; i++)
     {
      order =  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //for buy stop
      if(OrderType() == OP_BUY)
        {
         mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),(OrderOpenPrice() - (buy_stop_loss*Point)),(OrderOpenPrice() + (buy_take_profit*Point)),0,clrBlue);
        }
      // for sellstop
      if(OrderType() == OP_SELL)
        {
         mdfy = OrderModify(OrderTicket(),OrderOpenPrice(),(OrderOpenPrice() + (sell_stop_loss*Point)),(OrderOpenPrice() - (sell_take_profit*Point)),0,clrAzure);
        }
     }
  }




//+-----------------------------------------------------------------------------------------------------------------------------------------+
//|      closing function for all pending orders                                                                                            |
//+-----------------------------------------------------------------------------------------------------------------------------------------+
int CloseAll()
  {
   cnt = 0;
   Total = OrdersTotal();

   for(i = 0 ; i < Total ; cnt++,i++)
     {
      z = OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol() == Symbol()  && (OrderType() == OP_BUYSTOP ||  OrderType()== OP_BUYLIMIT))
        {
         z = OrderDelete(OrderTicket());
         cnt--;
        }
      if(OrderSymbol() == Symbol()  && (OrderType() == OP_SELLSTOP ||  OrderType()== OP_SELLLIMIT))
        {
         z = OrderDelete(OrderTicket());
         cnt--;
        }
     }
   return(0);
  }




//+------------------------------------------------------------------+
//|// function for cong  the  open orders                            |
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
         for(c = 0 ; c < tries ; c++)
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

//+------------------------------------------------------------------+
