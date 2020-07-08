\d .stplg

multilog:`custom;      // [custom|none|tabperiod]
customlogmode:`period;   // [period|tabular|custom]
customlogtabs:`trade`quote!(`period`tabular)  // dictionary of tables to apply custom logging on
multilogperiod:0D01;
errmode:1b;
batchmode:`defaultbatch;  // [autobatch|defaultbatch|immediate]

// define a custom logname function here, below is just tabperiod logname function but can be anything
// lognamefunc:{[dir;tab;logfreq;dailyadj]
//   ` sv(hsym dir;`$string[tab],ssr[;;""]/[-13_string logfreq xbar .z.p+dailyadj;":.D"])
//   };

\d .proc

loadprocesscode:1b;
