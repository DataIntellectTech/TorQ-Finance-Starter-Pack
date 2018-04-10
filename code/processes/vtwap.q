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
tabfuncs[`quote`quote_iex`pnltab]:{[t;x]t insert x};

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
tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];

shrtquote:([sym:`symbol$()]src:`symbol$();bid:`float$();ask:`float$());							/ last value cache quote table
lngtrade:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$();side:`symbol$();tid:`long$();		/ full trade records
  position:`long$();dcost:`float$());
shrttrade:`sym xkey lngtrade;												/ last value cache trade table 
idstp:0;														/ trade id
pnlsnap:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$();side:`symbol$();tid:`long$();			/ pnl snapshot
  position:`long$();dcost:`float$();src:`symbol$();bid:`float$();ask:`float$();pnl:`float$();	
  r:`float$();totpnl:`float$());
pnlbatch:pnlsnap;													/ pnl batch
pnltab:pnlsnap;														/ full pnl records ###remove in release version###

getlast:{{?[null x;0;x]}@[shrttrade each x;y]};										/ function to get the last value from trade fields, .i.e last position/dcost

updclientt:{[t;x]														/ upd for pnl data
  tsnap:update position:.pnl.getlast[sym;`position]+sums size*?[side=`BUY;1;-1],					/ calculate required fields for pnl calculation
  dcost:.pnl.getlast[sym;`dcost]+sums price*size*?[side=`BUY;-1;1] by sym from
    select time,sym,price,size,side,tid:.pnl.idstp+i from x;
  lngtrade,:tsnap;													/ append trade snapshot to long records
  `.pnl.shrttrade upsert select by sym from tsnap;									/ update last value cache trade table
  .pnl.ticktime:first x`time;												
  pnlcalc[tsnap;shrtquote];												/ push data to pnl calculator
  .pnl.idstp+:count tsnap;												
 };

updsrcq:{[t;x]
  `.pnl.shrtquote upsert `sym xkey select sym,src,bid,ask from select by sym from x;					/ update last value cache quote table ###update to BBO book for release###
  /pnlcalc[`time`sym xcols 0!shrttrade;quote];
 };

pnlcalc:{[td;qt]													/ function to calculate pnl
  pnl:(count exec distinct sym from pnltab)_ update totpnl:sums r by sym from						
                update r:0^first[r]^pnl-prev[pnl] by sym from
                  uj[`time`sym xcols 0!select by sym from pnltab;
                    update pnl:dcost+position*?[1=signum position;bid;ask]from lj[td;qt]];
  pnltab,:pnl;														/ append to total pnl record
  $[tickmode;
    (pnl.pnlsnap:pnl;													/ either save snapshot or batch up pnl
    tph(`.u.upd;`pnltab;value flip pnl));
    pnlbatch,:pnl];
 };

setbatchtimer:{update period:0D+`second$x from `.timer.timer where (`$description)=`$"batch mode calculation"};		/ function to set batch post period

batchpost:{														/ function to post batched data to TP
  tph(`.u.upd;`pnltab;value flip pnlbatch);
  .pnl.pnlbatch:0#pnlbatch;												/ empty batch table
 };

modeswitch:{														/ function to switch between tick by tick and batch modes
  .pnl.tickmode:not tickmode;	
  update active:not active from `.timer.timer where (`$description)in(`$"batch mode calculation";`$"refresh pnl");
 };

refrpnl:{if[0D00:00:10<.z.p-ticktime;tph(`.u.upd;`pnltab;value flip pnlsnap)]};						/ function to resend previous pnl tick

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
.timer.repeat[.z.p;0W;0D00:00:02;.pnl.refrpnl;"refresh pnl"];								/ set refresh timer job
.timer.repeat[.z.p+1000000000;0W;0D+`second$5;(.pnl.batchpost;.pnl.pnlbatch);"batch mode calculation"];			/ set batch timer job
update active:not active from `.timer.timer where (`$description)=`$"batch mode calculation";				/ make batch timer job inactive by default

waps:{[syms;st;et]													/ Calculate time/volume weighted average price			
  syms:(),syms;
  a:@'[x;i:{[x;y]x+til y-x}./:{[st;et;x]x bin (st;et)}[st;et;]each x:.wap.summary'[syms;`time]];
  :([]sym:syms;
    vwap:wavg'[@'[.wap.summary'[syms;`size];i]; 			                                                / Calculate vwap
    @'[.wap.summary'[syms;`price];i]];twap:wavg'[(next'[a]-a);@'[.wap.summary'[syms;`price];i]] 			/ Calculate twap
  );
 };
