// Bespoke RDB config : Finance Starter Pack

\d .rdb
hdbdir:hsym`$getenv[`KDBHDB]    // the location of the hdb directory
reloadenabled:1b                // if true, the RDB will not save when .u.end is called but
                                // will clear it's data using reload function (called by the WDB)

hdbtypes:()                     // connection to HDB not needed
connectonstart:1b               // rdb connects and subscribes to tickerplant on startup
tickerplanttypes: `tickerplant

\d .servers
CONNECTIONS:enlist `gateway     // if connectonstart false, include tickerplant in tickerplanttypes, not in CONNECTIONS
