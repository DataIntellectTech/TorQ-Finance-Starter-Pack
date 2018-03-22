tab:flip`time`sym`price`size`stop`cond`ex!();
upd:{[t;x]
  if[t<>`trade;:()];
  syms:distinct x 1;
  .vtwap.data:@[value;`.vtwap.data;syms!()];
  .vtwap.addrows[`.vtwap.data;exec([]time;price;size)by sym from (tab upsert @[flip;x;enlist x])]'[syms];
 };

\d .vtwap
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                              // list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                                      // replay the tickerplant log file
schema:@[value;`schema;0b];                                                                            // retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`trade`trade_iex];                                                    // a list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                               // a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                          // number of seconds between attempts to connect to the tp

upd:{[t;x]
  if[t<>`trade;:()];
  syms:exec distinct sym from x;
  .vtwap.data:@[value;`.vtwap.data;syms!()];
  addrows[`.vtwap.data;exec([]time;price;size)by sym from x]'[syms];
 };

addrows:{[tab;x;y]@[tab;y;upsert;x y]};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                          // set the date that was returned by the subscription code i.e. the date for the tickerplant log file
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                        // and a list of the tables that the process is now subscribing for
    @[`.vtwap;key subinfo;:;value subinfo];                                                            // setting subtables and tplogdate globals
    ];
 };
notpconnected:{[]
    :0 = count select from .sub.SUBSCRIPTIONS where proctype in .vtwap.tickerplanttypes, active;
 };
\d .
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.vtwap.tickerplanttypes

.lg.o[`init;"searching for servers"];
.servers.startup[]; 
.vtwap.subscribe[];                                                                                    // subscribe to the tickerplant
while[                                                                                                 // check if the tickerplant has connected, block the process until a connection is established
  .vtwap.notpconnected[];
  .os.sleep .vtwap.tpconnsleepintv;                                                                    // while no connected make the process sleep for X seconds and then run the subscribe function again
  .servers.startup[];                                                                                  // run the servers startup code again (to make connection to discovery)
  .vtwap.subscribe[];
  ];

upd:.vtwap.upd;                                                                                        // set the upd function in the top level namespace

getvwap:{[syms;st;et]                                                                                  // calculate VWAP for a list of syms. st and et as times
  :raze{[st;et;sym]
    :([]enlist sym),'
    select vwap:size wavg price from .vtwap.data[sym]
      where time within(st;et);
  }[st;et]'[syms];
 };

gettwap:{[syms;st;et]										       // calculate TWAP for a list of syms. se and et as times
  :raze{[st;et;sym]
    i:bin[t:"n"$(d:.vtwap.data sym)`time;(st;et)];						       // get first and last index of times
    ind:i[0]+til i[1]+1-i 0;									       // get full list of indices
    :([]enlist sym;enlist twap:deltas[st;1_t[ind],et]wavg d[`price]ind);                              
   }["n"$st;"n"$et]'[syms];
  };
