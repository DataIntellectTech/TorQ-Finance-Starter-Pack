// Bespoke Feed config : Finance Starter Pack

\d .proc
loadprocesscode:1b

\d .servers
enabled:1b
CONNECTIONS:enlist `tickerplant         // Feedhandler connects to the tickerplant
HOPENTIMEOUT:30000

\d .iex
mainurl:"https://api.iextrading.com"
convertepoch:{"p"$1970.01.01D+1000000j*x}
reqtype:`both
syms:`CAT`DOG
callback:".u.upd"
quotesuffix:{[sym] "/1.0/stock/",sym,"/quote"}
tradesuffix:{[sym]"/1.0/tops/last?symbols=",sym}
upd:{[t;x].iex.callbackhandle(.iex.callback;t; value flip delete time from x)}
timerperiod:0D00:00:02.000

// Define columns for trade and quote data
dtrd:`ocol`ncol`typ!(`symbol`price`size`stop`cond`ex`time;`sym`price`size`stop`cond`ex`srctime;"SfjbCCn");
dqte:`ocol`ncol`typ!(`symbol`iexBidPrice`iexAskPrice`iexBidSize`iexAskSize`mode`ex`latestUpdate;`sym`bid`ask`bsize`asize`mode`ex`srctime;"SffjjCCn");

\d .


