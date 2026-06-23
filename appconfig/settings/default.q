system"c 23 2000"
RETRY:0D00:00:10

// Disable usage/client logging for ALL procs. The RDB logs every feed insert
// otherwise → ~2 GB/day usage logs that feed the ops log-scraper firehose and
// bloat the ops tickerplant log (the gateway-replay hang). The RDB loads
// default.q (not tickerplant.q, where the original 0b lived but never reached
// the RDB), so the switch must be here to take effect on the RDB.
\d .usage
enabled:0b
logtodisk:0b
\d .
