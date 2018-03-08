//This script runs on a cronjob every five minutes.
//It checks all 4 rdb tables for the last time by sym
//It then compares the (current time - tm1 minutes) to the current time
//Syms appearing in the initital rdb check but not in this tm1-minute window
//are flagged, appended to log
//Cron then reads this and sends mail only if it has records (mail -Es)

//Manual Usage Example
/q symcheck.q -rdb ::14002:admin:admin -init 0 -noexit 1 -tm1 00:05:00.000

//create dictionary of cmdargs to type, connect to rdb, exit if not specified or can't find rdb
prse:`rdb`init`noexit`tm1!"SBBT";

o:{[x]a:.Q.opt[.z.x]; prse[d]$(d:(key prse) inter (key a))#first each a}[];
if[any not `rdb`init`noexit`tm1 in key .Q.opt[.z.x];exit 0];

rdb:@[hopen;first hsym o[`rdb];{-1 "rdb unavailable"}];
if[rdb<0;exit 0];

//get list tables to check, and syms to expect (per table)
tablist:`quote`trade`trade_iex`quote_iex;
symlistbs:`AIG`HPQ`AMD`IBM`DOW`INTC`DELL`MSFT`GOOG`AAPL;
symlistiex:`CAT`DOG;

//set upsert table for last value per sym
symtab:([sym:`$();tab:`$()]time:`timestamp$());

//define sym grab function
//connects to rdb and grabs last record by sym,table
symgrab:{[x]
  {
  grab:{[x]select last time by sym,tab:"s"$x from x};
  data:rdb(grab;x);
  `symtab upsert data;
  }each tablist;
 };

//checks for regular (non iex) syms, compares them to original list and flags missings
symsnotpresentreg:{[o]
  regsyms::select last time by sym from symtab where tab in `quote`trade;
  reglist::(exec distinct sym from regsyms) except exec distinct sym from symtab where time within(.z.P-o`tm1;.z.P),tab in`quote`trade;
  regdata::`sym xkey select sym,last_time:time from select from `time xasc symtab where sym in reglist,tab in `quote`trade;
 };


//checks for iex syms
symsnotpresentiex:{[o]
  iexsyms::select last time by sym from symtab where tab in `quote_iex`trade_iex;
  iexlist::(exec distinct sym from iexsyms) except exec distinct sym from symtab where time within(.z.P-o`tm1;.z.P), tab in `quote_iex`trade_iex;
  iexdata::`sym xkey select sym,last_time:time from select from `time xasc symtab where sym in iexlist,tab in `quote_iex`trade_iex;
 };

createlog:{
  logfile:`$":logs/","missingsyms.log";
  fh::hopen logfile;
 };

symlog:{[f;x]
  neg[fh](string[.z.P]," ; ",raze string[f]," ; ",x);
 };

logsyms:{ 
  symgrab[x];
 };

appendmissing:{[]
  if[0<count iexdata;symlog[`logsyms;string [exec distinct sym from iexdata], " ; last seen at: ",raze string exec last last_time from iexdata]];
  if[0<count regdata;symlog[`logsyms;string [exec distinct sym from regdata], " ; last seen at: ",raze string exec last last_time from regdata]];
  exit 0;
 };

//initialization function

init:{[o]
  createlog[];
  logsyms[];
  symsnotpresentreg[o];
  symsnotpresentiex[o];
  system "t ",string o[`timer];
  $[(0<count iexdata)|0<count regdata;appendmissing[];exit 0];
 };

if[o`init;init[o]];
if[not`noexit in key .Q.opt .z.x;exit 0];
