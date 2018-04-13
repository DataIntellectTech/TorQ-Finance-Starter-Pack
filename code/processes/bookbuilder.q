changetotab:{[t;x]flip cols[t]!x};                                                              //Flip list into correct table schema

upd:{[t;x].bbo.tabfuncs[t][t;changetotab[t;x]]};                                                //Replay Upd

\d .bbo
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                                       //List of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                                                               //Replay the tickerplant log file
schema:@[value;`schema;1b];                                                                     //Retrieve the schema from the tickerplant
subscribeto:@[value;`subscribeto;`srcquote];                                                    //A list of tables to subscribe to, default (`) means all tables
subscribesyms:@[value;`subscribesyms;`];                                                        //A list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];                                                   //Number of seconds between attempts to connect to the tp
tabfuncs:()!();                                                                                 //Define dictionary for upd functions
tabfuncs[`srcquote]:{[t;x]t insert x;update id:i from t;buildbk[]};

subscribe:{[]
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    .lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
    subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;0b;first s];                        //Call subscribe function and save info
    @[`.bbo;key subinfo;:;value subinfo];                                                       //Setting subtables and tplogdate globals
   ];
 };

upd:{[t;x]tabfuncs[t][t;x]};                                                                    //Generic upd

notpconnected:{0=count select from .sub.SUBSCRIPTIONS where proctype in .bbo.tickerplanttypes,active};

state:([sym:`symbol$();src:`symbol$()]price:`float$();size:`long$();id:`int$());

func:{[x;y;z] x:z[`price] x upsert`sym`src`price`size`id!(y[1 0 4 3 5]); x};

\d .

.servers.CONNECTIONS:distinct(.servers.CONNECTIONS,.bbo.tickerplanttypes);
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

.bbo.buildbk:{
  `book insert update bidbook:{[f;x;y]f[x;y;xdesc]}[.bbo.func]\[.bbo.state;flip(src;sym;time;bsize;bid;id)],
   askbook:{[f;x;y]f[x;y;xasc]}[.bbo.func]\[.bbo.state;flip(src;sym;time;asize;ask;id)]
  by sym 
  from update `s#id,`s#time,`g#sym from srcquote;
  @[`.;`book;,';(raze exec{[x]select bbid:first price,bbsrcs:src,bbsize:size,bblp:id from x where price=max 0w^price}'[bidbook] from book)
  ,'(raze exec{[x]select bask:first price,basrcs:src,basize:size,balp:id from x where price=min 0w^price}'[askbook] from book)]
 };
