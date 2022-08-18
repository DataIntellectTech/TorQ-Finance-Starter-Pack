// Bespoke Tailer config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]		// location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]            // move wdb database to different location
sortworkertypes:()			// WDB doesn't need to connect to sortworkers


\d .servers
CONNECTIONS:`segmentedtickerplant`sort`gateway`rdb`hdb`tailer_seg1`tailer_seg2`tr_seg1`tr_seg2
