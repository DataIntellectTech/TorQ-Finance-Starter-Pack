// Bespoke WDB config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]		// location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]            // move wdb database to different location
sortslavetypes:()			// WDB doesn't need to connect to sortslaves

\d .servers
CONNECTIONS:`tickerplant`sort`gateway`rdb`hdb
