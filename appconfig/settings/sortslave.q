// Bespoke Sort Slave config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]		// location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]            // move wdb database to different location
tickerplanttypes:rdbtypes:hdbtypes:gatewaytypes:sorttypes:sortslavetypes:()	// sortslaves don't need these connections
