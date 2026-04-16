// surveillance.q — Real-time market surveillance process
// Connects to the RDB via discovery, runs three anomaly detectors on timers,
// and publishes alerts to the tickerplant.

\d .surv

// -------------------------------------------------------------------------
// Connections
// -------------------------------------------------------------------------

// Tickerplant handle — looked up fresh on each publish call
tph:{first exec w from .servers.getservers[`proctype;`segmentedtickerplant;()!();1b;0b]}

// RDB handle — looked up fresh on each detection call
rdbh:{
  h:first exec w from .servers.getservers[`proctype;.surv.cfg.rdbtypes;()!();1b;0b];
  if[null h; .lg.w[`surv;"no RDB handle available"]];
  h}

// -------------------------------------------------------------------------
// Alert publishing utility
// -------------------------------------------------------------------------

// .surv.alert — publish a table of alert rows to the tickerplant
// rows: table conforming to the alert schema
alert:{[rows]
  h:.surv.tph[];
  if[null h; .lg.w[`surv;"no tickerplant handle — alerts dropped"]; :()];
  h(`.u.upd;`alert;value flip rows);
  .lg.o[`surv;"published ",(string count rows)," alert(s)"];}

// -------------------------------------------------------------------------
// Load scenario files
// -------------------------------------------------------------------------

\l code/processes/surveillance/volumespike.q
\l code/processes/surveillance/pricedeviation.q
\l code/processes/surveillance/quotestuffing.q

// -------------------------------------------------------------------------
// Timer registration
// -------------------------------------------------------------------------

.lg.o[`surv;"registering detection timers"];

.timer.repeat[.proc.cp[];0Wp;.surv.cfg.vol.interval;
  ({@[.surv.vol.detect;();{.lg.e[`surv;x]}]};`);
  "Volume spike detection"];

.timer.repeat[.proc.cp[];0Wp;.surv.cfg.pxdev.interval;
  ({@[.surv.pxdev.detect;();{.lg.e[`surv;x]}]};`);
  "Price deviation detection"];

.timer.repeat[.proc.cp[];0Wp;.surv.cfg.qs.interval;
  ({@[.surv.qs.detect;();{.lg.e[`surv;x]}]};`);
  "Quote stuffing detection"];

.lg.o[`surv;"surveillance timers registered"];

// -------------------------------------------------------------------------
// API documentation
// -------------------------------------------------------------------------

.api.add[`.surv.alert;1b;"Publish alert rows to tickerplant";"[rows: alert table]";"()"];
.api.add[`.surv.tph;0b;"Return current segmentedtickerplant handle";"[]";"int"];
.api.add[`.surv.rdbh;0b;"Return current RDB handle";"[]";"int"];

\d .

// -------------------------------------------------------------------------
// Connection setup — must be last
// -------------------------------------------------------------------------

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,`segmentedtickerplant`rdb;

.servers.startup[];
