//default params for tm1 and timer
o:.Q.def[`tm1`timer!(00:05:00.000;300000)].Q.opt .z.x

\d .symcheck

//get rdb info and schema, reconnection wait time
rdbtypes:@[value;`rdbtypes;`rdb];                           //list of rdb types to look for and call in rdb
rdbnames:@[value;`rdbnames;`rdb1];                             //list of rdb names to search for and call in rdb

schema:@[value;`schema;1b];                                 //retrieve the schema from the rdb
rdbconnsleepintv:@[value;`rdbconnsleepintv;10];             //number of seconds between attempts to connect to the rdb                                                                      

// if the timer is not enabled, then exit with error
if[not .timer.enabled;.lg.e[`rdbinit;"the timer must be enabled to run the symcheck process"]];

//subscribe to rdb
subscribe:{
  // get handle
  if[count s:.sub.getsubscriptionhandles[`rdb;();()!()];
  subproc:first s;
  // if got handle successfully, subsribe to tables
  .lg.o[`subscribe;"subscribing to ", string subproc`procname];
  :.sub.subscribe[`trade`quote`quote_iex`trade_iex;`;0b;0b;subproc]]};


// function to check that the tickerplant is connected and subscription has been setup
nordbconnected:{[]
  0 = count select from .sub.SUBSCRIPTIONS where proctype in .symcheck.rdbtypes, active;
 };


\d .

// make sure that the process will make a connection to each of the tickerplant and hdb types
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.symcheck.rdbtypes;

// append connection results to logfile
.lg.o[`init;"searching for servers"];

.servers.startup[];

//subscribe to the rdb
.symcheck.subscribe[]


// check if the tickerplant has connected, block the process until a connection is established
while[.symcheck.nordbconnected[];
  // while no connected make the process sleep for X seconds and then run the subscribe function again
  .os.sleep[.symcheck.rdbconnsleepintv];
  // run the servers startup code again (to make connection to discovery)
  .servers.startup[];
 ];


//create email connection, namespace read in from default.q
.email.connect[`url`user`password`from`usessl`debug!.email`url`user`password`from`usessl`debug];

//get list tables to check
tablist:`quote`trade`trade_iex`quote_iex;

//set upsert table for last value per sym
symtab:([sym:`$();tab:`$()]time:`timestamp$());

system "t ",string o`timer;

.z.ts:{
  symgrab[x];
  symsnotpresentiex[o];
  symsnotpresentreg[o];
  if[max 0<count each(.chk.iexdata;.chk.regdata);
   .email.send[`to`subject`body`debug!(.email`user;"Missing syms on rdb";("The following syms are missing at: ",string .z.P;"Syms missing: ", " ; " sv string exec sym from lj[.chk.regdata;.chk.iexdata]);1i)]];
 };

//define sym grab function
//connects to rdb and grabs last record by sym,table
symgrab:{[x]
  {
    grab:{[x]select last time by sym,tab:"s"$x from x};
    data:(first exec w from s:.sub.getsubscriptionhandles[`rdb;();()!()])(grab;x);
    `symtab upsert data;
  }each tablist;
 };

//checks for regular (non iex) syms, compares them to original list and flags missings
symsnotpresentreg:{[o]
  .chk.regsyms:select last time by sym from symtab where tab in `quote`trade;
  .chk.reglist:(exec distinct sym from .chk.regsyms) except exec distinct sym from symtab where time within(.z.P-o`tm1;.z.P),tab in`quote`trade;
  .chk.regdata:`sym xkey select sym,last_time:time from select from `time xasc symtab where sym in .chk.reglist,tab in `quote`trade;
 };


//checks for iex syms
symsnotpresentiex:{[o]
  .chk.iexsyms:select last time by sym from symtab where tab in `quote_iex`trade_iex;
  .chk.iexlist:(exec distinct sym from .chk.iexsyms) except exec distinct sym from symtab where time within(.z.P-o`tm1;.z.P), tab in `quote_iex`trade_iex;
  .chk.iexdata:`sym xkey select sym,last_time:time from select from `time xasc symtab where sym in .chk.iexlist,tab in `quote_iex`trade_iex;
 };
