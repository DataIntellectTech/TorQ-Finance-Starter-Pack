tab:flip`time`sym`price`size`stop`cond`ex!();

upd:{[t;x]
  if[t<>`trade;:()];
  .vtwap.upd[t;tab upsert@[flip;x;enlist x]];
 };

\d .vtwap
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                              // list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                                      // replay the tickerplant log file
schema:@[value;`schema;0b];                                                                            // retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`trade`trade_iex];                                                    // a list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                               // a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                          // number of seconds between attempts to connect to the tp
timediff:@[value;`timediff;(`$())!()];
data:@[value;`data;(`$())!()];
state:@[value;`state;([sym:`symbol$()]time:`timestamp$();pxsz:`float$();size:`int$())];

upd:{[t;x]
  if[t<>`trade;:()];
  syms:exec distinct sym from x;
  .vtwap.currenttime:first x`time;
  if[count .vtwap.state;
    p:exec deltas[.vtwap.currenttime^.vtwap.state[first sym]`time;time]by sym from x;
    @[`.vtwap.timediff;key p;,;value p];
    ];
  .vtwap.a:exec                                                                                        // extract data and add to lists
    (time;price;
    sums[size]+0i^.vtwap.state[first sym]`size;
    sums[price*size]+0f^.vtwap.state[first sym]`pxsz)
    by sym from x;
  @[`.vtwap.data;key .vtwap.a;,';value .vtwap.a];
  `.vtwap.state upsert select                                                                          // keep state
    last time,pxsz:sum[price*size]+0f^.vtwap.state[first sym]`pxsz,
    size:sum[size]+0i^.vtwap.state[first sym]`size
    by sym from x;
 };

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];                          // set the date that was returned by the subscription code i.e. the date for the tickerplant log file
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];                        // and a list of the tables that the process is now subscribing for
    @[`.vtwap;key subinfo;:;value subinfo];                                                            // setting subtables and tplogdate globals
    ];
 };

notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .vtwap.tickerplanttypes,active};

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

getvwap:{[syms;tm]                                                                                     // list of syms, tm=previous time (00:10)
  st:.z.p-tm;et:.z.p;                                                                                  // get times as timestamp
  :raze{[st;et;sym]
    i:@[bin[.vtwap.data[sym;0];(st;et)];0;+;1];                                                        // get indexes
    :([]enlist sym;vwap:last[deltas .vtwap.data[sym;3;i]]%last[deltas .vtwap.data[sym;2;i]])
   }[st;et]'[syms];
 };

gettwap:{[syms;tm]                                                                                     // list of syms, tm=previous time (00:10)
  st:.z.p-tm;et:.z.p;
  :raze{[st;et;sym]
    i:bin[.vtwap.data[sym;0];(st;et)];
    pi:i[0]+til 1+i[1]-i 0;                                                                            // get indexes of prices
    ti:1_pi;                                                                                           // get indexes of times
    times:(.vtwap.data[sym;0;ti 0]-st),.vtwap.timediff[sym;-1_ti],et-.vtwap.data[sym;0;last ti];       // get correct time differences for full period
    :([]enlist sym;vwap:sum[times*.vtwap.data[sym;1;pi]]%et-st);
   }[st;et]'[syms];
 };
