\d .dqe

connectiontypes:@[value;`connectiontypes;`hdb];										/ symbol list of connection types 
sleepintv:@[value;`sleepintv;10];											/ integer connection attempt sleep interval
notconnected:{[]0=count select from .servers.SERVERS where proctype in .dqe.connectiontypes,not null w};		/ boolean to signify if process is connected to required types
hdbdir:@[value;`hdbdir;getenv`KDBHDB];											/ string path to HDB
schemaTables:@[value;`schemaTables;.Q.pt];										/ symbol list of fully qualified .schema tables

getTableSchema:{													/ function to retrieve empty tables from schema file 
  .lg.o[`fileload;"Loading in table schema as .schema.tablename"];
  .proc.loadf[(src:$[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];			/ load in empty schema tables
  {(set')[.dqe.schemaTables:` sv/:`.schema,/:x;value each x]}.Q.pt;							/ rename each schema table, save names under schemaTables
 };

checkLogger:{[checkname;checkresult]											/ function to add a log wrapper to each check
  $[checkresult;													/ conditional to log to output or error logs depending on check result
    (.lg.o[`check;"The check ",checkname," has passed"];:checkresult);
    .lg.e[`check;"The check ",checkname," has failed"];
   ];
 };
  
checkTableNumber:{checkLogger["tableNumber";count[.dqe.schemaTables]=count .Q.pt]};					/ function to check if the same number of tables are saved to disk as exist in the schema

checkColumnNames:{checkLogger["columnNames";cols'[.Q.pt]~`date,/:cols each .dqe.schemaTables]};				/ function to check if on-disk table column names match those of the schema

checkRecordCount:{													/ function to check approximate record counts for each table, compares first date in list to average of other dates
  :checkLogger["recordCount";
    all{(abs avg[-1_x]-last x)<2*dev each flip -1_x}flip .Q.cn each value each .Q.pt];					/ fails if any table counts differ from the average of the considered dates by twice the dev 
 };

checkColumnTypes:{													/ function to check if on-disk column types match those of the schema
  :checkLogger["recordCount";
    all first each 1_ all meta'[.Q.pt]=meta each .dqe.schemaTables];
 };

runChecks:{														/ wrapper function to run on-disk checks
  0N!.dqe.checkTableNumber[];
  0N!.dqe.checkColumnNames[];
  0N!.dqe.checkRecordCount[];
  0N!.dqe.checkColumnTypes[];
 };

\d . 

.servers.CONNECTIONS:.dqe.connectiontypes;										/ set connection types required

init:{															/ initialisation function 
  .lg.o[`init;"searching for servers"];
  .servers.startup[];													/ make connections

  while[.dqe.notconnected[];												/ loop to block process until required connections are made
    .os.sleep[.dqe.sleepintv];
    .servers.startup[];
   ];

  system"l ",.dqe.hdbdir;												
  .dqe.getTableSchema[];												/ load in table schema 
  system"l ",.dqe.hdbdir;												/ map hdb into memory

  .timer.repeat[(.z.d+1)+01:00;0W;1D;.dqe.runChecks;"run on-disk data checks"];						/ timer job to run on-disk checks daily, post rollover
 };

/init[];
