/ time windows for metric calculations
windows:0D00:01 0D00:05 0D01;

/ schemas for tables
sumstab:([] time:`timestamp$(); sym:`g#`symbol$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());
latest:([sym:`u#`symbol$()] time:`timestamp$(); sumssize:`int$(); sumsps:`float$(); sumspricetimediff:`float$());

/ define upd to keep running sums
upd:{[t;x]
   / join latest to x, maintaining time col from x, then calc running sums
   r:ungroup select time,sym,sumssize:(0^sumssize)+sums size,sumsps:(0^sumsps)+sum price*size,sumspricetimediff:(0^sumspricetimediff)+sums price*0^deltas[first lt;time] by sym from x lj delete time from update lt:time from latest;
   / add latest values for each sym from r to latest
   latest,::select by sym from r;
   / add records to sumstab for all records in update message
   sumstab,::`time`sym xcols 0!r
 }

/ function to calc twap/vwap
/ calculates metrics for windows in "windows"
metrics:{[syms]
   / allow calling function with ` for all syms
   syms:$[syms~`;exec distinct sym from latest;syms,()];
   / metric calcs
   t:select sym,timediff,vwap:(lsumsps-sumsps)%lsumssize-sumssize,twap:(lsumspricetimediff-sumspricetimediff)%.z.p - time
     / get sums asof time each window ago
     from aj[`sym`time;([]sym:syms) cross update time:.z.p - timediff from ([]timediff:windows);sumstab] 
          / join latest sums for each sym
          lj 1!select sym,lsumssize:sumssize, lsumsps:sumsps, lsumspricetimediff:sumspricetimediff from latest

   / add allday window
   if[not all syms in key start;start::exec first time by sym from sumstab];
   `sym`timediff xasc t,select sym,timediff:0Nn,vwap:sumsps%sumssize,twap:sumspricetimediff%.z.p - start[sym] from latest where sym in syms
  
 }

/ check for TP connection
notpconnected:{[]
	0 = count select from .sub.SUBSCRIPTIONS where proctype in ((),`tickerplant), active}

/ get handle for TP & subscribe
subscribe:{
  if[count s:.sub.getsubscriptionhandles[`tickerplant;();()!()];
  r:.sub.subscribe[`trade;`;0b;0b;first s]];:r};

/ get subscribed to TP, recover up until now from RDB
init:{
  r:subscribe[];

  while[notpconnected[];
	.os.sleep[10];
	.servers.startup[];
  	r:subscribe[]];

  if[r[`icounts][`trade] > 0;
   / recover from RDB
   while[not count s:.sub.getsubscriptionhandles[`rdb;();()!()];.os.sleep[10]];
   h:exec first w from s;
   t:h"select time,sym,size,price from trade where i<",string r[`icounts][`trade];
   `sumstab insert select time,sym,sumssize,sumsps,sumspricetimediff from update sumssize:sums size,sumsps:sums price*size,sumspricetimediff:sums price*time-prev time by sym from t;
   `latest insert select by sym from sumstab;
   ];

   / setup empty start dict for use in all day calculation
   start::()!();
 }

/ get connections to TP, & RDB for recovery
.servers.CONNECTIONS:`rdb`tickerplant;
.servers.startup[];
init[];
