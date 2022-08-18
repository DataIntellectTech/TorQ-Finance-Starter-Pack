// Bespoke Tailer config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]		// location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]            // move wdb database to different location
sortworkertypes:()			// tailer doesn't need to connect to sortworkers
rowthresh:1000				// row count threshold for tailer savedown
period:00:10:00				// how often to check table row counts against threshold

\d .servers
CONNECTIONS:`segmentedtickerplant`sort`gateway`rdb`hdb
