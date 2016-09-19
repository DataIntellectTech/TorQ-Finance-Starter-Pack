// Bespoke Sort config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]          // location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]		// move wdb database to different location

\d .servers
CONNECTIONS:`hdb`tickerplant`rdb`gateway`sortslave        // list of connections to make at start up

