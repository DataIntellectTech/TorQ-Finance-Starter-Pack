/ schemas for tables
sumstab:([] time:`timestamp$(); sym:`g#`symbol$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());
latest:([sym:`u#`symbol$()] time:`timestamp$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());

\d .metrics

/ load settings
windows:@[value;`windows;0D00:01 0D00:05 0D01];
enableallday:@[value;`enableallday;1b];
tickerplanttypes:@[value;`tickerplanttypes;`segmentedtickerplant];
rdbtypes:@[value;`rdbtypes;`rdb];
tpconsleep:@[value;`tpconsleep;10]; 
requiredprocs:rdbtypes,tickerplanttypes; 
tpcheckcycles:@[value;`tpcheckcycles;0W]; 
rdbconnsleep:@[value;`rdbconnsleep;10];

\d .

/ define upd to keep running sums
upd:{[t;x]
   / join latest to x, maintaining time col from x, then calc running sums
   r:ungroup select time,sumssize:(0^sumssize)+sums size,sumsps:(0^sumsps)+sum price*size,sumspricetimediff:(0^sumspricetimediff)+sums price*0^deltas[first lt;time] by sym from x lj delete time from update lt:time from latest;
   / add latest values for each sym from r to latest
   latest,::select by sym from r;
   / add records to sumstab for all records in update message
   sumstab,::`time`sym xcols 0!r
 }

/ function to calc twap/vwap
/ calculates metrics for windows in .metrics.windows
metrics:{[syms]
   / allow calling function with ` for all syms
   syms:$[syms~`;exec distinct sym from latest;syms,()];
   / metric calcs
   t:select sym,timediff,vwap:(lsumsps-sumsps)%lsumssize-sumssize,twap:(lsumspricetimediff-sumspricetimediff)%.z.p - time
     / get sums asof time each window ago
     from aj[`sym`time;([]sym:syms) cross update time:.z.p - timediff from ([]timediff:.metrics.windows);sumstab] 
          / join latest sums for each sym
          lj 1!select sym,lsumssize:sumssize, lsumsps:sumsps, lsumspricetimediff:sumspricetimediff from latest;

   / add allday window
   if[.metrics.enableallday;
     if[not all syms in key .metrics.start;.metrics.start::exec first time by sym from sumstab];
     t:`sym`timediff xasc t,select sym,timediff:0Nn,vwap:sumsps%sumssize,twap:sumspricetimediff%.z.p - .metrics.start[sym] from latest where sym in syms
   ]; 
   :t;  
 }

// Define top-level functions for receiving messages from an STP
endofperiod:{[currp;nextp;data] .lg.o[`endofperiod;"Received endofperiod. currentperiod, nextperiod and data are ",(string currp),", ", (string nextp),", ", .Q.s1 data]};
endofday:{[dt;data] .lg.o[`endofday;"Received endofday for ",string dt]};

\d .metrics 

/ get handle for TP & subscribe
subscribe:{
   / exit if no handles found
   if[0=count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];:()];
   subproc:first s;
   / subsribe to trade table
   .lg.o[`subscribe;"subscribing to ", string subproc`procname];
   .sub.subscribe[`trade;`;0b;0b;subproc]
 }

/ get subscribed to TP, recover up until now from RDB
init:{
  r:subscribe[];
 
  // Block process until all required processes are connected
  .servers.startupdepcycles[requiredprocs;tpconsleep;tpcheckcycles]; 
  r:subscribe[]; 
  / check if updates have already been sent from TP, if so recover from RDB
  if[0<r[`icounts]`trade;
   / get handle for RDB
   h:exec first w from s:.sub.getsubscriptionhandles[rdbtypes;();()!()];
   .lg.o[`recovery;"recovering ",(a:string r[`icounts]`trade)," records from trade table on ",string first s`procname];
   / query data from before subscription from RDB
   t:h"select time,sym,size,price from trade where i<",a;
   .lg.o[`recovery;"recovered ",(string count t)," records"];
   / insert data recovered from RDB into relevant tables
   t:select time,sym,sumssize,sumsps,sumspricetimediff from update sumssize:sums size,sumsps:sums price*size,sumspricetimediff:sums price*time-prev time by sym from t;
   @[`.;`sumstab;:;t];
   @[`.;`latest;:;select by sym from t];
   ];

   / setup empty start dict for use in all day calculation
   start::()!();
 }

\d .

/ get connections to TP, & RDB for recovery
.servers.CONNECTIONS:.metrics.rdbtypes,.metrics.tickerplanttypes;
.servers.startup[];
/ run the initialisation function to get subscribed & recover
.metrics.init[];
