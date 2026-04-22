\d .surv.pxdev

detect:{
  h:.surv.rdbh[];
  if[null h; .lg.w[`surv;"no rdb handle"]; :()];
  cutoff:.proc.cp[]-.surv.cfg.pxdev.lookback;
  trades:h"select time,sym,price,tradeid from trade where time >= ",.Q.s1 cutoff;
  if[0=count trades; :()];
  quotes:`sym`time xasc h"select time,sym,bid,ask from quote";
  joined:aj[`sym`time; trades; quotes];
  joined:select from joined where not null bid, not null ask;
  if[0=count joined; :()];
  joined:update mid:(bid+ask)%2 from joined;
  joined:select from joined where not mid=0f;
  if[0=count joined; :()];
  joined:update deviation:abs[price-mid]%mid from joined;
  flagged:select from joined where deviation > .surv.cfg.pxdev.threshold;
  if[0=count flagged; :()];
  alerted:h"exec refid from alert where alerttype=`pricedeviation";
  flagged:select from flagged where not tradeid in alerted;
  if[0=count flagged; :()];
  flagged:update severity:`low from flagged;
  flagged:update severity:`medium from flagged where deviation > 2*.surv.cfg.pxdev.threshold;
  flagged:update severity:`high from flagged where deviation > 3*.surv.cfg.pxdev.threshold;
  thr:.surv.cfg.pxdev.threshold;
  notes:{[r]
    "price ",(string r`price),
    " deviates ",(string "f"$100*r`deviation),
    "% from mid ",(string r`mid),
    " (bid ",(string r`bid),
    ", ask ",(string r`ask),")"
    } each flagged;
  alerts:([]
    sym:    flagged`sym;
    alerttype: count[flagged]#`pricedeviation;
    severity:  flagged`severity;
    refid:  flagged`tradeid;
    price:  flagged`price;
    size:   count[flagged]#0j;
    threshold: count[flagged]#thr;
    actual: flagged`deviation;
    notes:  notes);
  .lg.o[`surv;"pxdev.detect: ",(string count alerts)," alert(s) for syms: ",", " sv string exec distinct sym from alerts];
  .surv.alert[alerts]}

\d .

.api.add[`.surv.pxdev.detect;1b;"Price deviation detection — queries RDB trade/quote, flags trades where abs(price-mid)/mid exceeds threshold";"[]";""];