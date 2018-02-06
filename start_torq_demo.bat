REM see README.txt
REM SET UP ENVIRONMENT VARIABLES

set TORQHOME=%cd%
set KDBCODE=%TORQHOME%\code
set KDBCONFIG=%TORQHOME%\config
set KDBLOG=%TORQHOME%\logs
set KDBHTML=%TORQHOME%\html
set KDBLIB=%TORQHOME%\lib
set KDBBASEPORT=6000
set KDBHDB=%TORQHOME%/hdb/database
set KDBWDB=%TORQHOME%/wdbhdb

REM App specific configuration directory
set KDBAPPCONFIG=%TORQHOME%/appconfig

REM Additional demo specific environment variables
set PATH=%PATH%;%KDBLIB%\w32

REM the address emails will be sent to
REM DEMOEMAILRECEIVER=test@youremail.com

REM launch the discovery service
start "discovery" q torq.q -proctype discovery -procname discovery1 -load code/processes/discovery.q -U appconfig/passwords/accesslist.txt -o 0 -localtime

timeout 2

REM launch the tickerplant, rdb, hdb
start "tickerplant" q torq.q -proctype tickerplant -procname tickerplant1 -load code/processes/tickerplant.q -schemafile database -tplogdir %TORQHOME%/hdb -U appconfig/passwords/accesslist.txt -localtime
start "rdb" q torq.q -proctype rdb -procname rdb1 -load code/processes/rdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1
start "chainedtp" q torq.q -proctype chainedtp -procname chainedtp1 -load code/processes/chainedtp.q -U appconfig/passwords/accesslist.txt -localtime
start "hdb1" q torq.q -proctype hdb -procname hdb1 -load %KDBHDB% -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000
start "hdb2" q torq.q -proctype hdb -procname hdb2 -load %KDBHDB% -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000

REM launch the gateway
start "gateway" q torq.q -proctype gateway -procname gateway1 -load code/processes/gateway.q -.servers.CONNECTIONS hdb rdb -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000

REM launch the monitor
start "monitor" q torq.q -proctype monitor -procname monitor1 -load code/processes/monitor.q -localtime

REM launch the reporter
start "reporter" q torq.q -proctype reporter -procname reporter1 -load code/processes/reporter.q -U appconfig/passwords/accesslist.txt -localtime

REM launch housekeeping
start "housekeeping" q torq.q -proctype housekeeping -procname housekeeping1 -load code/processes/housekeeping.q -U appconfig/passwords/accesslist.txt -localtime

REM launch the wdb and sort processes
start "sort" q torq.q -proctype sort -procname sort1 -load code/processes/wdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1

start "wdb" q torq.q -proctype wdb -procname wdb1 -load code/processes/wdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1

REM launch compression process
start "compression" q torq.q -proctype compression -procname compression1 -load code/processes/compression.q -localtime -g 1

REM launch feed
start "feed" q torq.q -proctype feed -procname feed1 -load code/tick/feed.q -U appconfig/passwords/accesslist.txt -localtime

REM launch iexfeed
start "iexfeed" q torq.q -load code/processes/iexfeed.q -proctype iexfeed -procname iexfeed1 -U appconfig/passwords/accesslist.txt -localtime

REM launch sort slave process
start "sortslave1" q torq.q -proctype sortslave -procname slavesort1 -load code/processes/wdb.q -localtime -g 1
start "sortslave2" q torq.q -proctype sortslave -procname slavesort2 -load code/processes/wdb.q -localtime -g 1

REM launch metrics
start "metrics" q torq.q -proctype metrics -procname metrics1 -load code/processes/metrics.q -U appconfig/passwords/accesslist.txt -localtime -g 1

REM to kill it, run this:
REM q torq.q -proctype kill -procname killtick -load code/processes/kill.q -.servers.CONNECTIONS rdb wdb tickerplant hdb gateway housekeeping monitor discovery sort reporter compression feed -localtime
