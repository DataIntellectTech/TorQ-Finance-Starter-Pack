// Bespoke RDB config : Finance Starter Pack

\d .rdb
hdbdir:hsym`$getenv[`KDBHDB]    // the location of the hdb directory
reloadenabled:1b                // if true, the RDB will not save when .u.end is called but
                                // will clear it's data using reload function (called by the WDB)

connectonstart:1b               // rdb connects and subscribes to tickerplant on startup
tickerplanttypes:`segmentedtickerplant
gatewatypes:`none
replaylog:1b

hdbtypes:()			//connection to HDB not needed

subfiltered:1b
subcsv:hsym first .proc.getconfigfile[string `rdbsub.csv`rdb2sub.csv`rdb3sub.csv `rdb1`rdb2`rdb3?.proc.procname]

\d .servers

CONNECTIONS:enlist `gateway     // if connectonstart false, include tickerplant in tickerplanttypes, not in CONNECTIONS
