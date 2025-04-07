// Configure connection to Tickerplant(s)
.servers.CONNECTIONS: enlist `segmentedtickerplant;


\d .ord
upd:@[value;`upd;{insert}];
connectonstart:@[value;`connectonstart;1b];                 //order process connects to tickerplant as soon as it is started
subscribeto:@[value;`subscribeto;`quote];                        //a list of tables to subscribe to, default (`quote)
subscribesyms:@[value;`subscribesyms;`];                    //a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];               //number of seconds between attempts to connect to the tp	
tpcheckcycles:@[value;`tpcheckcycles;0W];                   //specify the number of times the process will check for an available tickerplant
tickerplanttypes:@[value;`tickerplanttypes;enlist `segmentedtickerplant];   //list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                           //replay the tickerplant log file
schema:@[value;`schema;1b];                                 //retrieve the schema from the tickerplant

startup:{[]
    /-check if the process has connected to discovery process, block the process until a connection is established
    while[0 = count .servers.getservers[`proctype;`discovery;()!();0b;1b];
    .os.sleep[5];
    /-run the servers startup code again (to make connection to discovery)
    .servers.startup[];
    .lg.o[`subscribe;"attempting to connect to discovery process"];
    .servers.retrydiscovery[]]}


subscribe:{[]
	if[count s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];;
		.lg.o[`subscribe;"found available tickerplant, attempting to subscribe"];
		/-set the date that was returned by the subscription code i.e. the date for the tickerplant log file
		/-and a list of the tables that the process is now subscribing for
		subinfo:.sub.subscribe[subscribeto;subscribesyms;schema;replaylog;first s];
		/-setting subtables and tplogdate globals
		@[`.ord;;:;]'[`subtables`tplogdate;subinfo`subtables`tplogdate];];}


\d .
// Initialize connection management
// START UP
.servers.startup[]
.ord.startup[]

$[.ord.connectonstart;
 [.servers.CONNECTIONS,:.ord.tickerplanttypes;
  .servers.startupdepcycles[.ord.tickerplanttypes;.ord.tpconnsleepintv;.ord.tpcheckcycles];
  .ord.subscribe[];
 ];;]

upd:.ord.upd
 
