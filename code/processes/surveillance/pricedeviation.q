// pricedeviation.q — Trade-vs-quote price deviation detection
// Flags trades whose execution price differs abnormally from the
// prevailing best bid/ask midpoint at the time of the trade.

\d .surv.pxdev

detect:{[]
  h:.surv.rdbh[];
  if[null h; .lg.w[`survpxdev;"no RDB handle — skipping price deviation detection"]; :()];

  cutoff:.proc.cp[] - .surv.cfg.pxdev.lookback;
  trades:h("select time,sym,price,tradeid from trade where time >= x";cutoff);

  if[0=count trades; :()];

  quotes:h"select time,sym,bid,ask from quote";

  if[0=count quotes; :()];

  // aj requires right table sorted by sym and time
  quotes:`sym`time xasc quotes;

  // Pair each trade with the prevailing quote at trade time
  paired:aj[`sym`time;trades;quotes];

  // Drop trades with no matching quote or zero mid
  paired:select from paired where not null bid,not null ask;
  if[0=count paired; :()];

  paired:update mid:(bid+ask)%2 from paired;
  paired:select from paired where mid <> 0;
  if[0=count paired; :()];

  paired:update dev:abs[price-mid]%mid from paired;

  thresh:.surv.cfg.pxdev.threshold;
  flagged:select from paired where dev > thresh;
  if[0=count flagged; :()];

  // Assign severity — apply in order so higher bands overwrite
  n:count flagged;
  severity:n#`low;
  severity:?[flagged[`dev] > 2*thresh; n#`medium; severity];
  severity:?[flagged[`dev] > 3*thresh; n#`high; severity];

  // Build notes strings
  notes:{[px;pct;md;b;a]
    "price ",(string px)," deviates ",(string`float$"j"$pct*10000),"% from mid ",
    (string md)," (bid ",(string b),", ask ",(string a),")"
    } .' flip (flagged`price; flagged`dev; flagged`mid; flagged`bid; flagged`ask);

  now:.proc.cp[];
  alerts:([]
    time:n#now;
    sym:flagged`sym;
    alerttype:n#`pricedeviation;
    severity:severity;
    refid:flagged`tradeid;
    price:flagged`price;
    size:n#0j;
    threshold:n#thresh;
    actual:flagged`dev;
    notes:notes);

  .lg.o[`survpxdev;"price deviation: ",(string n)," alert(s) generated"];
  .surv.alert[alerts];}

\d .

.api.add[`.surv.pxdev.detect;1b;
  "Detect trades whose price deviates abnormally from the prevailing quote midpoint";
  "[]";"()"];
