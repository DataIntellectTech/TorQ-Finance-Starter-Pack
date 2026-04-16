// feed_anomalies.q — Anomaly injection for surveillance testing
// Loaded by feed.q. Publishes synthetic events that reliably trigger each
// surveillance detector. Uses the same globals (s, p, h) as feed.q.

\d .feed.anom

// -------------------------------------------------------------------------
// Volume spike injection
// -------------------------------------------------------------------------
// Publishes one trade with size 500x normal, guaranteeing it exceeds 3 stddevs
// of the rolling average computed by .surv.vol.detect.

injectvol:{[]
  i:rand count s;
  sym:s[i];
  price:p[i];
  tradeid:.feed.tradeid+:1;
  row:([]
    sym:   enlist sym;
    price: enlist price;
    size:  enlist 50000i;
    stop:  enlist 0b;
    cond:  enlist " ";
    ex:    enlist "N";
    side:  enlist `buy;
    tradeid: enlist tradeid);
  h(".u.upd";`trade;value flip row);
  .lg.o[`feedanom;"injected volume spike: sym=",(string sym),", size=50000"];}

// -------------------------------------------------------------------------
// Price deviation injection
// -------------------------------------------------------------------------
// Publishes one trade at 8% above the current base price, well above the
// 2% deviation threshold checked by .surv.pxdev.detect.

injectpxdev:{[]
  i:rand count s;
  sym:s[i];
  baseprice:p[i];
  tradeid:.feed.tradeid+:1;
  row:([]
    sym:   enlist sym;
    price: enlist baseprice * 1.08;
    size:  enlist 100i;
    stop:  enlist 0b;
    cond:  enlist " ";
    ex:    enlist "N";
    side:  enlist `buy;
    tradeid: enlist tradeid);
  h(".u.upd";`trade;value flip row);
  .lg.o[`feedanom;"injected price deviation: sym=",(string sym),", price=",(string baseprice*1.08)];}

// -------------------------------------------------------------------------
// Quote stuffing injection
// -------------------------------------------------------------------------
// Publishes 85 quotes for one symbol with near-identical bid/ask.
// Count (85) exceeds the 50-quote threshold; price range (0.02) is below
// the 0.5 minimum movement threshold checked by .surv.qs.detect.

injectqs:{[]
  i:rand count s;
  sym:s[i];
  baseprice:p[i];
  ids:.feed.quoteid+1+til 85;
  .feed.quoteid+:85;
  burst:([]
    sym:     85#sym;
    bid:     85#baseprice - 0.01;
    ask:     85#baseprice + 0.01;
    bsize:   85#100j;
    asize:   85#100j;
    mode:    85#" ";
    ex:      85#"N";
    src:     85#`INJECT;
    quoteid: ids);
  h(".u.upd";`quote;value flip burst);
  .lg.o[`feedanom;"injected quote stuffing: sym=",(string sym),", count=85"];}

// -------------------------------------------------------------------------
// Timer setup
// -------------------------------------------------------------------------

setup:{[]
  .timer.repeat[.proc.cp[];0Wp;0D00:00:45;
    ({@[.feed.anom.injectvol;();{.lg.e[`feedanom;x]}]};`);
    "Anomaly injection: volume spike"];
  .timer.repeat[.proc.cp[];0Wp;0D00:00:45;
    ({@[.feed.anom.injectpxdev;();{.lg.e[`feedanom;x]}]};`);
    "Anomaly injection: price deviation"];
  .timer.repeat[.proc.cp[];0Wp;0D00:00:30;
    ({@[.feed.anom.injectqs;();{.lg.e[`feedanom;x]}]};`);
    "Anomaly injection: quote stuffing"];
  .lg.o[`feedanom;"anomaly injection timers registered"];}

\d .
