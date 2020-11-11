\d .

createlogs:1b;                  // create a logs

\d .stplg

multilog:`tabperiod;            // [tabperiod|none|periodic|tabular|custom]
multilogperiod:0D01;
errmode:1b;
batchmode:`defaultbatch;        // [memorybatch|defaultbatch|immediate]
customcsv:hsym first .proc.getconfigfile["stpcustom.csv"];
replayperiod:`day               // [period|day|prior]

\d .proc

loadprocesscode:1b;

\d .eodtime

datatimezone:`$"Etc/GMT-1";
rolltimezone:`$"Etc/GMT-1";