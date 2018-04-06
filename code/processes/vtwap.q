changetotab:{[t;x]flip cols[t]!x}; 																														  / Flip list into correct table schema

upd:{[t;x].wap.tabfuncs[t][t;changetotab[t;x]]};                                                / Replay Upd

\d .wap
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                       / List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;0b];                                                               / Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                     / Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`];	                                                          / A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                        / A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                   / Number of seconds between attempts to connect to the tp
summary:([sym:()]time:();price:();size:());                                                     / Summary table schema
tabfuncs:()!();																																									/ Define dictionary for upd functions
tabfuncs[`trade`trade_iex]:{[t;x]@[`.wap.summary;asc([]sym:distinct x`sym);,';value exec (time;price;size) by sym from x];t insert x};
tabfuncs[`srcquote`clienttrade]:{[t;x] if[.pnl.tickmode=1b;.pnl.updtick[t;x]]};
tabfuncs[`quote`quote_iex`pnltab]:{[t;x]t insert x};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                  
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                 / Call subscribe function and save info
    @[`.wap;key subinfo;:;value subinfo];                                                       / Setting subtables and tplogdate globals
    ];
  };

upd:{[t;x]tabfuncs[t][t;x]}; 																																		/ Generic upd
																									
notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .wap.tickerplanttypes,active};

\d .pnl

tickmode:@[value;`tickmode;1b];
ticktime:@[value;`ticktime;`timestamp$0];
quote:([sym:`symbol$()]src:`symbol$();bid:`float$();ask:`float$());
trade:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$();side:`symbol$();position:`long$();dcost:`float$());
pnltab:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$();side:`symbol$();position:`long$();dcost:`float$();src:`symbol$();bid:`float$();ask:`float$();pnl:`float$();r:`float$();totpnl:`float$());
tph:@[value;`tph;.servers.gethandlebytype[`tickerplant;`any]];

updtick:{[t;x]
  if[t=`clienttrade;
    /lstpos:(exec last position by sym from pnltab);
    /lstdcost:(exec last dcost by sym from pnltab);
    /.pnl.trade:update dcost:?[sym in key lstdcost;lstdcost sym;0]+sums price*size*?[side=`BUY;-1;1], position:?[sym in key lstpos;lstpos sym;0]+sums size*?[side=`BUY;1;-1] by sym from 
     /             select time,sym,price,size,side from x;
    .pnl.trade:update dcost:sums price*size*?[side=`BUY;-1;1],position:sums size*?[side=`BUY;1;-1] by sym from 
      select time,sym,price,size,side from x;
    .pnl.ticktime:first x`time;
    pnlcalc[.pnl.trade;.pnl.quote];
    
   ];
  if[t=`srcquote;
    `.pnl.quote upsert `sym xkey select sym,src,bid,ask from select by sym from x;
   ];
 };

pnlcalc:{[td;qt]
  scount:count select by sym from .pnl.pnltab;
  pnl:scount _ update totpnl:sums r by sym from
        update r:0^deltas pnl by sym from
          uj[`time`sym xcols 0!select by sym from .pnl.pnltab;
             update pnl:dcost+position*?[1=signum position;ask;bid]from td lj qt];
  pnltab,:pnl;
  /.u.upd[`pnltab;flip pnl];
 };

\d .

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.wap.tickerplanttypes;
.lg.o[`init;"searching for servers"]; 
.servers.startup[];
.wap.subscribe[];                                                                               / Subscribe to the tickerplant
while[                                                                                        	 / Check if the tickerplant has connected, block the process until a connection is established
  .wap.notpconnected[];
  .os.sleep .wap.tpconnsleepintv;                                                               / While no connected make the process sleep for X seconds and then run the subscribe function again
  .servers.startup[];                                                                         	 / Run the servers startup code again (to make connection to discovery)
  .wap.subscribe[];
  ];

upd:.wap.upd;

waps:{[syms;st;et]																																							/ Calculate time/volume weighted average price			
  syms:(),syms;
  a:@'[x;i:{[x;y]x+til y-x}./:{[st;et;x]x bin (st;et)}[st;et;]each x:.wap.summary'[syms;`time]];
  :([]sym:syms;
    vwap:wavg'[@'[.wap.summary'[syms;`size];i];                                                 / Calculate vwap
    @'[.wap.summary'[syms;`price];i]];twap:wavg'[(next'[a]-a);@'[.wap.summary'[syms;`price];i]] / Calculate twap
  );
 };
