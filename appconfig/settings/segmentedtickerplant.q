\d .stplg

multilog:`tabperiod;      // [tabperiod|none|periodic|tabular|custom]
multilogperiod:0D01;
errmode:1b;
batchmode:`defaultbatch;  // [autobatch|defaultbatch|immediate]
customcsv:hsym first .proc.getconfigfile["stpcustom.csv"];
replayperiod:`day         // [period|day|none]

\d .proc

loadprocesscode:1b;

\d .eodtime

datatimezone:`$"Etc/GMT-1";
rolltimezone:`$"Etc/GMT-1";
