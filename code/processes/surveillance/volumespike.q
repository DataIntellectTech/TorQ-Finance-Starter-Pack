// volumespike.q — Volume spike detection
// Flags trades whose size is abnormally large relative to the recent
// rolling average for that symbol.

\d .surv.vol

detect:{[]
  h:.surv.rdbh[];
  if[null h; .lg.w[`survvol;"no RDB handle — skipping volume spike detection"]; :()];

  cutoff:.proc.cp[] - .surv.cfg.vol.lookback;
  trades:h("select time,sym,size,tradeid from trade where time >= x";cutoff);

  if[0=count trades; :()];

  // Per-symbol stats — require at least 2 trades for a meaningful stddev
  stats:select cnt:count i,meansize:avg size,devsize:dev size by sym from trades;
  stats:select from stats where cnt >= 2;

  if[0=count stats; :()];

  stats:update threshold:meansize + (.surv.cfg.vol.multiplier * devsize) from stats;

  // lj gives null threshold for syms with fewer than 2 trades — filtered below
  flagged:trades lj `sym xkey select sym,meansize,threshold from stats;
  flagged:select from flagged where not null threshold,size > threshold;

  if[0=count flagged; :()];

  // Build notes strings — pass flagged and multiplier explicitly to avoid
  // free-variable capture issues in q lambdas
  mult:.surv.cfg.vol.multiplier;
  notes:{[s;th;mn]
    "size ",(string`long$s)," exceeds threshold ",(string th),
    " (mean ",(string mn),", ",(string .surv.cfg.vol.multiplier)," stddevs)"
    } .' flip (flagged`size;flagged`threshold;flagged`meansize);

  now:.proc.cp[];
  n:count flagged;
  alerts:([]
    time:n#now;
    sym:flagged`sym;
    alerttype:n#`volumespike;
    severity:n#`high;
    refid:flagged`tradeid;
    price:n#0n;
    size:`long$flagged`size;
    threshold:flagged`threshold;
    actual:`float$flagged`size;
    notes:notes);

  .lg.o[`survvol;"volume spike: ",(string n)," alert(s) generated"];
  .surv.alert[alerts];}

\d .

.api.add[`.surv.vol.detect;1b;
  "Detect volume spikes in recent trades and publish alerts to tickerplant";
  "[]";"()"];
