changetotab:{[t;x]flip cols[t]!x}; 											/ Flip list into correct table schema

upd:{[t;x].wap.tabfuncs[t][t;changetotab[t;x]]};                                                			/ Replay Upd

\d .wap
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                       			/ List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;0b];                                                               			/ Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                     			/ Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`];	                                                          			/ A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                        			/ A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                   			/ Number of seconds between attempts to connect to the tp
summary:([sym:()]time:();price:();size:());                                                     			/ Summary table schema
tabfuncs:()!();														/ Define dictionary for upd functions
															
tabfuncs[`trade`trade_iex]:{[t;x]@[`.wap.summary;asc([]sym:distinct x`sym);,';value exec (time;price;size) by sym from x];t insert x};
tabfuncs[`srcquote]:{[t;x].pnl.updsrcq[t;x]};
tabfuncs[`clienttrade]:{[t;x].pnl.updclientt[t;x]};
tabfuncs[`quote`quote_iex`pnltab`pnltrade`pnlquote]:{[t;x](::)};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                  
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                 			/ Call subscribe function and save info
    @[`.wap;key subinfo;:;value subinfo];                                                       			/ Setting subtables and tplogdate globals
    ];
  };

upd:{[t;x]tabfuncs[t][t;x]}; 												/ Generic upd																									
notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .wap.tickerplanttypes,active};

\d .pnl

tickmode:@[value;`tickmode;1b];												/ post mode
ticktime:@[value;`ticktime;`timestamp$0];										/ last tick time
tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];								/ TP handle

shrtquote:([sym:`symbol$()]time:`timestamp$();src:`symbol$();bid:`float$();ask:`float$();bsize:`long$();asize:`long$();mode:`char$();ex:`char$();qid:`long$());
shrttrade:([sym:`symbol$()]time:`timestamp$();price:`float$();size:`int$();side:`symbol$();position:`long$();dcost:`float$();tid:`long$());
/shrttrade:`sym xkey flip`time`sym`price`size`size`position`dcost`tid!();
/shrtquote:`sym xkey flip`time`sym`src`bid`ask`bsize`asize`mode`ex`qid!();
tidstp:0;														/ trade id
qidstp:0;														/ ### REMOVE IN RELEASE ###
pnlidstp:0;														/ pnl id
pnlsnap:([]time:`timestamp$();sym:`symbol$();tid:`long$();qid:`long$();pnlid:`long$();
  position:`long$();dcost:`float$();pnl:`float$());
pnlbatch:pnltab:pnlsnap;													

getlast:{0^shrttrade'[x]y};												/ function to get the last value from trade fields, .i.e last position/dcost

updclientt:{[t;x]				 									/ upd for clienttrade table, calculates pnl
  tsnap:ungroup update tid:.pnl.tidstp+i from 
    select time:last time,price,size,side,position:last position,dcost:last dcost by sym from 
    update position:.pnl.getlast[sym;`position]+sum size*?[side=`BUY;1;-1],						/ calculate required fields for pnl calculation
    dcost:.pnl.getlast[sym;`dcost]+sum price*size*?[side=`BUY;-1;1] by sym from x;
 
  .pnl.ticktime:last x`time;							
  `.pnl.shrttrade upsert select by sym from tsnap;
  pnlcalc[select by sym from tsnap;delete time from shrtquote];										/ push data to pnl calculator 			
  tph(`.u.upd;`pnltrade;value flip `time`sym xcols tsnap);										/ post back trade table to TP with tid								
  .pnl.tidstp+:count exec distinct tid from tsnap;
  
 };

updsrcq:{[t;x]														/ upd for srcquote table, calculates pnl
  qsnap:update qid:.pnl.qidstp+i from x;						
  `.pnl.shrtquote upsert select by sym from qsnap;										/ update last value cache quote table ###update to BBO book for release###
  tph(`.u.upd;`pnlquote;value flip qsnap);										/ post back quote table to TP with qid
  .pnl.qidstp+:count qsnap;
  
  /pnlcalc[`time`sym xcols 0!shrttrade;quote];
 };

pnlcalc:{[td;qt]													/ function to calculate pnl
  pnl:select time,sym,tid,qid,pnlid,position,dcost,pnl from    
    update pnlid:.pnl.pnlidstp+i,pnl:0^dcost+position*?[1=signum position;bid;ask]from lj[td;qt];
 
  pnl,:select last time,sym:`TOTAL,pnlid:1+last pnlid,dcost:(0^last[.pnl.pnlsnap`dcost])+sum dcost,
    pnl:(0^last[.pnl.pnlsnap`pnl])+sum pnl from pnl;
 
  .pnl.pnltab,:pnl;
  .pnl.pnlidstp+:count pnl;													
    $[tickmode;														/ either save snapshot or batch up pnl
    (.pnl.pnlsnap:pnl;
    tph(`.u.upd;`pnltab;value flip pnl));
    pnlbatch,:pnl
   ];
 };

setbatchtimer:{update period:0D+`second$x from `.timer.timer where (`$description)=`$"batch mode calculation"};		/ function to set batch post period

batchpost:{														/ function to post batched data to TP
  tph(`.u.upd;`pnltab;value flip pnlbatch);
  .pnl.pnlbatch:0#pnlbatch;												/ empty batch table
 };

modeswitch:{														/ function to switch between tick by tick and batch modes
  .pnl.tickmode:not tickmode;	
  update active:not active from `.timer.timer where (`$description)in`$("batch mode calculation";"refresh pnl");
 };

refreshpnl:{if[0D00:00:10<.z.p-ticktime;tph(`.u.upd;`pnltab;value flip pnlsnap)]};					/ function to resend previous pnl tick

staticcalc:{[td;qt]													/ function for calculation of pnl for static date
  pnl:aj[`sym`time;
    update position:sums size*?[side=`BUY;1;-1],dcost:sums price*size*?[side=`BUY;-1;1] by sym from
    select time,sym,price,size,side,tid:.pnl.tidstp+i from td;
    select time,sym,src,bid,ask,qid:0 from qt
   ];
  :update pnlid:i from update totalpnl:sums r from update r:deltas pnl by sym from  
    update pnl:0^dcost+position*?[1=signum position;bid;ask]from pnl;
 };

recreate:{[pt]														/ function to recreate pnl post-rollover
  hh:.servers.gethandlebytype[`hdb;`any];
  :staticcalc[hh({select from `clienttrade where date=x};pt);hh({select from `srcquote where date=x};pt)];
 };

\d .

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.wap.tickerplanttypes;
.lg.o[`init;"searching for servers"]; 
.servers.startup[];
.wap.subscribe[];                                                                               			/ Subscribe to the tickerplant
while[                                                                                        	 			/ Check if the tickerplant has connected, block the process until a connection is established
  .wap.notpconnected[];
  .os.sleep .wap.tpconnsleepintv;                       			                                        / While no connected make the process sleep for X seconds and then run the subscribe function again
  .servers.startup[];                                                            		             	 	/ Run the servers startup code again (to make connection to discovery)
  .wap.subscribe[];
  ];

upd:.wap.upd;

.pnl.tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];							/ tph handle
.timer.repeat[.z.p;0W;0D00:00:02;.pnl.refreshpnl;"refresh pnl"];							/ set refresh timer job
.timer.repeat[.z.p+1000000000;0W;0D+`second$5;(.pnl.batchpost;.pnl.pnlbatch);"batch mode calculation"];			/ set batch timer job
.timer.repeat["p"$.z.d+1;0W;1D;({x set 0#value x};'[(`.pnl.shrttrade;`.pnl.pnltrade;`.pnl.pnlquote)]);			/ set end of day flush of .pnl tables
  "flush last trade value cache"];				
update active:not active from `.timer.timer where (`$description)=`$"batch mode calculation";				/ make batch timer job inactive by default

waps:{[syms;st;et]													/ Calculate time/volume weighted average price			
  syms:(),syms;
  a:@'[x;i:{[x;y]x+til y-x}./:{[st;et;x]x bin (st;et)}[st;et;]each x:.wap.summary'[syms;`time]];
  :([]sym:syms;
    vwap:wavg'[@'[.wap.summary'[syms;`size];i]; 			                                                / Calculate vwap
    @'[.wap.summary'[syms;`price];i]];twap:wavg'[(next'[a]-a);@'[.wap.summary'[syms;`price];i]] 			/ Calculate twap
  );
 };
