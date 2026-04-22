\d .feed.anom

injectpxdev:{
  syms:get `s;
  sym:syms rand count syms;
  baseprice:(get `p)[syms?sym];
  row:([]
    sym:      enlist sym;
    price:    enlist baseprice*1.08;
    size:     enlist 100i;
    stop:     enlist 0b;
    cond:     enlist " ";
    ex:       enlist "N";
    side:     enlist `buy;
    tradeid:  enlist .feed.tradeid+:1);
  (get `h)(`.u.upd;`trade;value flip row)}

setup:{
  .timer.repeat[.proc.cp[];0Wp;0D00:00:05;
    ({@[.feed.anom.injectpxdev;();{.lg.e[`feedanom;x]}]};`);
    "Price deviation anomaly injection"];
  .lg.o[`feedanom;"anomaly injection timer registered"]}

\d .
