// Configure connection to Tickerplant(s)
.servers.CONNECTIONS: enlist `segmentedtickerplant;


\d .ord
//upd:@[value;`upd;{insert}];

// open quote table
upd:{[t;x]
    // First apply standard insert
    t insert x;
    // Filter and insert into partitioned table by sym, ex, src
    if[t=`quote;
        `openquote insert select by sym, ex, src from x;
    ];};
connectonstart:@[value;`connectonstart;1b];                 //order process connects to tickerplant as soon as it is started
subscribeto:@[value;`subscribeto;`quote];                        //a list of tables to subscribe to, default (`quote)
subscribesyms:@[value;`subscribesyms;`];                    //a list of syms to subscribe for, (`) means all syms
tpconnsleepintv:@[value;`tpconnsleepintv;10];               //number of seconds between attempts to connect to the tp	
tpcheckcycles:@[value;`tpcheckcycles;0W];                   //specify the number of times the process will check for an available tickerplant
tickerplanttypes:@[value;`tickerplanttypes;enlist `segmentedtickerplant];   //list of tickerplant types to try and make a connection to
replaylog:@[value;`replaylog;1b];                           //replay the tickerplant log file
schema:@[value;`schema;1b];                                 //retrieve the schema from the tickerplant

subfiltered:@[value;`subfiltered;0b];                       //allows subscription filters to be loaded and applied in the order




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
		@[`.ord;;:;]'[`subtables`tplogdate;subinfo`subtables`tplogdate];
        /-apply subscription filters to replayed data
        if[subfiltered&replaylog;
			applyfilters[;subscribesyms]each subtables];]
            ;}

applyfilters:{[t;f]
	filters:$[all null w:f[t;`filters];();@[parse;"select from t where ",w] 2];
  columns:last $[all null c:f[t;`columns];();@[parse;"select ",c," from t"]];
	@[`.;t;:;eval(?;t;filters;0b;columns)];}

feed:{
    h:.servers.gethandlebytype[tickerplanttypes;`any];
    h"`orderTable insert ",.Q.s1 value flip orderTable
 }
\d .




// Define the schema for the order table 
orderTable: ([]
       Id: `long$();
       Sym: `$();
       Ex: `char$();
       Src: `$();       
       Side: `$();
       OrderType: `$();
       CreationTime: `timestamp$();
       Price: `float$();
       Quantity: `int$())

// Define the schema for the openquote table
openquote:([sym:`$(); ex:`char$(); src:`symbol$()] 
    time:`timestamp$();
    bid:`float$();
    ask:`float$();
    bsize:`long$();
    asize:`long$();
    mode:`char$())

// Function to generate random orders and append to the existing order table
generateRandomOrders: {[numOrders;time]
    quoteTable:0!select by sym,ex,src from quote where time  within (last time - `minute$time; last time);
    // Realistic Limit Dimensions Table
    RLDquote::quoteTable;
    if[9=sum null exec from quoteTable; '"latest quote is empty, please try again"];
    // Get the current maximum ID in the order table (to ensure unique IDs)
    maxID: exec max Id from orderTable;
    // Handle case where orderTable is empty
    if[null maxID; maxID: 0]; 

    // Generate Unix timestamps (in milliseconds) for the new orders
    unixTimes: "j"$(.z.p - 1970.01.01D00:00:00.000) % 1000000; // Current Unix time in milliseconds
    unixTimes: unixTimes + til numOrders; // Add a counter to ensure uniqueness

    // Randomly choose between "market" and "limit"
    orderTypes: `Market`Limit numOrders?2;

    // Randomly choose between "buy" and "sell"
    side: `Buy`Sell numOrders?2;

    // Randomly select rows from the quote table to base orders on
    quoteIndices: numOrders?count quoteTable;
    selectedQuotes: quoteTable[quoteIndices];

    // Generate random timestamps slightly after the quote time
    creationTimes: selectedQuotes[`time] + 1000 * til numOrders; // Add milliseconds for uniqueness

    // Extract symbols, exchanges, and sources from the selected quotes
    symbols: selectedQuotes[`sym];
    exchanges: selectedQuotes[`ex];
    sources: selectedQuotes[`src];

    // Generate random prices between bid and ask for each order
    prices: {[quote]
        bid: quote[`bid];
        ask: quote[`ask];
        bid + (ask - bid) * rand 1.0
    } each selectedQuotes;

    // Generate random quantities based on bid/ask sizes
    quantities: {[quote]
        bsize: quote[`bsize];
        asize: quote[`asize];
        maxSize: max(bsize; asize);
        minSize: min(bsize; asize);
        minSize + floor (maxSize - minSize) * rand 1.0
    } each selectedQuotes;

    // Create a new table with the generated data
    newOrders: ([]
        Id: unixTimes;
        Sym: symbols;
        Ex: exchanges;
        Src: sources;  
        OrderType: orderTypes;
        Side:side;
        CreationTime: creationTimes;
        Price: prices;
        Quantity: quantities
    );
    // Append the new orders to the existing order table
    `orderTable upsert newOrders}

transactions:([] 
  orderID:`$();               // Order ID
  orderType:`$();           // Order type (market, limit, etc.)
  orderQty:`float$();             // Original order quantity
  cumQty:`float$();               // Cumulative filled quantity
  lastFillQty:`float$();          // Last fill quantity
  lastPrice:`float$();            // Last execution price
  lastMkt:`$();            // Last market where filled
  avgPrice:`float$();             // Average execution price
  sendTime:`timestamp$();         // When order was sent
  side:`symbol$();               // Buy or sell
  symbol:`symbol$();             // Instrument symbol
  exchange:`symbol$();           // Exchange identifier
  executionType:`symbol$();      // Execution type (FOK, IOC, etc.)
  orderStatus:`symbol$())         // Order status (filled, partial, etc.)


refreshOpenQuote:{[] `openquote upsert select by sym,ex,src from quote where time=max time}
genorder_amount:10
genorder_minute:10
genorder:{[] generateRandomOrders[genorder_amount;genorder_minute]}

// Initialize connection management
// START UP
.servers.startup[]
.ord.startup[]

$[.ord.connectonstart;  
 [.servers.CONNECTIONS,:.ord.tickerplanttypes;
  .servers.startupdepcycles[.ord.tickerplanttypes;.ord.tpconnsleepintv;.ord.tpcheckcycles];
  .ord.subscribe[];
  // timer for updates of order function and openQuote table
  .timer.rep[`timestamp$.proc.cd[]+00:00;0Wp;0D00:00:01;(`refreshOpenQuote;`);0h;"Openquote maintenance timer";1b];
  .timer.rep[`timestamp$.proc.cd[]+00:00;0Wp;0D00:00:01;(`genorder;`);0h;"Random order functions called";1b];
 ];;]

upd:.ord.upd
h:.servers.gethandlebytype[`segmentedtickerplant;`any]
//.timer.repeat[.proc.cp[];0Wp;0D00:00:00.200;(`feed;`);"Publish Feed"]; 
//.sub.subscribe[`quote;`;1b;0b;first s]
// issue:
/ cannot get quote table; replay issue, save down eod
/ .sub.subscribe[`trthquote;`A`B;0b;0b] each .sub.getsubscriptionhandles[`tickerplant;();()!()]
/ 
/ 

 /-set the upd function in the top level namespace
upd:.ord.upd

//data replay
// random order generator 
// open quote table
// Realistic Limit Dimensions Table
// execution generator
/ timer function
