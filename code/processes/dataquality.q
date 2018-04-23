/This will be a data quality engine

\d .dqe

testvar:101;
connectiontypes:@[value;`connectiontypes;`hdb];
sleepintv:@[value;`sleepintv;10];
notconnected:{[]0 = count select from .servers.SERVERS where proctype in .dqe.connectiontypes,not null w};
hdbdir:@[value;`hdbdir;getenv[`KDBHDB]];

getTableSchema:{
  .lg.o[`fileload;"Loading in table schema as .schema.tablename"];
  .proc.loadf[(src:$[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];
  {(set')[`$".schema.",/:string x;value each x]}.schema.tablenames:.Q.pt;
 };

checkLogger:{[checkname;checkresult]
  $[result:checkresult;
    (.lg.o[`check;"The check ",checkname," has passed";:result]);
    .lg.e[`check;"The check ",checkname,"has failed"];
   ];
 };
  
checkTableNumber:{checkLogger["tableNumber";(count .schema.tablenames)=count .Q.pt]};

checkColumnNames:{checkLogger["columnNames";(cols each .Q.pt)~`date,'cols each `$".schema.",/:string .schema.tablenames]};

checkRecordCount:{[dates]
  :checkLogger["recordCount";
    all {(abs avg[-1_x]-last x)<2*dev each flip -1_x}{[x;y]count select from x where date=y}'[.Q.pt;]'[dates]
  ];
 };

\d . 

.servers.CONNECTIONS:.dqe.connectiontypes;

.lg.o[`init;"searching for servers"];
.servers.startup[];

while[.dqe.notconnected[];
	.os.sleep[.dqe.sleepintv];
	.servers.startup[];
 ];


system"l ",.dqe.hdbdir;
.dqe.getTableSchema[];
system"l ",.dqe.hdbdir;

