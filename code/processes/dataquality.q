opts:.Q.def[(enlist`us)!(enlist 0b)].Q.opt .z.x;

usage:("";
  "USAGE - Welcome to the Data Quality Engine"; 
  "This process is built to run a series of checks periodically on on-disk data";
  "Available checks can be found under the .dqe namespace";
  "The checks are run periodically by the .timer TorQ functionality, by default daily at 0100";
  "The checks can be run manually using the .dqe.runChecks function which takes a hdb partition as its argument");

\d .dqe

connectiontypes:@[value;`connectiontypes;`hdb];										/ symbol list of connection types
notconnected:{[]0=count select from .servers.SERVERS where proctype in .dqe.connectiontypes,not null w};		/ boolean to signify if process is connected to required types
hdbdir:@[value;`hdbdir;getenv`KDBHDB];											/ string path to HDB
schemaTables:@[value;`schemaTables;.Q.pt];										/ symbol list of fully qualified .schema tables

getTableSchema:{													/ function to retrieve empty tables from schema file 
  .lg.o[`fileload;"Loading in table schema as .schema.tablename"];
  .proc.loadf[($[`schemafile in key .proc.params;raze .proc.params`schemafile;"sym"]),".q"];				/ load in empty schema tables
  {(set')[.dqe.schemaTables:` sv/:`.schema,/:x;value each x]}.Q.pt;							/ rename each schema table, save names under schemaTables
 };

checkLogger:{[checkname;result;detail]											/ function to add a log wrapper to each check
  $[result;														/ conditional to log to output or error logs depending on check result
    (.lg.o[`check;"The check ",checkname," has passed"];:result);
    (.lg.e[`check;"The check ",checkname," has failed"];alertMail[checkname;detail]);					/ pass checkname and failure details to alertMail function upon failure
   ];
 };

// Each of the following checks make use of the checkLogger function,
// passing in the check name, the boolean result of the check, and the details of the failure
  
checkTableNumber:{													/ function to check if the same number of tables are saved to disk as exist in the schema
  missingTables:.Q.pt where not (tables`.schema)=.Q.pt;									/ set list of tables that do not pass the check
  :checkLogger["tableNumber";
    not count missingTables;
    "The latest partition is missing the following tables: ",", "sv string missingTables]
 };

checkColumnNames:{													/ function to check if on-disk table column names match those of the schema
  errTables:.Q.pt where not all each cols'[.Q.pt]=`date,/:cols each .dqe.schemaTables;					/ set list of tables that do not pass the check
  :checkLogger["columnNames";
    not count errTables;
    "The following tables' columns do not match the schema file: ",", "sv string errTables]
 };				

checkRecordCount:{													/ function to check approximate record counts for each table, compares first date in list to average of other dates
  errTables:.Q.pt where not {(abs avg[-1_x]-last x)<2*dev each flip -1_x}flip .Q.cn each value each .Q.pt;		/ set list of tables that do not pass the check
  :checkLogger["recordCount";
    not count errTables;												/ fails if any table counts differ from the average of the considered dates by twice the dev
    "The following tables have unexpected record counts: ",", "sv string errTables];
 };

checkColumnTypes:{													/ function to check if on-disk column types match those of the schema
  errTables:.Q.pt where not exec t from all each 1_'{select t from x}each meta'[.Q.pt]=meta each .dqe.schemaTables;	/ set list of tables that do not pass the check
  :checkLogger["columnTypes";
    not count errTables;
    "The following tables do not have the correct column types: ",","sv string errTables];
 };


tabSelect:{[tabName;colName;dt] tempTab:select from tabName where date=dt; ?[tempTab;();();(enlist count;colName)]};	/ function to extract a given column list from a given table on a given date
       
colsCountTab:{[tabName;dt] tabSelect[tabName;;dt] each cols[tabName]};							/ function to enerate a list of record counts for each column of a given table on a given date

checkColumnCount:{[dt]													/ function to check that column counts for each table are equal
  errTables:.Q.pt where not {all not deltas[first x;x]} each {[dt] colsCountTab[;dt] each .Q.pt}[dt];			/ set list of tables that do not pass the check 
  checkLogger["Equal Column Counts";									
  not count errTables;
  ("The following tables have failed the Equal Column Counts check on ";string dt;": ",", "sv string errTables)]
 };

checkAttributes:{[dt]													/ function to check that the parted attribute has been applied to each tables' sym column
  errTables:.Q.pt where not {[tabName;dt]`p=attr .Q.par[`:.;dt;tabName]`sym}[;dt]each .Q.pt;				/ set list of tables that do not pass the check
  :checkLogger["Parted Attribute"; 
  not count errTables;
  ("The following tables have failed the Parted Attribute check on";string dt;": ",", "sv string errTables)];
 };

checkEnumeration:{													/ function to check if enumeration exists on the top level
  :checkLogger["Top Level Enumeration File"; 
  $[()~key hdbdir,"/sym";0b;1b];
  ("The sym-enumeration file is NOT currently located at the top level")];
 };


alertMail:{[checkname;detail]												/ function to send an email alert upon any check failing using TorQ email functionality
  .email.send[`to`subject`debug`body!(
    .email`user;													/ email recipient
    "Houston, We Have a Problem.";											/ subject line
    1i;															/ debug information
    ("The check ",checkname," has failed";"The detail of the problem is as follows: ",detail))				/ body of email
   ];
 };

runChecks:{[dt]														/ wrapper function to run on-disk checks
  0N!.dqe.checkTableNumber[];
  0N!.dqe.checkColumnNames[];
  0N!.dqe.checkRecordCount[];
  0N!.dqe.checkColumnTypes[];
  0N!.dqe.checkColumnCount[dt];
  0N!.dqe.checkAttributes[dt];
  0N!.dqe.checkEnumeration[]; 
 };

\d . 

.servers.CONNECTIONS:.dqe.connectiontypes;										/ set connection types required

init:{                                                                                                                  / initialisation function
  system"l ",.dqe.hdbdir;
  .dqe.getTableSchema[];                                                                                                / load in table schema
  system"l ",.dqe.hdbdir;                                                                                               / map hdb into memory

  .email.connect`url`user`password`from`usessl`debug#.email;
  .timer.repeat[(.z.d+1)+01:00;0W;1D;(.dqe.runChecks;[.z.d-1]);"run on-disk data checks"];                              / timer job to run on-disk checks daily, post rollover
  if[opts[`us]=1b;show usage];
 };

attemptSetup:{
  .lg.o[`init;"searching for servers"];
  .servers.startup[];
  
  if[not .dqe.notconnected[];
    update active:not active from `.timer.timer where (`$description)=`$"Attempt startup procedure";
    init[];
  ];	 
 };

.timer.repeat[.z.p;0W;0D00:00:05;(attemptSetup;[]);"Attempt startup procedure"];

