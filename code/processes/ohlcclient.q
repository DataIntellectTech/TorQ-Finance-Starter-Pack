\d .ohlc

gatewaytypes:@[value;`gatewaytypes;`gateway];        // gateway proctypes to connect to
gwconnsleep:@[value;`gwconnsleep;5];                 // seconds between gateway connection attempts
gwcheckcycles:@[value;`gwcheckcycles;0W];            // max attempts before giving up

bucket:@[value;`bucket;0D01];                        // hourly bucket size

requiredprocs:gatewaytypes;

/- locate a live gateway handle from .servers.SERVERS
gethandle:{
  h:first exec w from .servers.SERVERS where proctype in .ohlc.gatewaytypes,not null w,.dotz.liveh w;
  if[null h;'"getHourlyOHLC: no live gateway connection"];
  h}

/- minimal set of back-end server types needed to satisfy the date range
/-   today only      -> rdb
/-   historical only -> hdb
/-   spans both      -> rdb and hdb
servertypes:{[sd;ed]
  td:.z.d;
  needtoday:(sd<=td)&ed>=td;
  needhist:sd<td;
  $[needtoday and needhist;`rdb`hdb;
    needtoday;`rdb;
    needhist;`hdb;
    `rdb]}

\d .

/- Hourly OHLC per symbol for the inclusive date range [startdate;enddate].
/- The period may be today, historical, or span today + history.
getHourlyOHLC:{[startdate;enddate]
  if[(-14h<>type startdate)|-14h<>type enddate;'"getHourlyOHLC: startdate and enddate must be dates"];
  if[enddate<startdate;'"getHourlyOHLC: enddate must be >= startdate"];
  h:.ohlc.gethandle[];
  st:.ohlc.servertypes[startdate;enddate];
  /- hloc is defined on rdb and hdb (TorQ-Finance-Starter-Pack examplequeries);
  /- gateway razes results across the queried server types.
  res:h(`.gw.syncexec;(`hloc;startdate;enddate;.ohlc.bucket);st);
  `sym`time xasc select sym,time,open,high,low,close from 0!res}

/- TorQ infrastructure: register the gateway as a required connection
.servers.CONNECTIONS:distinct .servers.CONNECTIONS,.ohlc.gatewaytypes;
.servers.startup[];

/- block until at least one gateway is reachable
.servers.startupdepcycles[.ohlc.requiredprocs;.ohlc.gwconnsleep;.ohlc.gwcheckcycles];

.lg.o[`ohlcclient;"getHourlyOHLC ready - usage: getHourlyOHLC[startdate;enddate]"];
