\d .surv

cfg.rdbtypes:@[value;`cfg.rdbtypes;`rdb];
cfg.pxdev.lookback:@[value;`cfg.pxdev.lookback;0D00:05];
cfg.pxdev.threshold:@[value;`cfg.pxdev.threshold;0.02];
cfg.pxdev.interval:@[value;`cfg.pxdev.interval;0D00:00:10];

tph:{first exec w from .servers.getservers[`proctype;`segmentedtickerplant;()!();1b;0b]}

rdbh:{first exec w from .servers.getservers[`proctype;.surv.cfg.rdbtypes;()!();1b;0b]}

alert:{[rows]
  h:.surv.tph[];
  if[null h; .lg.w[`surv;"no tickerplant handle"]; :()];
  h(`.u.upd;`alert;value flip rows);
  .lg.o[`surv;"published ",(string count rows)," alert(s)"]}


\d .

.api.add[`.surv.alert;1b;"Publish alert rows to the segmented tickerplant";"[table:rows]";""];
.api.add[`.surv.pxdev.detect;1b;"Run price deviation detection (stub — overridden by code/surveiller/)";"[]";""];

.timer.repeat[.proc.cp[];0Wp;.surv.cfg.pxdev.interval;
  ({@[.surv.pxdev.detect;();{.lg.e[`surv;x]}]};`);
  "Price deviation detection"];

.servers.CONNECTIONS:distinct .servers.CONNECTIONS,`segmentedtickerplant`rdb;
.servers.startup[];