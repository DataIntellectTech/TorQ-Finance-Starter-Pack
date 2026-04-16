# Surveillance Process — Implementation Prompts

Six prompts to implement the surveillance process described in `surveillance-spec.md`.
Run them in order — each prompt assumes the previous one is already applied.

---

## Prompt 1 — Schema & Infrastructure

**Task:** Make the infrastructure changes required before any surveillance code can run.

**Files to modify:**

`database.q` — add `tradeid:\`long$()` as the last column of `trade`; add `quoteid:\`long$()` as the last column of `quote`; append a new `alert` table with exactly this schema (column order must match):
```q
alert:([]
  time:`timestamp$();
  sym:`g#`symbol$();
  alerttype:`symbol$();
  severity:`symbol$();
  refid:`long$();
  price:`float$();
  size:`long$();
  threshold:`float$();
  actual:`float$();
  notes:()
  )
```
`notes` is a generic list — each row holds a string (character vector). Follow Rule S7 — the table must be unkeyed (type 98h). Follow Rule S2 — `sym` carries `` `g# ``.

`appconfig/process.csv` — add one row for `surveillance1`: port `{KDBBASEPORT}+25`, proctype `surveillance`, load `${KDBAPPCODE}/processes/surveillance.q`, `startwithall` 1, `U` pointing to the shared access list.

`appconfig/passwords/accesslist.txt` — append `surveillance:pass`.

**Constraints:** Do not rename or reorder any existing columns in `trade` or `quote`.

---

## Prompt 2 — Config File & Main Process Scaffold

**Task:** Create the config file and the main `surveillance.q` entry point. No detection logic yet — just wiring.

**Files to create:**

`appconfig/settings/surveillance.q`
— All variables inside `\d .surv` / `\d .` block. Every variable uses the TorQ guard pattern: `cfg.vol.lookback:@[value;\`cfg.vol.lookback;0D00:05]`. Define:
```
cfg.rdbtypes:`rdb
cfg.vol.lookback      0D00:05
cfg.vol.multiplier    3.0
cfg.vol.interval      0D00:00:10
cfg.pxdev.lookback    0D00:05
cfg.pxdev.threshold   0.02
cfg.pxdev.interval    0D00:00:10
cfg.qs.lookback       0D00:00:05
cfg.qs.countthreshold 50
cfg.qs.minpricemove   0.5
cfg.qs.interval       0D00:00:05
```

`code/processes/surveillance.q`
— Namespace `\d .surv` / `\d .`. Must:
1. Load the three scenario files: `\l code/processes/surveillance/volumespike.q` etc.
2. Define `.surv.alert` — the publishing utility. Signature: `{[rows] h:.surv.tph[]; if[null h; .lg.w[\`surv;"no tickerplant handle"]; :()]; h(\`.u.upd;\`alert;value flip rows); .lg.o[\`surv;"published ",(string count rows)," alert(s)"]}`. Define `.surv.tph:{first exec w from .servers.getservers[\`proctype;\`tickerplant;()!();1b;0b]}` as a separate helper.
3. Define `.surv.rdbh:{first exec w from .servers.getservers[\`proctype;.surv.cfg.rdbtypes;()!();1b;0b]}`. If the result is null, the detection functions will log and return — no need to signal here.
4. Set `.servers.CONNECTIONS:distinct .servers.CONNECTIONS,\`tickerplant\`rdb`.
5. After loading scenario files, register three timers using `.timer.repeat`. Each timer calls the corresponding `.surv.vol.detect`, `.surv.pxdev.detect`, `.surv.qs.detect` at the configured interval. Wrap each callback: `{@[.surv.vol.detect;();{.lg.e[\`surv;x]}]}` so a detection error does not remove the timer from the schedule (Rule T3).
6. Call `.servers.startup[]` at end of file (Rule M1).
7. Use `.lg.o` for all log messages (Rule L1).

---

## Prompt 3 — Volume Spike Detection

**Task:** Implement `.surv.vol.detect[]` in `code/processes/surveillance/volumespike.q`.

**Logic (from spec §3.1):**
1. Get the RDB handle via `.surv.rdbh[]`. If null, log a warning and return.
2. Query the RDB for all trades in the last `.surv.cfg.vol.lookback` window: `select time,sym,size,tradeid from trade where time >= .proc.cp[] - .surv.cfg.vol.lookback`.
3. Compute per-symbol mean and stddev of `size`. If a symbol has only one trade (stddev = 0), skip it — filter for `count >= 2` per sym to avoid noise.
4. Threshold per symbol = `mean + (.surv.cfg.vol.multiplier * dev)`.
5. Join thresholds back to trade rows and flag trades where `size > threshold`.
6. For each flagged trade build one alert row:
   - `time`: `.proc.cp[]`
   - `sym`: trade sym
   - `alerttype`: `` `volumespike ``
   - `severity`: `` `high ``
   - `refid`: tradeid
   - `price`: `0n`
   - `size`: trade size (cast to long)
   - `threshold`: computed threshold (float)
   - `actual`: trade size cast to float
   - `notes`: string describing the breach, e.g. `"size 45000 exceeds threshold 12480.3 (mean 1200.0, 3.0 stddevs)"`
7. If any alerts exist, call `.surv.alert[alerts]`.

**Constraints:**
- All code in `\d .surv.vol` / `\d .` block.
- `notes` must be a string (character vector) per row — use `enlist` when building a single-row table so the column remains a generic list.
- Use `.proc.cp[]` not `.z.p` for current time.
- Document `.surv.vol.detect` with `.api.add`.

---

## Prompt 4 — Price Deviation Detection

**Task:** Implement `.surv.pxdev.detect[]` in `code/processes/surveillance/pricedeviation.q`.

**Logic (from spec §3.2):**
1. Get RDB handle. If null, log warning and return.
2. Query trades in the last `.surv.cfg.pxdev.lookback` window: `select time,sym,price,tradeid from trade where time >= .proc.cp[] - .surv.cfg.pxdev.lookback`.
3. Query all quotes from RDB: `select time,sym,bid,ask from quote`.
4. Use `aj[\`sym\`time; trades; quotes]` to pair each trade with the prevailing quote at trade time.
5. Drop rows where `bid` or `ask` is null (trades with no matching quote).
6. Compute `mid:(bid+ask)%2`. Drop rows where `mid=0`.
7. Compute `dev:abs[price-mid]%mid`.
8. Filter rows where `dev > .surv.cfg.pxdev.threshold`.
9. Assign severity (apply in order so higher bands overwrite):
   - Start with `` `low ``
   - `` `medium `` if `dev > 2 * threshold`
   - `` `high `` if `dev > 3 * threshold`
10. Build one alert row per flagged trade:
    - `alerttype`: `` `pricedeviation ``
    - `refid`: tradeid
    - `price`: trade price
    - `size`: `0`
    - `threshold`: `.surv.cfg.pxdev.threshold`
    - `actual`: computed `dev` value
    - `notes`: e.g. `"price 84.5 deviates 8.3% from mid 78.0 (bid 77.5, ask 78.5)"`
11. Call `.surv.alert[alerts]`.

**Constraints:**
- Namespace `\d .surv.pxdev` / `\d .`.
- `notes` is a string per row — use `enlist` for single-row results.
- Document `.surv.pxdev.detect` with `.api.add`.

---

## Prompt 5 — Quote Stuffing Detection

**Task:** Implement `.surv.qs.detect[]` in `code/processes/surveillance/quotestuffing.q`.

**Logic (from spec §3.3):**
1. Get RDB handle. If null, log warning and return.
2. Query quotes in last `.surv.cfg.qs.lookback` window: `select time,sym,bid,ask,quoteid from quote where time >= .proc.cp[] - .surv.cfg.qs.lookback`.
3. Group by sym. Per symbol compute:
   - `cnt`: count of quotes
   - `pricerange`: `(max ask) - (min bid)`
   - `lastid`: last `quoteid` in the window (for `refid`)
4. Flag symbols where `cnt > .surv.cfg.qs.countthreshold` **and** `pricerange < .surv.cfg.qs.minpricemove`.
5. Assign severity:
   - `` `low `` if `cnt > 1 * countthreshold`
   - `` `medium `` if `cnt > 2 * countthreshold`
   - `` `high `` if `cnt > 3 * countthreshold`
6. Build **one alert row per flagged symbol**:
   - `alerttype`: `` `quotestuffing ``
   - `refid`: `lastid`
   - `price`: `0n`
   - `size`: `cnt` (cast to long)
   - `threshold`: `countthreshold` cast to float
   - `actual`: `cnt` cast to float
   - `notes`: e.g. `"85 quotes for AAPL in 5s window, price range 0.02 (threshold 50 quotes, min move 0.5)"`
7. Call `.surv.alert[alerts]`.

**Constraints:**
- Namespace `\d .surv.qs` / `\d .`.
- One row per symbol, not per quote.
- `notes` is a string per row — use `enlist` for single-row results.
- Document `.surv.qs.detect` with `.api.add`.

---

## Prompt 6 — Feed Modifications & Anomaly Injection

**Task:** Modify the feed to assign IDs and inject anomalies. Read `code/tick/feed.q` in full before making any changes.

**Part A — `code/tick/feed.q` changes (minimal):**
1. Add two running counters after the existing globals: `.feed.tradeid:0j` and `.feed.quoteid:0j`.
2. In the trade-generation path, before publishing: assign IDs to the batch by computing `ids:.feed.tradeid+1+til count rows`, then set `.feed.tradeid:.feed.tradeid+count rows`, then `update tradeid:ids` on the rows. IDs start at 1 and increase monotonically.
3. Apply the same pattern for quote rows using `.feed.quoteid`.
4. At the bottom of `feed.q`, after all existing setup: load the anomaly file with `\l` and call `.feed.anom.setup[]`.

**Part B — `code/tick/feed_anomalies.q` (new file):**
Namespace `\d .feed.anom` / `\d .`. Three injection functions plus a setup function:

**`.feed.anom.injectvol[]`** — volume spike (timer: every 45 seconds):
- Pick `sym:syms[rand count syms]` using the `syms` list from feed.q.
- Publish one trade row: `size` = `50000j`, `price` = base price for that sym from the prices dict, `stop` = `0b`, `cond` = `" "`, `ex` = `"N"`, `side` = `` `buy ``, `tradeid` = `.feed.tradeid+:1; .feed.tradeid`.
- Publish via `.u.upd[\`trade; value flip enlist row]`.

**`.feed.anom.injectpxdev[]`** — price deviation (timer: every 45 seconds):
- Pick a random sym.
- Get base price from the prices dict in feed.q.
- Publish one trade row with `price` = `baseprice * 1.08` (8% above base — well above the 2% threshold). Other fields: `size` = `100i`, `stop` = `0b`, `cond` = `" "`, `ex` = `"N"`, `side` = `` `buy ``, `tradeid` = `.feed.tradeid+:1; .feed.tradeid`.
- Publish via `.u.upd[\`trade; value flip enlist row]`.

**`.feed.anom.injectqs[]`** — quote stuffing (timer: every 30 seconds):
- Pick a random sym.
- Get base price. Build a table of 85 rows for that sym: `bid` = `baseprice - 0.01`, `ask` = `baseprice + 0.01` (price movement across the burst < 0.1, meeting the flat-price criterion). `bsize` = `100`, `asize` = `100`, `mode` = `" "`, `ex` = `"N"`, `src` = `` `INJECT ``.
- Assign `quoteid`s: `ids:.feed.quoteid+1+til 85`, then `.feed.quoteid:.feed.quoteid+85`.
- Publish all 85 rows in a single `.u.upd[\`quote; value burst]` call.

**`.feed.anom.setup[]`:**
- Registers all three timers using `.timer.repeat` with start time `.proc.cp[]`, end time `0Wp`, and the configured intervals (hardcode 45s/45s/30s as atoms — these are injection helpers, not user-facing config).
- Wrap each callback in an error trap (Rule T3).
- Log `"anomaly injection timers registered"` with `.lg.o[\`feedanom;...]`.

**Constraints:**
- Do not alter any existing trade or quote generation logic — only add ID assignment in the two publishing paths and the load/setup call at the bottom.
- The `src` column on injected quotes is `` `INJECT `` so injected rows are distinguishable in the data if needed.
- Verify the column order of rows passed to `.u.upd` matches the schema in `database.q` exactly — the tickerplant does a positional insert.