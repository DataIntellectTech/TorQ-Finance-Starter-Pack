changetotab:{[t;x]flip cols[t]!x}; 																														  / Flip list into correct table schema

upd:{[t;x].wap.tabfuncs[t][t;changetotab[t;x]]};                                                / Replay Upd

\d .wap
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                       / List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                               / Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                     / Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`];	                                                          / A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                        / A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                   / Number of seconds between attempts to connect to the tp
summary:([sym:()]time:();price:();size:());                                                     / Summary table schema
tabfuncs:()!();																																									/ Define dictionary for upd functions
tabfuncs[`trade`trade_iex]:{[t;x]@[`.wap.summary;asc([]sym:distinct x`sym);,';value exec (time;price;size) by sym from x];t insert x};
tabfuncs[`quote`quote_iex`srcquote`clienttrade]:{[t;x]t insert x};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                  
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                 / Call subscribe function and save info
    @[`.wap;key subinfo;:;value subinfo];                                                       / Setting subtables and tplogdate globals
    ];
  };

upd:{[t;x]tabfuncs[t][t;x]}; 																																		/ Generic upd
																									
notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .wap.tickerplanttypes,active};

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
