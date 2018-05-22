//base:"I"$getenv[`KDBBASEPORT]									//Get base port used by all processes

//.my.pnl:hopen `$":localhost:",string[base+21],":rdb:pass";					//Open PnL port
//.my.rtas:hopen `$":localhost:",string[base+24],":rdb:pass";					//Open Real-Time Aggregation Subscriber port
//.my.rdb:hopen `$":localhost:",string[base+2],":rdb:pass";					//Open connection to RDB
//.my.hdb:hopen `$":localhost:",string[base+3],":rdb:pass";					//Open connection to HDB
//.my.tst:hopen `$":localhost:",string[base],":rdb:pass";						//Test subscriber

.ut.connectiontypes:@[value;`.ut.connectiontypes;`rdb`hdb`wdb`wap];                                                          
.ut.connsleepintv:@[value;`.ut.connsleepintv;5];
.ut.notconnected:{[]0=count select from .servers.SERVERS where proctype in .ut.connectiontypes,not null w};

init:{[]
  .handle.rdb:.servers.gethandlebytype[`rdb;`any];
  .handle.hdb:.servers.gethandlebytype[`hdb;`any];
  .handle.wdb:.servers.gethandlebytype[`wdb;`any];
  .handle.pnl:.servers.gethandlebytype[`wap;`any];
 };                                       

.servers.CONNECTIONS:.ut.connectiontypes;                                                                  

while[
 .ut.notconnected[];
 .os.sleep .ut.connsleepintv;
 .servers.startup[];
 ];

init[];

