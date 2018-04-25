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

checkLogger:{[checkname;result;detail]											/ function to add a log wrapper to each check
  $[result;														/ conditional to log to output or error logs depending on check result
    (.lg.o[`check;"The check ",checkname," has passed"];:result);
    (.lg.e[`check;"The check ",checkname," has failed"];alertMail[checkname;detail]);
   ];
 };
  
checkTableNumber:{													 / function to check if the same number of tables are saved to disk as exist in the schema
  missingTables:.Q.pt where not (tables`.schema)=.Q.pt;
  :checkLogger["tableNumber";
    not count missingTables;
    "The latest partition is missing the following tables: ",", "sv string missingTables]
 };

checkColumnNames:{													/ function to check if on-disk table column names match those of the schema
  errTables:.Q.pt where not all each cols'[.Q.pt]=`date,/:cols each .dqe.schemaTables;
  :checkLogger["columnNames";
    not count errTables;
    "The following tables' columns do not match the schema file: ",", "sv string errTables]
 };				

checkRecordCount:{													/ function to check approximate record counts for each table, compares first date in list to average of other dates
  errTables:.Q.pt where not {(abs avg[-1_x]-last x)<2*dev each flip -1_x}flip .Q.cn each value each .Q.pt;
  :checkLogger["recordCount";
    not count errTables;												 / fails if any table counts differ from the average of the considered dates by twice the dev
    "The following tables have unexpected record counts: ",", "sv string errTables];
 };

checkColumnTypes:{													 / function to check if on-disk column types match those of the schema
  errTables:.Q.pt where not exec t from all each 1_'{select t from x}each meta'[.Q.pt]=meta each .dqe.schemaTables
  :checkLogger["columnTypes";
    not count errTables;
    "The following tables do not have the correct column types: ",","sv string errTables];
 };

alertMail:{[checkname;detail]
  .email.send[`to`subject`debug`body!(.email`user;"Houston, We Have a Problem.";
    1i;
    ("The check ",checkname," has failed";"The detail of the problem is as follows: ",detail))
   ];
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
  
  .email.connect`url`user`password`from`usessl`debug#.email;

  .timer.repeat[(.z.d+1)+01:00;0W;1D;.dqe.runChecks;"run on-disk data checks"];						/ timer job to run on-disk checks daily, post rollover
 };

init[];
