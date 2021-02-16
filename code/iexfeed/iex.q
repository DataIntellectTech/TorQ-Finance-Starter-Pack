\d .iex

main_url:@[value;`main_url;"https://cloud.iexapis.com/stable"];
token:@[value;`token;""];
convert_epoch:@[value;`convert_epoch;{{"p"$1970.01.01D+1000000j*x}}];
reqtype:@[value;`reqtype;`both];
syms:@[value;`syms;`CAT`DOG];
callback:@[value;`callback;".u.upd"];
callbackhandle:@[value;`callbackhandle;0i];
callbackconnection:@[value;`callbackconnection;`];
quote_suffix:@[value;`quote_suffix;{{[sym] "/stock/",sym,"/quote?token="}}];
trade_suffix:@[value;`trade_suffix;{{[sym] "/tops/last?symbols=",sym,"&token="}}];
upd:@[value;`upd;{{[t;x].iex.callbackhandle(.iex.callback;t; value flip x)}}];
timerperiod:@[value;`timerperiod;0D00:00:02.000];

init:{[x]
   if[`main_url in key x;.iex.main_url:x `main_url];
   if[`token in key x;.iex.token:x `token];
   if[`quote_suffix in key x;.iex.quote_suffix:x `quote_suffix];
   if[`trade_suffix in key x;.iex.trade_suffix:x`trade_suffix];
   if[`syms in key x;.iex.syms: upper x`syms];
   if[`reqtype in key x;.iex.reqtype:x`reqtype];
   if[`callbackconnection in key x;.iex.callbackhandle:neg hopen .iex.callbackconnection:x `callbackconnection];
   if[`callbackhandle in key x;.iex.callbackhandle:x `callbackhandle];
   if[`callback in key x;.iex.callback: $[.iex.callbackhandle=0; string @[value;x `callback;{[x;y]x set {[t;x]x}}[x`callback]]; x`callback]];
   if[`upd in key x; .iex.upd:x[`upd]];
   .iex.timer:$[not .iex.reqtype in key .iex.timer_dict;'`timer;.iex.timer_dict .iex.reqtype];
   }

get_data:{[suffix]
   :.Q.hg hsym `$.iex.main_url,suffix,.iex.token;
   }

get_last_trade:{tab:{[syms]
   / This function can run for multiple securities.
   syms:$[1<count syms;"," sv string[upper syms];string[upper syms]];
   / Construct the GET request
   suffix:.iex.trade_suffix[syms];
   / Parse json response and put into table. Trade data from https://iextrading.com/developer/
   data:.j.k .iex.get_data[suffix];
   tab:select sym:`$symbol, price:`float$price, size:`int$size, stop:(count data)#0b, cond:(count data)#`char$(), ex:(count data)#`char$(), srctime:.iex.convert_epoch time from data
   }[.iex.syms]; .iex.upd[`trade_iex;tab]
   }

get_quote:{tab:raze {[sym]
   sym:string[upper sym];
   suffix:.iex.quote_suffix[sym];
   / Parse json response and put into table
   data: enlist .j.k .iex.get_data[suffix];
   select sym:`$symbol, bid: `float$iexBidPrice, ask:`float$iexAskPrice, bsize:`long$iexBidSize, asize:`long$iexAskSize, mode:(count data)#`char$(), ex:(count data)#`char$(), srctime:.iex.convert_epoch latestUpdate from data
   }'[.iex.syms,()]; .iex.upd[`quote_iex;tab] 
   }

timer_both:{.iex.get_last_trade[];.iex.get_quote[]}
timer_dict:`trade`quote`both!(.iex.get_last_trade;.iex.get_quote;timer_both)

timer:{ @[$[not .iex.reqtype in key .iex.timer_dict;
              {'`$"timer request type not valid: ",string .iex.reqtype};
              .iex.timer_dict[.iex.reqtype]];
          [];
          {.lg.e[`iextimer;"failed to run iex timer function: ",x]}]}


\d . 
