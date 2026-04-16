# Surveillance Process — Implementation Spec

## Overview

Add a real-time surveillance process to the TorQ Finance Starter Pack. The process
periodically scans data in the RDB for three anomaly scenarios, publishing alerts to
the tickerplant for downstream persistence and querying.

---

## 1. New Process: `surveillance`

### Identity

| field | value |
|-------|-------|
| proctype | `surveillance` |
| procname | `surveillance1` |
| port | `{KDBBASEPORT}+25` |
| load | `${KDBAPPCODE}/processes/surveillance.q` |
| startwithall | 1 |

### Behaviour

- Connects to the RDB via the discovery service on startup
- Runs three detection functions on independent timers (configurable intervals)
- Each detection function queries the RDB, evaluates rules, and publishes any
  resulting alerts to the tickerplant via `.u.upd`
- Publishes to the `alert` table (schema defined below)

### File structure

```
code/processes/
├── surveillance.q               Main process: init, connections, timer setup
└── surveillance/
    ├── volumespike.q            Volume spike detection
    ├── pricedeviation.q         Trade-vs-quote price deviation detection
    └── quotestuffing.q          Quote stuffing detection
```

`surveillance.q` loads the three scenario files and wires each main function onto
a timer. Each scenario file is self-contained: config defaults, helper functions,
and one main detection function.

### Namespace

All surveillance code lives under `.surv.*`:
- `.surv.cfg.*`       — configuration (thresholds, windows, intervals)
- `.surv.vol.*`       — volume spike logic
- `.surv.pxdev.*`     — price deviation logic
- `.surv.qs.*`        — quote stuffing logic
- `.surv.alert`       — alert publishing utility
- `.surv.rdbh`        — handle to RDB (resolved via discovery)

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
  description:()               / human-readable explanation (string list)
  )
```

This gives an investigator everything they need: what happened, which instrument,
what triggered it, and how far it was from normal.

---

## 3. Detection Scenarios

### 3.1 Volume Spike

**Concept:** A single trade whose size is abnormally large compared to the recent
average trade size for that symbol.

**Detection function:** `.surv.vol.detect[]`

**Logic:**
1. Query RDB for trades in the last N minutes (configurable lookback window)
2. Per symbol, compute the mean and standard deviation of `size`
3. Flag any trade where `size > mean + (multiplier * stddev)`
4. Publish one alert row per flagged trade

**Configuration (`.surv.cfg`):**

| param | default | description |
|-------|---------|-------------|
| `vol.lookback` | `0D00:05` | Rolling window to compute baseline |
| `vol.multiplier` | `3.0` | Number of standard deviations above mean |
| `vol.interval` | `0D00:00:10` | Timer frequency |

---

### 3.2 Price Deviation (Trade vs Prevailing Quote)

**Concept:** A trade executes at a price that differs abnormally from the prevailing
best bid/ask for that symbol at trade time. This could indicate a bad fill, a fat
finger, or stale pricing.

**Detection function:** `.surv.pxdev.detect[]`

**Logic:**
1. Query RDB for trades in the last N minutes
2. Query RDB for the latest quote per symbol as-of each trade time (use `aj` —
   asof join — to pair each trade with the prevailing quote)
3. Compute midprice from the paired quote: `mid = (bid + ask) % 2`
4. Compute deviation: `abs[trade.price - mid] % mid`
5. Flag trades where deviation exceeds threshold percentage
6. Assign severity: `low` if > threshold, `medium` if > 2x threshold,
   `high` if > 3x threshold
7. Publish one alert row per flagged trade

**Configuration:**

| param | default | description |
|-------|---------|-------------|
| `pxdev.lookback` | `0D00:05` | Window of recent trades to check |
| `pxdev.threshold` | `0.02` | 2% deviation from mid triggers alert |
| `pxdev.interval` | `0D00:00:10` | Timer frequency |

---

### 3.3 Quote Stuffing

**Concept:** A burst of rapid quote updates for a single symbol within a short
window, where the price barely moves between updates. In real markets this can
indicate an attempt to slow down competitors' processing or manipulate the book.

**Detection function:** `.surv.qs.detect[]`

**Logic:**
1. Query RDB for quotes in the last N seconds (short window — stuffing is fast)
2. Group by symbol
3. Per symbol, count quotes in the window
4. Also compute the price range in the window: `(max ask - min bid)`
5. Flag if quote count exceeds threshold AND price range is below the
   minimum movement threshold (high activity + flat price = suspicious)
6. Severity based on how far count exceeds threshold:
   `low` if > 1x, `medium` if > 2x, `high` if > 3x
7. Publish one alert per flagged symbol (not per quote — the burst is the event)
8. The `refid` in the alert references the `quoteid` of the last quote in the burst

**Configuration:**

| param | default | description |
|-------|---------|-------------|
| `qs.lookback` | `0D00:00:05` | Short rolling window (5 seconds) |
| `qs.countthreshold` | `50` | Quotes per symbol in window to trigger |
| `qs.minpricemove` | `0.5` | Min price range (absolute) — below this is "flat" |
| `qs.interval` | `0D00:00:05` | Timer frequency |

---

## 4. Configuration File

`appconfig/settings/surveillance.q`

```q
// Surveillance process settings

\d .surv

// RDB connection
cfg.rdbtypes:`rdb

// Volume spike
cfg.vol.lookback:0D00:05        // 5 min rolling baseline
cfg.vol.multiplier:3.0          // stddev multiplier
cfg.vol.interval:0D00:00:10     // check every 10 seconds

// Price deviation (trade vs prevailing quote)
cfg.pxdev.lookback:0D00:05      // 5 min window of trades to check
cfg.pxdev.threshold:0.02        // 2% deviation from midprice
cfg.pxdev.interval:0D00:00:10   // check every 10 seconds

// Quote stuffing
cfg.qs.lookback:0D00:00:05      // 5 second window
cfg.qs.countthreshold:50        // quotes per sym to flag
cfg.qs.minpricemove:0.5         // price must move less than this to qualify
cfg.qs.interval:0D00:00:05      // check every 5 seconds
```

All values are overridable via the standard TorQ config guard pattern:
```q
cfg.vol.multiplier:@[value;`.surv.cfg.vol.multiplier;3.0]
```

---

## 5. Feed Modifications

### 5.1 New Columns

Add to `trade` in `database.q`:
- `tradeid` (`long`) — monotonically increasing ID per trade

Add to `quote` in `database.q`:
- `quoteid` (`long`) — monotonically increasing ID per quote

The feed maintains running counters (`.feed.tradeid` and `.feed.quoteid`) and
assigns IDs as rows are generated. These IDs appear in alert rows as `refid` so
investigators can trace back to the exact event.

### 5.2 Anomaly Injection

Modify the feed to periodically inject scenarios that will reliably trigger each
detection type. Use independent timers so scenarios overlap naturally.

**Volume spike injection:**
- On a separate timer (e.g. every 30–60 seconds)
- Pick a random symbol
- Publish a single trade with `size` set to 10x the normal range for that symbol
- This guarantees it exceeds 3 stddevs of the rolling average

**Price deviation injection:**
- On a separate timer (e.g. every 30–60 seconds)
- Pick a random symbol
- Publish a trade whose price is offset 5–10% from the current base price for
  that symbol (well above the 2% detection threshold)
- Normal bid/ask margins are small (0–1.0 on prices of 12–84), so a 5% offset
  will clearly deviate from mid

**Quote stuffing injection:**
- On a separate timer (e.g. every 20–40 seconds)
- Pick a random symbol
- Publish a burst of 80+ quotes for that single symbol with near-identical
  bid/ask (price movement < 0.1), delivered in a single `.u.upd` call
- Count of 80 exceeds the 50-quote threshold, flat price meets the criteria

### 5.3 Feed Code Organisation

Keep the anomaly injection logic separate from the normal feed path:
```
code/tick/
├── feed.q              Existing feed (modified to include tradeid/quoteid)
└── feed_anomalies.q    Anomaly injection functions, loaded by feed.q
```

---

## 6. Other Changes

### process.csv
Add one row for `surveillance1`.

### accesslist.txt
Add `surveillance:pass`.

### sort.csv (if present)
Add `alert` table with sort columns `sym`, `time`.

---

## 7. Summary of Files Changed / Created

**New files:**
- `code/processes/surveillance.q`
- `code/processes/surveillance/volumespike.q`
- `code/processes/surveillance/pricedeviation.q`
- `code/processes/surveillance/quotestuffing.q`
- `code/tick/feed_anomalies.q`
- `appconfig/settings/surveillance.q`

**Modified files:**
- `database.q` — add `alert` table, add `tradeid` to `trade`, add `quoteid` to `quote`
- `code/tick/feed.q` — add ID counters, load `feed_anomalies.q`, wire anomaly timers
- `appconfig/process.csv` — add `surveillance1` row
- `appconfig/passwords/accesslist.txt` — add `surveillance:pass`