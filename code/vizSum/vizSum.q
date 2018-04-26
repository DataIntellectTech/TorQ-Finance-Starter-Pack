//DEFINE schema for tables 
clienttradeLVC:([sym:`$()]time:`timestamp$();price:`float$();size:`int$();stop:`boolean$();cond:`char$();ex:`char$();side:`$()); 				
srcquoteLVC:([sym:`$()]time:`timestamp$();src:`$();bid:`float$();ask:`float$();bsize:`long$();asize:`long$();mode:`char$();ex:`char$()); 
BSPressure:([sym:`$()]time:`timestamp$();price:`float$();size:`long$();stop:`boolean$();cond:`char$();ex:`char$();side:`$();press:`long$();ind:`long$();pressure:`float$());

\d .summary
tabfuncs:()!(); 
tabfuncs[`clienttrade]:{[t;x]
 `sym xasc`clienttradeLVC upsert`sym xkey x
 };
 
tabfuncs[`srcquote]:{[t;x]
 `sym xasc`srcquoteLVC upsert`sym xkey x
 }; 

//Setting Default values 
hdbtypes:@[value;`hdbtypes;`hdb]; 
hdbnames:@[value;`hdbnames;()];
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];
replaylog:@[value;`replaylog;0b];
schema:@[value;`schema;0b]; 
subscribeto:@[value;`subscribeto;`clienttrade`srcquote];
ignorelist:@[value;`ignorelist;`heartbeat`logmsg];
subscribesyms:@[value;`subscribesyms;`]; 
tpconnsleepintv:@[value;`tpconnsleepintv;10];

//Define upd function 
upd:{[t;x]
 t insert x;
 tabfuncs[t][t;x];
 };

//Subscribe to all available tickerplants 
subscribe:{[] 
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()]; 
  subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s]; 
  @[`.summary;;:;]'[key subinfo;value subinfo]]
 };

//Check if successfully connected to tickerplant 
notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .summary.tickerplanttypes,active};
\d . 

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.summary.hdbtypes,.summary.tickerplanttypes;

upd:.summary.upd; 

//takes the last 10 values for a given table 
last10TQ:{update ind:i from -10#value x}

//counts the occurances of each sym in a given table
occurences:{[st;et;table]
 select occ:100*(count ind)%count value table by sym from update ind:i from value table where time within(st;et)
 }

//sets default values for time if they are not provided and adds spread, midprice and midsize to the srcquote table
srcQuoteUpd:{[st;et]
 if[prd 00:00~'(st;et);st:exec first time from srcquote;et:.z.P];
 a:update spread:ask-bid,midprice:%[bid+ask;2],midsize:%[bsize+asize;2] from srcquote where time within(st;et)
 }

//sets default values for time if they are not provided and adds volume and volatility to the clienttrade table 
clienttradeUpd:{[st;et]
 if[prd 00:00~'(st;et);st:exec first time from clienttrade;et:.z.P]; 
 a:update volume:price*size,volatility:0^{100*(log y%x)xexp 2}':[price] by sym from clienttrade where time within(st;et) 
 }

//computes the buy/sell pressure
buySellPressure:{
 `BSPressure upsert`sym xkey update pressure:100*press%ind from update press:sums press,ind:sums ind by sym from update press:{$[`BUY~x;1;-1]}'[side],ind:1 from clienttrade;BSPressure 
 }

//counts the number of records by table for the past 7 days 
HDBC:{
  hdbhand:exec first w from .sub.getsubscriptionhandles[.summary.hdbtypes;();()!()];
  a:(hdbhand("tables[]"))except .summary.ignorelist;
  f:{[x]`date`table xkey update table:x from select cnt:count sym by date from select from x where date>=.z.d-7};break; 
  HDBCount::`date xasc raze {x uj y}\[{[h;func;x]h(func;x)}[hdbhand;f]'[a]]
 };

.servers.startup[];

.summary.subscribe[];

while[.summary.notpconnected[]; 
  .os.sleep[.summary.tpconnsleepintv];
  .servers.startup[];
  .summary.subscribe[];
  ]

HDBC[];
