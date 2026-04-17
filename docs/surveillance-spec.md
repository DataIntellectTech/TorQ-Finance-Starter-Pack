# Surveillance Process — Implementation Spec

## Overview

Add a polling-based surveillance process to the TorQ Finance Starter Pack. The
process periodically queries the RDB for three anomaly scenarios and publishes
any resulting alerts to the segmented tickerplant, from which they flow to the
RDB (and eventually the HDB) via the existing subscription path.

---

## 1. New Process: `surveiller`

### Identity

| field | value |
|-------|-------|
| proctype | `surveiller` |
| procname | `surveiller1` |
| port | `{KDBBASEPORT}+25` |
| load | `${KDBAPPCODE}/processes/surveiller.q` |
| startwithall | 1 |

### Behaviour

- Resolves outbound handles to the RDB and segmented tickerplant through
  `.servers.getservers` (never `hopen`). Handles are looked up fresh on each
  poll and each publish so the process self-heals if either counterparty
  restarts
- Polls on independent timers — one per detection type, each with a
  configurable interval
- On each tick, the detection function runs a query against the RDB for a
  rolling lookback window, evaluates its rules, and publishes any alerts to
  the tickerplant via `.u.upd`
- Alerts flow to the RDB automatically via normal TP subscription — no extra
  wiring on either side

### File structure

```
code/
├── surveiller/                  Auto-loaded by TorQ when proctype=surveiller
│   ├── volumespike.q            Volume spike detection
│   ├── pricedeviation.q         Trade-vs-quote price deviation detection
│   └── quotestuffing.q          Quote stuffing detection
└── processes/
    └── surveiller.q             -load entry: alert helper, timer wiring, .servers.startup[]
```

TorQ auto-loads `${KDBAPPCODE}/{proctype}/` for every process of that proctype
before the `-load` file runs. The three detection files therefore pick up
automatically — no `\l` statements needed. `code/processes/surveiller.q` is
the explicit entry point: it defines the `.surv.alert` publish helper, wires
one timer per detect function, then sets up connections.

### Namespace

All surveillance code lives under `.surv.*`:
- `.surv.cfg.*`  — configuration (thresholds, windows, intervals)
- `.surv.vol.*`  — volume spike logic
- `.surv.pxdev.*` — price deviation logic
- `.surv.qs.*`   — quote stuffing logic
- `.surv.alert`  — publish helper: sends a table of alert rows to the TP
- `.surv.rdbh`   — function returning current RDB handle
- `.surv.tph`    — function returning current segmented-tickerplant handle

### Connection setup

At the end of `code/processes/surveiller.q`, after returning to root namespace:

```q
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,`segmentedtickerplant`rdb;
.servers.startup[];
```

Both lines are required. `.servers.CONNECTIONS` declares which proctypes this
process may connect to; omitting `segmentedtickerplant` or `rdb` silently
produces null handles at runtime. `.servers.startup[]` is not called
automatically by TorQ — every process is responsible for invoking it itself.

### Timer registration

Each detect function is wrapped in an error trap before being scheduled so
that a transient failure (for example, a brief RDB disconnection) logs an
error rather than disabling the timer (Rule T3):

```q
.timer.repeat[.proc.cp[];0Wp;.surv.cfg.vol.interval;
  ({@[.surv.vol.detect;();{.lg.e[`surv;x]}]};`);
  "Volume spike detection"];
```

---

## 2. Alert Table Schema

Added to `database.q`:

```q
alert:([]
  time:`timestamp$();          / alert generation time
  sym:`g#`symbol$();           / instrument symbol
  alerttype:`symbol$();        / `volumespike`pricedeviation`quotestuffing
  severity:`symbol$();         / `low`medium`high
  refid:`long$();              / tradeid or quoteid that triggered the alert
  price:`float$();             / relevant price (trade price, or 0n for quote stuffing)
  size:`long$();               / relevant size (trade size, or quote count for stuffing)
  threshold:`float$();         / threshold value that was breached
  actual:`float$();            / actual value that breached it
  notes:()                     / human-readable explanation (string list)
  )
```

`database.q` is the schema file passed to the segmented tickerplant via
`-schemafile`, so defining `alert` there satisfies the requirement that every
published table's schema exists on the receiving process (Rule S4). The RDB
picks up the same schema through its normal TP subscription.

`time` first, `sym` second with the `` `g# `` attribute, table unkeyed — the
standard TP-subscribable shape.

---

## 3. Detection Scenarios

### 3.1 Volume Spike

**Concept:** A single trade whose size is abnormally large compared to the
recent average trade size for that symbol.

**Detection function:** `.surv.vol.detect[]`

**Logic:**
1. Query RDB for trades in the last N minutes (configurable lookback)
2. Per symbol, compute mean and stddev of `size`; discard symbols with fewer
   than 2 trades (stddev is undefined)
3. Flag any trade where `size > mean + (multiplier * stddev)`
4. Publish one alert row per flagged trade, severity `` `high ``

**Configuration (`.surv.cfg.vol.*`):**

| param | default | description |
|-------|---------|-------------|
| `lookback` | `0D00:05` | Rolling window to compute baseline |
| `multiplier` | `3.0` | Number of standard deviations above mean |
| `interval` | `0D00:00:10` | Timer frequency |

---

### 3.2 Price Deviation (Trade vs Prevailing Quote)

**Concept:** A trade executes at a price that differs abnormally from the
prevailing best bid/ask for that symbol at trade time. Could indicate a bad
fill, a fat finger, or stale pricing.

**Detection function:** `.surv.pxdev.detect[]`

**Logic:**
1. Query RDB for trades in the last N minutes
2. Query RDB for the quote table and sort by `` `sym`time `` (as-of join
   requires the right-hand table sorted this way)
3. Pair each trade with the prevailing quote via `aj[`sym`time;trades;quotes]`
4. Compute `mid:(bid+ask)%2` and `dev:abs[price-mid]%mid`
5. Flag trades where `dev > threshold`
6. Severity bands (applied in order so higher overrides lower):
   `` `low `` > threshold, `` `medium `` > 2× threshold, `` `high `` > 3×
7. Publish one alert row per flagged trade

**Configuration (`.surv.cfg.pxdev.*`):**

| param | default | description |
|-------|---------|-------------|
| `lookback` | `0D00:05` | Window of recent trades to check |
| `threshold` | `0.02` | 2% deviation from mid triggers alert |
| `interval` | `0D00:00:10` | Timer frequency |

---

### 3.3 Quote Stuffing

**Concept:** A burst of rapid quote updates for a single symbol within a short
window where the price barely moves. In real markets this can indicate an
attempt to slow competitors' processing or to manipulate the book.

**Detection function:** `.surv.qs.detect[]`

**Logic:**
1. Query RDB for quotes in the last N seconds
2. Per symbol, compute `cnt` (number of quotes), `pricerange:(max ask)-min bid`,
   and `lastid:last quoteid`
3. Flag symbols where `cnt > countthreshold` AND `pricerange < minpricemove`
4. Severity: `` `low `` > 1×, `` `medium `` > 2×, `` `high `` > 3× of
   `countthreshold`
5. Publish one alert per flagged symbol (the burst is the event, not each
   quote). `refid` references the last `quoteid` in the burst

**Configuration (`.surv.cfg.qs.*`):**

| param | default | description |
|-------|---------|-------------|
| `lookback` | `0D00:00:05` | Short rolling window (5 seconds) |
| `countthreshold` | `50` | Quotes per symbol in window to trigger |
| `minpricemove` | `0.5` | Max price range — below this is "flat" |
| `interval` | `0D00:00:05` | Timer frequency |

---

## 4. Configuration File

`appconfig/settings/surveiller.q` — all values use the guard pattern so they
remain overridable from any lower-priority config layer and from the command
line:

```q
\d .surv

cfg.rdbtypes:@[value;`cfg.rdbtypes;`rdb]

/ Volume spike
cfg.vol.lookback:@[value;`cfg.vol.lookback;0D00:05]
cfg.vol.multiplier:@[value;`cfg.vol.multiplier;3.0]
cfg.vol.interval:@[value;`cfg.vol.interval;0D00:00:10]

/ Price deviation
cfg.pxdev.lookback:@[value;`cfg.pxdev.lookback;0D00:05]
cfg.pxdev.threshold:@[value;`cfg.pxdev.threshold;0.02]
cfg.pxdev.interval:@[value;`cfg.pxdev.interval;0D00:00:10]

/ Quote stuffing
cfg.qs.lookback:@[value;`cfg.qs.lookback;0D00:00:05]
cfg.qs.countthreshold:@[value;`cfg.qs.countthreshold;50]
cfg.qs.minpricemove:@[value;`cfg.qs.minpricemove;0.5]
cfg.qs.interval:@[value;`cfg.qs.interval;0D00:00:05]

\d .
```

A command-line override uses the fully qualified name, e.g.
`-.surv.cfg.vol.multiplier 4.0`. If pre-setting a value from a higher-priority
config layer or a test harness, assign the fully qualified name as well
(`.surv.cfg.vol.multiplier:4.0`) — a bare `cfg.vol.multiplier:4.0` set outside
the `\d .surv` block resolves to root and is silently ignored (Rule C5).

---

## 5. Feed Modifications

### 5.1 New Columns

Add to `trade` in `database.q`:
- `tradeid` (`long`) — monotonically increasing ID per trade

Add to `quote` in `database.q`:
- `quoteid` (`long`) — monotonically increasing ID per quote

The feed maintains running counters (`.feed.tradeid`, `.feed.quoteid`) and
assigns IDs as rows are generated. These IDs appear in alert rows as `refid`
so investigators can trace back to the exact event.

### 5.2 Anomaly Injection

Modify the feed to periodically inject scenarios that reliably trigger each
detector. Use independent timers so scenarios overlap naturally with the
normal traffic.

**Volume spike injection** — every 30–60s, pick a random symbol, publish a
single trade with `size` ≈ 10× the normal range for that symbol.

**Price deviation injection** — every 30–60s, pick a random symbol, publish a
trade whose price is offset 5–10% from the current base price (well above the
2% threshold).

**Quote stuffing injection** — every 20–40s, pick a random symbol, publish a
burst of 80+ quotes for that symbol with near-identical bid/ask (price
movement < 0.1) in a single `.u.upd` call. 80 > the 50-quote threshold and
the flat price meets the range criterion.

### 5.3 Feed Code Organisation

Keep anomaly injection separate from the normal feed path:
```
code/tick/
├── feed.q              Existing feed, modified to include tradeid/quoteid
└── feed_anomalies.q    Anomaly injection functions, loaded by feed.q
```

---

## 6. Other Changes

### process.csv
Add one row for `surveiller1`.

### Credentials
Outbound authentication is hierarchical: `$KDBAPPCONFIG/passwords/surveiller.txt`
with contents `surveiller:pass` is required so the surveiller authenticates
when opening handles. Inbound: add `surveiller:pass` to
`appconfig/passwords/accesslist.txt` so the TP and RDB accept it. Missing
either side produces a silent `'access` error at connection time (Rule M6 /
checklist item 17).

### sort.csv
Add `alert` with sort columns `sym`, `time` so WDB-side sorting handles it
like every other subscribed table.

### API documentation
Each `detect` function and the `alert` helper is registered with `.api.add`
(Rule A1) so they're discoverable via `.api.p` / `.api.s`.

---

## 7. Summary of Files Changed / Created

**New files:**
- `code/processes/surveiller.q`
- `code/surveiller/volumespike.q`
- `code/surveiller/pricedeviation.q`
- `code/surveiller/quotestuffing.q`
- `code/tick/feed_anomalies.q`
- `appconfig/settings/surveiller.q`
- `appconfig/passwords/surveiller.txt`

**Modified files:**
- `database.q` — add `alert` table, add `tradeid` to `trade`, add `quoteid` to `quote`
- `code/tick/feed.q` — add ID counters, load `feed_anomalies.q`, wire anomaly timers
- `appconfig/process.csv` — add `surveiller1` row
- `appconfig/passwords/accesslist.txt` — add `surveiller:pass`
- `appconfig/sort.csv` (if present) — add `alert`
