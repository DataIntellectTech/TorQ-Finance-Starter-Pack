// Bespoke RDB config : Finance Starter Pack

\d .rdb
hdbdir:hsym`$getenv[`KDBHDB]    //the location of the hdb directory
reloadenabled:1b		//if true, the RDB will not save when .u.end is called but
               			//will clear it's data using reload function (called by the WDB)

tickerplanttypes:`segmentedtickerplant
gatewatypes:`none
replaylog:0b

hdbtypes:()			//connection to HDB not needed

subfiltered:0b
subcsv:hsym first .proc.getconfigfile["rdbsub.csv"]

\d .servers
CONNECTIONS:enlist `tickerplant
