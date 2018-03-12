\d .eodsum
show "in symcheck ns";                                                                          //get rdb info and schema, reconnection wait time
rdbtypes:@[value;`rdbtypes;`rdb];                                                               //list of rdb types to look for and call in rdb
rdbnames:@[value;`rdbnames;()];                                                                 //list of rdb names to search for and call in rdb
schema:@[value;`schema;1b];                                                                     //retrieve the schema from the rdb
rdbconnsleepintv:@[value;`rdbconnsleepintv;10];                                                 //number of seconds between attempts to connect to the rdb

if[not .timer.enabled;.lg.e[`symcheckinit;
   "the timer must be enabled to run the symcheck process"]];                                   // if the timer is not enabled, then exit with error

subscribe:{                                                                                     //subscribe to rdb
  if[count s:.sub.getsubscriptionhandles[`rdb;();()!()];                                        //get handle
  subproc:first s;
   .lg.o[`subscribe;"subscribing to ", string subproc`procname];                                 //if got handle successfully, subsribe to tables
   :.sub.subscribe[`trade`quote`quote_iex`trade_iex;`;0b;0b;subproc]
  ]
 };

nordbconnected:{[]                                                                              // function to check that the rdb is connected and subscription has been setup
  :0 = count select from .sub.SUBSCRIPTIONS where proctype in .eodsum.rdbtypes, active;
 };

\d .

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.eodsum.rdbtypes;                            // make sure that the process will make a connection to any process of rdb type
.lg.o[`init;"searching for servers"];                                                           //and append connection results to logfile

.servers.startup[];

.eodsum.subscribe[]                                                                             //subscribe to the rdb

while[.eodsum.nordbconnected[];                                                                 // check if the tickerplant has connected, block the process until connection is established
  .os.sleep[.eodsum.rdbconnsleepintv];                                                          // while not connected, proc sleeps for X seconds then runs the subscribe function again
  .servers.startup[];                                                                           // run the servers startup code again (to make connection to discovery)
 ];


rdbhandle:(first exec w from .sub.getsubscriptionhandles[`rdb;();()!()]);                       //open handle to the rdb

eodavgsprd:rdbhandle"select avgSpread:avg ask-bid by sym from quote";                           //query quote table for avgSpread
eodvoltrd:rdbhandle"select volTraded:sum size, numTrades:count i by sym from trade";            //query trade table for vol+num traded
c:rdbhandle"select twas:avg ask-bid by sym,bucket:2 xbar time.hh from quote";                   //query quote table for TWAS in 2 hour buckets

update `$string bucket from `c;                                                                 //change type from long to sym
d:exec distinct bucket from c;                                                                  //get all unique values to be used as column headers
eodtwas:exec d#(bucket!twas) by sym:sym from c;                                                 //pivot table

eodsummary:(uj/)(eodvoltrd;eodavgsprd;eodtwas);                                                 //aj to create summary table
/
dt:`$raze ":",(system "pwd"),"/deploy/summary", ssr[string .z.d;".";""];                        //create dynamic variable to save table

dt set summary;                                                                                 //save local summary table to correct directory
\

savepath:hsym `$":/home/jburrows/deploy/newdeploy/hdb/database/";

savetable:{[d;p;f;t](d;p;f;count value t);
  .Q.dpft[d;p;f;t]
 };

savetable[savepath;.z.D;`sym;0!`eodsummary];

exit 0                                                                                          //terminate q session once task is complete
