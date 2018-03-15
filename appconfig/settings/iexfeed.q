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
upd:{[t;x] .iex.callbackhandle(.iex.callback;t; value flip delete time from x)}
timerperiod:0D00:00:02.000


\d .trd
ocol:`symbol`price`size`stop`cond`ex`time; /!(`symbol$();0f;0j;0b;" ";" ";0);
ncol:`sym`price`size`stop`cond`ex`srctime;
typ:`"SfjbCCn";

\d .qte
ocol:`symbol`iexBidPrice`iexAskPrice`iexBidSize`iexAskSize`mode`ex`latestUpdate; /!(`symbol$();0f;0f;0j;0j;" ";" ";0);
ncol:`sym`bid`ask`bsize`asize`mode`ex`srctime;
typ:"SffjjCCn";

\d .


