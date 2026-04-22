# Surveillance Process — Implementation Spec

## Overview

Add a polling-based surveillance process to the TorQ Finance Starter Pack. The
process periodically queries the RDB for price-deviation anomalies and
publishes any resulting alerts to the segmented tickerplant, from which they
flow to the RDB (and eventually the HDB) via the existing subscription path.

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
- Polls on a configurable-interval timer
- On each tick, the detection function runs a query against the RDB for a
  rolling lookback window, evaluates its rules, and publishes any alerts to
  the tickerplant via `.u.upd`
- Alerts flow to the RDB automatically via normal TP subscription — no extra
  wiring on either side

### File structure

```
code/
├── surveiller/                  Auto-loaded by TorQ when proctype=surveiller
│   └── pricedeviation.q         Trade-vs-quote price deviation detection
└── processes/
    └── surveiller.q             -load entry: alert helper, timer wiring, .servers.startup[]
```

TorQ auto-loads `${KDBAPPCODE}/{proctype}/` for every process of that proctype
before the `-load` file runs. The detection file therefore picks up
automatically — no `\l` statements needed. `code/processes/surveiller.q` is
the explicit entry point: it defines the `.surv.alert` publish helper, wires
the detect timer, then sets up connections.

### Namespace

All surveillance code lives under `.surv.*`:
- `.surv.cfg.*`   — configuration (thresholds, windows, intervals)
- `.surv.pxdev.*` — price deviation logic
- `.surv.alert`   — publish helper: sends a table of alert rows to the TP
- `.surv.rdbh`    — function returning current RDB handle
- `.surv.tph`     — function returning current segmented-tickerplant handle

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

The detect function is wrapped in an error trap before being scheduled so
that a transient failure (for example, a brief RDB disconnection) logs an
error rather than disabling the timer (Rule T3):

```q
.timer.repeat[.proc.cp[];0Wp;.surv.cfg.pxdev.interval;
  ({@[.surv.pxdev.detect;();{.lg.e[`surv;x]}]};`);
  "Price deviation detection"];
```

---

## 2. Alert Table Schema

Added to `database.q`:

```q
alert:([]
  time:`timestamp$();          / alert generation time
  sym:`g#`symbol$();           / instrument symbol
  alerttype:`symbol$();        / `pricedeviation (reserved as symbol for future detectors)
  severity:`symbol$();         / `low`medium`high
  refid:`long$();              / tradeid that triggered the alert
  price:`float$();             / trade price
  size:`long$();               / trade size
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

## 3. Detection Scenario — Price Deviation (Trade vs Prevailing Quote)

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

## 4. Configuration File

`appconfig/settings/surveiller.q` — all values use the guard pattern so they
remain overridable from any lower-priority config layer and from the command
line:

```q
\d .surv

cfg.rdbtypes:@[value;`cfg.rdbtypes;`rdb]

/ Price deviation
cfg.pxdev.lookback:@[value;`cfg.pxdev.lookback;0D00:05]
cfg.pxdev.threshold:@[value;`cfg.pxdev.threshold;0.02]
cfg.pxdev.interval:@[value;`cfg.pxdev.interval;0D00:00:10]

\d .
```

A command-line override uses the fully qualified name, e.g.
`-.surv.cfg.pxdev.threshold 0.05`. If pre-setting a value from a higher-priority
config layer or a test harness, assign the fully qualified name as well
(`.surv.cfg.pxdev.threshold:0.05`) — a bare `cfg.pxdev.threshold:0.05` set
outside the `\d .surv` block resolves to root and is silently ignored (Rule C5).

---

## 5. Feed Modifications

### 5.1 New Columns

Add to `trade` in `database.q`:
- `tradeid` (`long`) — monotonically increasing ID per trade

The feed maintains a running counter (`.feed.tradeid`) and assigns IDs as rows
are generated. These IDs appear in alert rows as `refid` so investigators can
trace back to the exact event.

### 5.2 Anomaly Injection

Modify the feed to periodically inject price-deviation scenarios that reliably
trigger the detector. Every 30–60s, pick a random symbol and publish a trade
whose price is offset 5–10% from the current base price (well above the 2%
threshold).

### 5.3 Feed Code Organisation

Keep anomaly injection separate from the normal feed path:
```
code/tick/
├── feed.q              Existing feed, modified to include tradeid
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
The `detect` function and the `alert` helper are registered with `.api.add`
(Rule A1) so they're discoverable via `.api.p` / `.api.s`.

---

## 7. Summary of Files Changed / Created

**New files:**
- `code/processes/surveiller.q`
- `code/surveiller/pricedeviation.q`
- `code/tick/feed_anomalies.q`
- `appconfig/settings/surveiller.q`
- `appconfig/passwords/surveiller.txt`

**Modified files:**
- `database.q` — add `alert` table, add `tradeid` to `trade`
- `code/tick/feed.q` — add ID counter, load `feed_anomalies.q`, wire anomaly timer
- `appconfig/process.csv` — add `surveiller1` row
- `appconfig/passwords/accesslist.txt` — add `surveiller:pass`
- `appconfig/sort.csv` (if present) — add `alert`
