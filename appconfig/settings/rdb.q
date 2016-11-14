// Bespoke RDB config : Finance Starter Pack

\d .rdb
hdbdir:hsym`$getenv[`KDBHDB]    //the location of the hdb directory
reloadenabled:1b		//if true, the RDB will not save when .u.end is called but
               			//will clear it's data using reload function (called by the WDB)

hdbtypes:()			//connection to HDB not needed

\d .servers
CONNECTIONS:enlist `tickerplant
