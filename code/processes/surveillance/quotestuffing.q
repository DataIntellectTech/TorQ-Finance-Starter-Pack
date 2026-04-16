// quotestuffing.q — Quote stuffing detection
// Flags symbols with a burst of rapid quote updates within a short window
// where the price barely moves — high activity with flat pricing is suspicious.

\d .surv.qs

detect:{[]
  h:.surv.rdbh[];
  if[null h; .lg.w[`survqs;"no RDB handle — skipping quote stuffing detection"]; :()];

  cutoff:.proc.cp[] - .surv.cfg.qs.lookback;
  quotes:h("select time,sym,bid,ask,quoteid from quote where time >= x";cutoff);

  if[0=count quotes; :()];

  // Aggregate per symbol
  stats:select
    cnt:count i,
    pricerange:(max ask) - min bid,
    lastid:last quoteid
    by sym from quotes;

  cntthresh:.surv.cfg.qs.countthreshold;
  minmove:.surv.cfg.qs.minpricemove;

  flagged:select from stats where cnt > cntthresh,pricerange < minmove;
  if[0=count flagged; :()];

  // Assign severity
  n:count flagged;
  severity:n#`low;
  severity:?[flagged[`cnt] > 2*cntthresh; n#`medium; severity];
  severity:?[flagged[`cnt] > 3*cntthresh; n#`high; severity];

  // Build notes strings
  lookbacksecs:string`long$1e9 xbar .surv.cfg.qs.lookback%1000000000;
  notes:{[s;c;r;ct;mm;lbs]
    (string s)," had ",(string c)," quotes in ",(lbs),"s window, price range ",
    (string r)," (threshold ",(string ct)," quotes, min move ",(string mm),")"
    } .' flip (flagged`sym; flagged`cnt; flagged`pricerange;
               n#cntthresh; n#minmove; n#lookbacksecs);

  now:.proc.cp[];
  alerts:([]
    time:n#now;
    sym:flagged`sym;
    alerttype:n#`quotestuffing;
    severity:severity;
    refid:flagged`lastid;
    price:n#0n;
    size:`long$flagged`cnt;
    threshold:n#`float$cntthresh;
    actual:`float$flagged`cnt;
    notes:notes);

  .lg.o[`survqs;"quote stuffing: ",(string n)," alert(s) generated"];
  .surv.alert[alerts];}

\d .

.api.add[`.surv.qs.detect;1b;
  "Detect quote stuffing bursts — high quote count with flat pricing — and publish alerts";
  "[]";"()"];
