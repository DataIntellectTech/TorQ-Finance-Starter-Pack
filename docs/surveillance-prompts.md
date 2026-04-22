# Surveillance Process — Implementation Prompts

Four prompts to implement the surveiller process described in `surveillance-spec.md`, structured around the torq-developer skill's two-stage workflow:

- **Stage 1 — Plumbing** (Prompts 1–2): schemas, process registration, credentials, and a scaffold that starts cleanly and opens every declared handle. No detection logic.
- **Stage 1 Verification Gate**: must pass before any Stage 2 work begins.
- **Stage 2 — Feature logic** (Prompts 3–4): real detection, alert publishing, and feed anomaly injection.

Run the prompts in order. Do not collapse stages — layering detection code onto broken plumbing produces bugs that look like logic errors but aren't.

---

## Stage 1 — Plumbing

### Prompt 1 — Schema, Process Registration, Credentials

**Task:** Make the infrastructure changes required before any surveillance code can run. No q logic yet.

**Files to modify:**

`database.q` — add `tradeid:`long$()` as the last column of `trade`; append the `alert` table with exactly this schema (column order must match — the tickerplant does positional inserts):
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
`notes` is a generic list — each row holds a string. Follow Rule S7 (unkeyed, type 98h) and Rule S2 (`sym` carries `` `g# ``). `database.q` is the segmented tickerplant's `-schemafile`, so defining the table here also makes the schema available on every downstream subscriber (Rule S4).

`appconfig/process.csv` — add one row for `surveiller1`: port `{KDBBASEPORT}+25`, proctype `surveiller`, load `${KDBAPPCODE}/processes/surveiller.q`, `startwithall` 1, `U` pointing to the shared access list.

`appconfig/passwords/accesslist.txt` — append `surveiller:pass` so the STP and RDB accept inbound connections from surveiller.

**Files to create:**

`appconfig/passwords/surveiller.txt` — single line: `surveiller:pass`. Required for outbound auth when surveiller opens handles (Rule M6).

**Constraints:**
- Do not rename or reorder any existing columns in `trade`.
- Missing either credential side silently produces `'access` at connection time — both must be in place (checklist item 17).

**If `appconfig/sort.csv` exists:** add a row for `alert` with sort columns `sym`,`time` so WDB-side sorting handles it like every other subscribed table. Optional — omit if the file is not present in the deployment.

---

### Prompt 2 — Config File & Scaffold with Stub Detect

**Task:** Create the config file and a surveiller scaffold that starts, opens handles, and fires a stubbed detect timer. No real detection logic — that lives in Prompt 3.

**Files to create:**

`appconfig/settings/surveiller.q` — all variables inside `\d .surv` / `\d .`, each using the guard pattern (Rule C1). Because the guard resolves to the current namespace, setting a bare variable outside `\d .surv` would silently root-scope (Rule C5):
```q
\d .surv
cfg.rdbtypes:@[value;`cfg.rdbtypes;`rdb]
cfg.pxdev.lookback:@[value;`cfg.pxdev.lookback;0D00:05]
cfg.pxdev.threshold:@[value;`cfg.pxdev.threshold;0.02]
cfg.pxdev.interval:@[value;`cfg.pxdev.interval;0D00:00:10]
\d .
```

`code/processes/surveiller.q` — the `-load` entry point. Namespace `\d .surv` / `\d .`.

`code/surveiller/` is auto-loaded by TorQ for proctype `surveiller` before the `-load` file runs, so the detection file created in Prompt 3 picks up automatically — **do not** `\l` it here. In Prompt 3 that file will define the real `.surv.pxdev.detect`, overriding the stub defined below.

Inside the file:

1. `tph` — tickerplant handle resolver. FSP uses the segmented tickerplant:
   ```q
   tph:{first exec w from .servers.getservers[`proctype;`segmentedtickerplant;()!();1b;0b]}
   ```
2. `rdbh` — RDB handle resolver:
   ```q
   rdbh:{first exec w from .servers.getservers[`proctype;.surv.cfg.rdbtypes;()!();1b;0b]}
   ```
3. `alert` — publish helper:
   ```q
   alert:{[rows]
     h:.surv.tph[];
     if[null h; .lg.w[`surv;"no tickerplant handle"]; :()];
     h(`.u.upd;`alert;value flip rows);
     .lg.o[`surv;"published ",(string count rows)," alert(s)"]}
   ```
4. `pxdev.detect` — **Stage 1 stub only**. Prompt 3 replaces it:
   ```q
   pxdev.detect:{.lg.o[`surv;"pxdev.detect stub"]}
   ```
5. Timer (Rule T3 — wrap so a failure does not remove the timer from the schedule):
   ```q
   .timer.repeat[.proc.cp[];0Wp;.surv.cfg.pxdev.interval;
     ({@[.surv.pxdev.detect;();{.lg.e[`surv;x]}]};`);
     "Price deviation detection"];
   ```
6. After returning to root namespace (Rule M1 — both lines required; `.servers.startup[]` is not called automatically by TorQ):
   ```q
   .servers.CONNECTIONS:distinct .servers.CONNECTIONS,`segmentedtickerplant`rdb;
   .servers.startup[];
   ```
7. Use `.lg.o`/`.lg.w`/`.lg.e` for all log messages (Rule L1). Document public helpers (`.surv.alert`, `.surv.pxdev.detect`) with `.api.add` (Rule A1).

---

## Stage 1 Verification Gate

Restart the STP and RDB (so they pick up the updated `database.q`), then start surveiller1. Confirm **every** item below before proceeding to Stage 2:

- [ ] `./torq.sh start surveiller1` succeeds; PID persists
- [ ] `err_surveiller1_*.log` contains no `ERR` lines after startup
- [ ] `out_surveiller1_*.log` shows expected startup messages
- [ ] In qcon on surveiller1: `select proctype, w from .servers.SERVERS where proctype in .servers.CONNECTIONS` — rows for `segmentedtickerplant` and `rdb` both have non-null `w`
- [ ] On the STP: `alert in tables[`.]` is `1b`; `last cols `trade` is `` `tradeid ``
- [ ] Timer fires: surveiller1's `out_` log shows repeated `pxdev.detect stub` messages at the configured interval

If any check fails, diagnose and fix before writing Stage 2 code. Do not proceed to "see if it still works" — that masks whichever Stage 1 issue is still broken.

---

## Stage 2 — Feature Logic

### Prompt 3 — Price Deviation Detection

**Task:** Implement the real `.surv.pxdev.detect[]` in `code/surveiller/pricedeviation.q`. This file is auto-loaded by TorQ for proctype `surveiller` and overrides the Stage 1 stub in `surveiller.q`.

Namespace `\d .surv.pxdev` / `\d .`.

**Logic (from spec §3):**
1. Get RDB handle via `.surv.rdbh[]`. If null, `.lg.w[\`surv;"no rdb handle"]` and return.
2. Query trades in the lookback window:
   ```q
   select time,sym,price,tradeid from trade where time >= .proc.cp[] - .surv.cfg.pxdev.lookback
   ```
3. Query quotes from RDB: `select time,sym,bid,ask from quote`, then `` `sym`time xasc `` before the join — `aj` requires the right-hand table sorted by sym then time.
4. `aj[\`sym\`time; trades; quotes]` to pair each trade with the prevailing quote.
5. Drop rows where `bid` or `ask` is null (no matching quote).
6. Compute `mid:(bid+ask)%2`. Drop rows where `mid=0`.
7. Compute `dev:abs[price-mid]%mid`.
8. Filter rows where `dev > .surv.cfg.pxdev.threshold`.
9. Assign severity (apply in order so higher bands overwrite):
   - start `` `low ``
   - `` `medium `` if `dev > 2 * threshold`
   - `` `high `` if `dev > 3 * threshold`
10. Build one alert row per flagged trade:
    - `time`: `.proc.cp[]`
    - `sym`: trade sym
    - `alerttype`: `` `pricedeviation ``
    - `severity`: computed band
    - `refid`: tradeid
    - `price`: trade price
    - `size`: `0`
    - `threshold`: `.surv.cfg.pxdev.threshold`
    - `actual`: computed `dev`
    - `notes`: e.g. `"price 84.5 deviates 8.3% from mid 78.0 (bid 77.5, ask 78.5)"`
11. Call `.surv.alert[alerts]`.

**Constraints:**
- Use `.proc.cp[]`, not `.z.p`, for current time.
- `notes` is a string per row — `enlist` for single-row results.
- Document `.surv.pxdev.detect` with `.api.add` (Rule A1).
- Rule Q1: for variable negation use `neg x`, not `-x`.
- Before sending to the TP, verify the columns/types you build match the `alert` schema in `database.q` exactly — the tickerplant does a positional insert (Core Principle 2, checklist item 18).

**After landing this prompt:** trigger the Prompt 4 injection (once that's in place) or wait for natural market data noise, and confirm `select from alert` on the RDB returns rows with the expected shape.

---

### Prompt 4 — Feed Modifications & Anomaly Injection

**Task:** Modify the feed to assign trade IDs and inject price-deviation anomalies. Read `code/tick/feed.q` in full before making any changes.

**Part A — `code/tick/feed.q` (minimal edits):**
1. Add a running counter alongside existing feed globals: `.feed.tradeid:0j`.
2. In the trade-generation path, before publishing: compute `ids:.feed.tradeid+1+til count rows`, set `.feed.tradeid:.feed.tradeid+count rows`, then `update tradeid:ids` on the rows. IDs start at 1 and increase monotonically.
3. At the bottom of `feed.q`, after all existing setup:
   ```q
   \l ${KDBAPPCODE}/tick/feed_anomalies.q
   .feed.anom.setup[];
   ```

**Part B — `code/tick/feed_anomalies.q` (new file):**
Namespace `\d .feed.anom` / `\d .`. Two functions:

**`.feed.anom.injectpxdev[]`** — price deviation:
- Pick `sym:syms[rand count syms]` using the `syms` list from feed.q.
- Get `baseprice` from the prices dict in feed.q.
- Build one trade row with column order matching the `trade` schema in `database.q` exactly:
  - `time:.proc.cp[]`, `sym`, `price:baseprice*1.08` (8% above base — well above the 2% threshold), `size:100i`, `stop:0b`, `cond:" "`, `ex:"N"`, `side:`buy`, `tradeid:.feed.tradeid+:1`
- Publish via `.u.upd[\`trade; value flip enlist row]`.

**`.feed.anom.setup[]`:**
- Register the timer — 45s is hardcoded as an atom (injection helper, not user-facing config):
  ```q
  .timer.repeat[.proc.cp[];0Wp;0D00:00:45;
    ({@[.feed.anom.injectpxdev;();{.lg.e[`feedanom;x]}]};`);
    "Price deviation anomaly injection"];
  ```
- `.lg.o[`feedanom;"anomaly injection timer registered"]`.

**Constraints:**
- Do not alter any existing trade generation logic — only add ID assignment in the publishing path and the load/setup call at the bottom of `feed.q`.
- Verify the column order of rows passed to `.u.upd` matches the `trade` schema in `database.q` exactly — positional insert (Core Principle 2, checklist item 18).
- Rule T3 error trap on the injection timer callback.

**Verification:**
- After restart, surveiller1's log shows alerts being published every ~45s.
- `select from alert` on the RDB returns rows with `alerttype=\`pricedeviation`, `severity` populated, and `refid` matching a real `tradeid` in `trade`.
