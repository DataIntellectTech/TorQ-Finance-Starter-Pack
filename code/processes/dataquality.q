/This will be a data quality engine

\d .dqe

testvar:101;
connectiontypes:@[value;`connectiontypes;`hdb];
sleepintv:@[value;`sleepintv;10];
notconnected:{[]0 = count select from .servers.SERVERS where proctype in .dqe.connectiontypes,not null w};
hdbdir:@[value;`hdbdir;getenv[`KDBHDB];

getTableNames:{.Q.pt where not .Q.pt in `logmsg`heartbeat};

setTableSchemas:{
  .proc.loadf[(src:$[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];
  .schema.tablenames:getTableNames[];
  {(set')[`$".schema.",/:string x;value each x]}.schema.tablenames;
 };

checkTableNumber:{
  $[result:(count .schema.tablenames)=count getTableNames[];
    (.lg.o[`check;"The number of on-disk tables is correct"];:result);
    .lg.e[`check;"The number of on-disk tables is not correct"];
   ];
 };

checkEnum:{
  
 };

\d . 

.servers.CONNECTIONS:.dqe.connectiontypes;

.lg.o[`init;"searching for servers"];
.servers.startup[];

while[.dqe.notconnected[];
	.os.sleep[.dqe.sleepintv];
	.servers.startup[];
 ];

.dqe.setTableSchemas[];

system"l ",getenv[`KDBHDB];

