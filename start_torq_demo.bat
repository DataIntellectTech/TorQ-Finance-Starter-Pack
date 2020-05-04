REM see README.txt
REM SET UP ENVIRONMENT VARIABLES 

set TORQHOME=%cd%
set KDBCODE=%TORQHOME%\code
set KDBCONFIG=%TORQHOME%\config
set KDBLOG=%TORQHOME%\logs
set KDBHTML=%TORQHOME%\html
set KDBLIB=%TORQHOME%\lib
set KDBBASEPORT=6000
set KDBHDB=%TORQHOME%/hdb
set KDBWDB=%TORQHOME%/wdbhdb
set KDBTPLOG=%TORQHOME%/tplogs

REM App specific configuration directory
set KDBAPPCONFIG=%TORQHOME%/appconfig

REM Additional demo specific environment variables
set PATH=%PATH%;%KDBLIB%\w32

REM the address emails will be sent to
REM DEMOEMAILRECEIVER=test@youremail.com

REM launch the discovery service
start "discovery" q torq.q -load code/processes/discovery.q -proctype discovery -procname discovery1 -U appconfig/passwords/accesslist.txt -o 0 -localtime 

timeout 2

REM launch the tickerplant, rdb, hdb
start "tickerplant" q torq.q -load code/processes/tickerplant.q -schemafile database -tplogdir %KDBTPLOG% -proctype tickerplant -procname tickerplant1 -U appconfig/passwords/accesslist.txt -localtime 
start "rdb" q torq.q -load code/processes/rdb.q -proctype rdb -procname rdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 180
start "chainedtp" q torq.q -load code/processes/chainedtp.q -proctype chainedtp -procname chainedtp1 -U appconfig/passwords/accesslist.txt -localtime
start "hdb1" q torq.q -load %KDBHDB% -proctype hdb -procname hdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000
start "hdb2" q torq.q -load %KDBHDB% -proctype hdb -procname hdb2 -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000

REM launch the gateway
start "gateway" q torq.q -load code/processes/gateway.q -proctype gateway -procname gateway1 -.servers.CONNECTIONS hdb rdb -U appconfig/passwords/accesslist.txt -localtime -g 1 -w 4000 

REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -proctype monitor -procname monitor1 -localtime 

REM launch the reporter
start "reporter" q torq.q -load code/processes/reporter.q -proctype reporter -procname reporter1 -U appconfig/passwords/accesslist.txt -localtime 

REM launch housekeeping
start "housekeeping" q torq.q -load code/processes/housekeeping.q -proctype housekeeping -procname housekeeping1 -U appconfig/passwords/accesslist.txt -localtime 

REM launch the wdb and sort processes 
start "sort" q torq.q -load code/processes/wdb.q -proctype sort -procname sort1 -U appconfig/passwords/accesslist.txt -localtime -g 1

start "wdb" q torq.q -load code/processes/wdb.q -proctype wdb -procname wdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1

REM launch compression
start "compression" q torq.q -load code/processes/compression.q -proctype compression -procname compression1 -localtime -g 1

REM launch feed
start "feed" q torq.q -load code/tick/feed.q -proctype feed -procname feed1 -U appconfig/passwords/accesslist.txt -localtime 

REM launch iexfeed
start "iexfeed" q torq.q -load code/processes/iexfeed.q -proctype iexfeed -procname iexfeed1 -U appconfig/passwords/accesslist.txt -localtime

REM launch sort slave process
start "sortslave1" q torq.q -load code/processes/wdb.q -proctype sortslave -procname slavesort1 -localtime -g 1 
start "sortslave2" q torq.q -load code/processes/wdb.q -proctype sortslave -procname slavesort2 -localtime -g 1

REM launch metrics
start "metrics" q torq.q -load code/processes/metrics.q -proctype metrics -procname metrics1 -U appconfig/passwords/accesslist.txt -localtime -g 1

REM to kill it, run this:
REM q torq.q -load code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS rdb wdb tickerplant hdb gateway housekeeping monitor discovery sort reporter compression feed -localtime 
