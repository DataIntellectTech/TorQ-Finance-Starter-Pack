changetotab:{[t;x]flip cols[t]!x};                                                              //Flip list into correct table schema

upd:{[t;x].bbo.tabfuncs[t][t;changetotab[t;x]]};                                                //Replay Upd

\d .bbo
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                       //List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                               //Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                     //Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`];                                                            //A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                        //A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                   //Number of seconds between attempts to connect to the tp
tabfuncs:()!();                                                                                 //Define dictionary for upd functions
tabfuncs[`trade`trade_iex`clienttrade`quote`quote_iex]:{[t;x]t insert x};
tabfuncs[`srcquote]:{[t;x]t insert x;build[t;x]};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                 //Call subscribe function and save info
    @[`.bbo;key subinfo;:;value subinfo];                                                       //Setting subtables and tplogdate globals
   ];
 };

upd:{[t;x]tabfuncs[t][t;x]};                                                                    //Generic upd

notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .bbo.tickerplanttypes,active};

\d .

.servers.CONNECTIONS:distinct(.servers.CONNECTIONS,.bbo.tickerplanttypes)except`rtd;
.lg.o[`init;"searching for servers"];
.servers.startup[];
.bbo.subscribe[];                                                                               //Subscribe to the tickerplant
while[                                                                                          //Check if the tickerplant has connected, block the process until a connection is established
  .bbo.notpconnected[];
  .os.sleep .bbo.tpconnsleepintv;                                                               //While no connected make the process sleep for X seconds then rerun the subscribe function
  .servers.startup[];                                                                           //Run the servers startup code again (to make connection to discovery)
  .bbo.subscribe[];
 ];

upd:.bbo.upd;


.bbo.build:{[t;x]
  state:([sym:`symbol$();src:`symbol$()] price:`float$();size:`long$());
  func:{[x;y;z] x:z[`price] x upsert `sym`src`price`size!(y[1 0 4 3]); x};
  `book set update bidbook:{[f;x;y]f[x;y;xdesc]}[func]\[state;flip(src;sym;time;bsize;bid)],
    askbook:{[f;x;y]f[x;y;xasc]}[func]\[state;flip(src;sym;time;asize;ask)]
  by sym 
  from srcquote;
 };
