// Bespoke Feed config : Finance Starter Pack

\d .proc
loadprocesscode:1b

\d .servers
enabled:1b
CONNECTIONS:enlist `tickerplant         // Feedhandler connects to the tickerplant
HOPENTIMEOUT:30000

\d .iex
main_url:"https://api.iextrading.com"
convert_epoch:{"p"$1970.01.01D+1000000j*x}
reqtype:`both
syms:`CAT`DOG
callback:".u.upd"
quote_suffix:{[sym] "/1.0/stock/",sym,"/quote"}
trade_suffix:{[sym]"/1.0/tops/last?symbols=",sym}
upd:{[t;x] .iex.callbackhandle(.iex.callback;t; value flip x)}
timerperiod:0D00:00:02.000

\d .
