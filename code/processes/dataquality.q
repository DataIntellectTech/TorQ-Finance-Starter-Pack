/This will be a data quality engine

\d .dqe

connectiontypes:@[value;`connectiontypes;`hdb];
sleepintv:@[value;`sleepintv;10];
notpconnected:{[]0 = count select from .sub.SUBSCRIPTIONS where proctype in .dqe.connectiontypes,active};

\d . 

.lg.o[`init;"searching for servers"];
.servers.startup[];

while[.dqe.notconnected[];
	.os.sleep[.dqe.sleepintv];
	.servers.startup[];
 ];
