\d .mig

hdbtypes:@[value;`hdbtypes;`hdb];                                                               //list of hdb types to look for and call
hdbnames:@[value;`hdbnames;()];                                                                 //list of hdb names to search for and call
hdbconnsleepintv:@[value;`hdbconnsleepintv;10];                                                 //number of seconds between attempts to connect to the hdb

if[not .timer.enabled;.lg.e[`migratorinit;
   "the timer must be enabled to run the migrator process"]];                                   //if the timer is not enabled, then exit with error. Useful if want to migrate periodically

nohdbconnected:{[]                                                                              //function to check that the hdb is connected to and subscription has been setup
  :0 = count select from .sub.SUBSCRIPTIONS where proctype in .mig.hdbtypes, active;
 };

dates:"D"$.proc.params.dates;
tablist:`$.proc.params.tablist;
parpath:hsym `$.proc.params.parpath;
sourcepath:.proc.params.sourcepath;

databasesave:{                                                                                  //function called to load source directory and save data to new partitions
  {
    system "l ",raze sourcepath;
    set[x;{[x;y]delete date from select from x where date=y}[x;y]];
    .Q.dpft[first parpath;y;`sym;x];
   }\'[tablist;]each dates;
 };

hdbsave:{                                                                                       //function called to connect to hdb and save data to new partitions
  {
   remotehdb:exec first w from .servers.SERVERS where proctype in`hdb;
   set[x;remotehdb({[x;y]delete date from select from x where date=y};x;y)];
   .Q.dpft[first parpath;y;`sym;x];
   }\'[tablist;]each dates;
 };

\d .

.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.mig.hdbtypes)except `rdb;                  //make sure that the process will make a connection to any process of hdb type
.lg.o[`init;"searching for servers"];                                                           //and append connection results to logfile
                                                                                                //drop rdb but leave disc for calls in case we need to migrate intraday data

.servers.startup[];

if[`dbasesave in key .proc.params and not`hdbsave in key .proc.params;
  .mig.databasesave[];
  exit 0
 ];

if[`hdbsave in key .proc.params and not`dbasesave in key .proc.params;
  .mig.hdbsave[];
  exit 0
 ];                                                                                             //if either present in cmdline, run corresponding function then quit
