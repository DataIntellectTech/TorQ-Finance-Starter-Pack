/This will be a data quality engine

\d .dqe

testvar:101;
connectiontypes:@[value;`connectiontypes;`hdb];
sleepintv:@[value;`sleepintv;10];
notconnected:{[]0 = count select from .servers.SERVERS where proctype in .dqe.connectiontypes,not null w};
hdbdir:@[value;`hdbdir;getenv[`KDBHDB]];
schemaTables:@[value;`schemaTables;.Q.pt];

getTableSchema:{
  .lg.o[`fileload;"Loading in table schema as .schema.tablename"];
  .proc.loadf[(src:$[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];
  /.dqe.schemaTables:`$".schema.",/:string .Q.pt;
  {(set')[.dqe.schemaTables:`$".schema.",/:string x;value each x]}.Q.pt;
 };

checkLogger:{[checkname;checkresult]
  $[result:checkresult;
    (.lg.o[`check;"The check ",checkname," has passed";:result]);
    .lg.e[`check;"The check ",checkname,"has failed"];
   ];
 };
  
checkTableNumber:{checkLogger["tableNumber";(count .dqe.schemaTables)=count .Q.pt]};

checkColumnNames:{checkLogger["columnNames";(cols each .Q.pt)~`date,'cols each .dqe.schemaTables]};

checkRecordCount:{[dates]
  :checkLogger["recordCount";
    all {(abs avg[-1_x]-last x)<2*dev each flip -1_x}{[x;y]count select from x where date=y}'[.Q.pt;]'[dates]];
 };

checkColumnTypes:{
  :checkLogger["recordCount";
    all first each 1_all (meta each .Q.pt)=meta each .dqe.schemaTables];
 };

\d . 

.servers.CONNECTIONS:.dqe.connectiontypes;

.lg.o[`init;"searching for servers"];
.servers.startup[];

while[.dqe.notconnected[];
	.os.sleep[.dqe.sleepintv];
	.servers.startup[];
 ];

init:{
  system"l ",.dqe.hdbdir;
  .dqe.getTableSchema[];
  system"l ",.dqe.hdbdir;

 };

runChecks:{
  0N!.dqe.checkTableNumber[];
  0N!.dqe.checkColumnNames[];
  0N!.dqe.checkRecordCount[date];
  0N!.dqe.checkColumnTypes[];
 };

init[];
