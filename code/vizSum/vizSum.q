//DEFINE schema for tables 
clienttradeLVC:([sym:`$()]time:`timestamp$();price:`float$();size:`int$();stop:`boolean$();cond:`char$();ex:`char$();side:`$()); 						
srcquoteLVC:([sym:`$()]time:`timestamp$();src:`$();bid:`float$();ask:`float$();bsize:`long$();asize:`long$();mode:`char$();ex:`char$());  					
srcquoteMid:([]time:`timestamp$();sym:`$();src:`$();bid:`float$();ask:`float$();bsize:`long$();asize:`long$();mode:`char$();ex:`char$();midPrice:`float$();midSize:`float$());  
   
\d .summary
tabfuncs:()!(); 																			    	//CREATE empty dictionary 
tabfuncs[`clienttrade]:{[t;x]										
  `sym xasc`clienttradeLVC upsert`sym xkey x;        																//Upsert last value cached and sort by sym 
  }; 

tabfuncs[`srcquote]:{[t;x]
  `sym xasc`srcquoteLVC upsert`sym xkey x;																	//Upsert last value cached and sort by sym
  `srcquoteMid upsert update midPrice:(ask+bid)%2,midSize:(asize+bsize)%2 from x};												//Calculate the midPrice,midSize and upsert to srcquoteMid

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
  t insert x; 																					//Default tables clienttrade and srcquote will be kept in memory
  tabfuncs[t][t;x] 
 };

//Subscribe to all available tickerplants 
subscribe:{[] 
  if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()]; 
  subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s]; 
  @[`.summary;;:;]'[key subinfo;value subinfo]]
 };

//Check if successfully connected to tickerplant 
notpconnected:{[]
  0 = count select from .sub.SUBSCRIPTIONS where proctype in .summary.tickerplanttypes, active
 };
\d . 

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.summary.hdbtypes,.summary.tickerplanttypes;

upd:.summary.upd;  

HDBC:{
  hdbhand:exec first w from .sub.getsubscriptionhandles[.summary.hdbtypes;();()!()];												//Get handle for hdb 
  a:(hdbhand("tables[]"))except .summary.ignorelist;																//Get list of tables in hdb and assign to a
  f:{[x]`date`table xkey update table:x from select cnt:count sym by date from select from x where date>=.z.d-3};							        //Get HDB counts for last 3 dates 
  HDBCount::`date xasc raze {x uj y}\[{[h;func;x]h(func;x)}[hdbhand;f]'[a]]                                                                                                     //Count records in tables by date
 };

.servers.startup[];

.summary.subscribe[];

while[.summary.notpconnected[]; 
  .os.sleep[.summary.tpconnsleepintv];
  .servers.startup[];
  .summary.subscribe[];
  ]

HDBC[];
