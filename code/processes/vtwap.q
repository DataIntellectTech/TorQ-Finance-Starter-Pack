changetotab:{[t;x]flip cols[t]!x};                                                                                      / Flip list into correct table schema

upd:{[t;x].rtsub.tabfuncs[t][t;changetotab[t;x]]};                                                                      / Replay Upd

\d .rtsub

tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                                               / List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                                                       / Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                                             / Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`trade`trade_iex`srcquote`clienttrade];                                                / A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                                                / A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                                           / Number of seconds between attempts to connect to the tp
summary:([sym:()]time:();price:();size:());                                                                             / Summary table schema
tabfuncs:()!();                                                                                                         / Define dictionary for upd functions
                                                                                                                        
tabfuncs[`trade`trade_iex]:{[t;x]@[`.rtsub.summary;asc([]sym:distinct x`sym);                                           / redirect trade and trade_iex tables for wap formating
  ,';value exec (time;price;size) by sym from x];t insert x};
tabfuncs[`srcquote]:{[t;x].pnl.updsrcquote[t;x]};                                                                       / redirect srcquote and clienttrade tables for pnl calculation
tabfuncs[`clienttrade]:{[t;x].pnl.updclienttrade[t;x]};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                  
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                                         / Call subscribe function and save info
    @[`.rtsub;key subinfo;:;value subinfo];                                                                             / Setting subtables and tplogdate globals
    ];
  };

upd:{[t;x]tabfuncs[t][t;x]};                                                                                            / Generic upd                                                                                                                                                                                                   
notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .rtsub.tickerplanttypes,active};

\d .wap

waps:{[syms;st;et]                                                                                                      / Calculate time/volume weighted average price
  syms:(),syms;
  a:@'[x;i:{[x;y]x+til y-x}./:{[st;et;x]x bin (st;et)}[st;et;]each x:.rtsub.summary'[syms;`time]];
  :([]sym:syms;
    vwap:wavg'[@'[.rtsub.summary'[syms;`size];i];                                                                       / Calculate vwap
    @'[.rtsub.summary'[syms;`price];i]];twap:wavg'[(next'[a]-a);@'[.rtsub.summary'[syms;`price];i]]                     / Calculate twap
  );
 };

\d .pnl

tickmode:@[value;`tickmode;1b];                                                                                         / post mode
ticktime:@[value;`ticktime;`timestamp$0];                                                                               / last tick time
tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];                                                          / TP handle

shrtquote:([sym:`symbol$()]time:`timestamp$();src:`symbol$();bid:`float$();ask:`float$();bsize:`long$();                / last value cache quote table
  asize:`long$();mode:`char$();ex:`char$();qid:`long$());
shrttrade:([sym:`symbol$()]time:`timestamp$();price:`float$();size:`int$();side:`symbol$();position:`long$();           / last value cache trade table
  dcost:`float$();tid:`long$());
tidstp:qidstp:pnlidstp:0;                                                                                               / id stamps
pnlbatch:pnlsnap:([]time:`timestamp$();sym:`symbol$();tid:`long$();qid:`long$();pnlid:`long$();position:`long$();       
  dcost:`float$();pnl:`float$());                                                                                               

tppostback:{[t;x]tph(`.u.upd;t;value flip x)};                                                                          / function to post back to tickerplant

getlast:{0^shrttrade'[x]y};                                                                                             / function to get the last value from trade fields, .i.e last position/dcost

updclienttrade:{[t;x]                                                                                                   / upd for clienttrade table, calculates pnl
  tsnap:ungroup update tid:.pnl.tidstp+i from                                                                           / calculate required fields for pnl calculation
    select time:last time,price,size,side,position:last position,dcost:last dcost by sym from 
      update position:.pnl.getlast[sym;`position]+sum size*?[side=`BUY;1;-1],                                             
        dcost:.pnl.getlast[sym;`dcost]+sum price*size*?[side=`BUY;-1;1] by sym from x;
 
  .pnl.ticktime:last x`time;                                                    
  tppostback[`pnltrade;`time`sym xcols tsnap];                                                                          / post back trade table to TP with tid
  `.pnl.shrttrade upsert tsnap:select by sym from tsnap;
  pnlcalc[tsnap;delete time from shrtquote];                                                                            / push data to pnl calculator                                                           
  .pnl.tidstp+:count exec distinct tid from tsnap;
 };

updsrcquote:{[t;x]                                                                                                      / upd for srcquote table, calculates pnl
  qsnap:update qid:.pnl.qidstp+i from x;                                                
  `.pnl.shrtquote upsert select by sym from qsnap;                                                                      / update last value cache quote table ###update to BBO book for release###
  tppostback[`pnlquote;qsnap];                                                                                          / post back quote table to TP with qid
  .pnl.qidstp+:count qsnap;
  pnlcalc[shrttrade;shrtquote];                                                                                         / push data to pnl calculator
 };

updbbo:{[t;x]                                                                                                           / placeholder function for BBO book upd
  
 };

pnlcalc:{[td;qt]                                                                                                        / function to calculate pnl
  pnl:select time,sym,tid,qid,pnlid,position,dcost,pnl from                                                             / calculate pnl by sym for each new trade/quote record
    update pnlid:.pnl.pnlidstp+i,pnl:0^dcost+position*?[1=signum position;bid;ask]from lj[td;qt];
  pnl,:select last time,sym:`TOTAL,pnlid:1+last pnlid,dcost:(0^last .pnl.pnlsnap`dcost)+sum dcost,                      / generate record for pseudosym TOTAL
    pnl:(0^last .pnl.pnlsnap`pnl)+sum pnl from pnl;
  
  .pnl.pnlidstp+:count pnl;
  $[tickmode;                                                                                                           
    (.pnl.pnlsnap:pnl;tppostback[`pnltab;pnl]);                                                                         / save last value cache for pnl, post pnl records to TP
    pnlbatch,:pnl                                                                                                       / batch up pnl to be sent off at regular intervals
   ];
 };

setbatchtimer:{update period:0D+`second$x from `.timer.timer where (`$description)=`$"batch mode calculation"};         / function to set batch post period

batchpost:{                                                                                                             / function to post batched data to TP
  tppostback[`pnltab;pnlbatch];
  .pnl.pnlbatch:0#pnlbatch;                                                                                             / empty batch table
 };

modeswitch:{                                                                                                            / function to switch between tick by tick and batch modes
  .pnl.tickmode:not tickmode;   
  update active:not active from `.timer.timer where (`$description)in`$("batch mode calculation";"refresh pnl");
 };

refreshpnl:{if[0D00:00:10<.z.p-ticktime;tppostback[pnltab;pnlsnap]]};                                                   / function to resend previous pnl tick

staticcalc:{[td;qt]                                                                                                     / function for calculation of pnl for static date
  pnl:aj[`sym`time;
    update position:sums size*?[side=`BUY;1;-1],dcost:sums price*size*?[side=`BUY;-1;1] by sym from
      select time,sym,price,size,side,tid:.pnl.tidstp+i from td;
    select time,sym,src,bid,ask,qid:0 from qt
   ];
  :update pnlid:i from update totalpnl:sums r from update r:deltas pnl by sym from  
    update pnl:0^dcost+position*?[1=signum position;bid;ask]from pnl;
 };

recreate:{[pt]                                                                                                          / function to recreate pnl post-rollover
  hh:.servers.gethandlebytype[`hdb;`any];
  :staticcalc .{x({[x;y]select from x where date=y};z;y)}[hh;pt]'[`clienttrade`srcquote];
 };

\d .

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.rtsub.tickerplanttypes;
.lg.o[`init;"searching for servers"]; 
.servers.startup[];
.rtsub.subscribe[];                                                                                                     / Subscribe to the tickerplant
while[                                                                                                                  / Check if the tickerplant has connected, block the process until a connection is established
  .rtsub.notpconnected[];
  .os.sleep .rtsub.tpconnsleepintv;                                                                                     / While no connected make the process sleep for X seconds and then run the subscribe function again
  .servers.startup[];                                                                                                   / Run the servers startup code again (to make connection to discovery)
  .rtsub.subscribe[];
  ];

upd:.rtsub.upd;

.pnl.tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];                                                     / tph handle
.timer.repeat["p"$.z.d+1;0W;1D;({{x set 0#value x}'[x]};`.pnl.shrttrade`.pnl.pnlsnap);"flush last trade value cache"]; 
.timer.repeat[.z.p;0W;0D00:00:02;.pnl.refreshpnl;"refresh pnl"];                                                        / set refresh timer job
.timer.repeat[.z.p+1000000000;0W;0D+`second$5;(.pnl.batchpost;.pnl.pnlbatch);"batch mode calculation"];                 / set batch timer job                     
update active:not active from `.timer.timer where (`$description)=`$"batch mode calculation";                           / make batch timer job inactive by default

