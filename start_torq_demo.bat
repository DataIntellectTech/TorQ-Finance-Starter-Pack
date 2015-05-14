REM see README.txt
REM SET UP ENVIRONMENT VARIABLES 

set KDBCODE=%cd%\code
set KDBCONFIG=%cd%\config
set KDBLOG=%cd%\logs
set KDBHTML=%cd%\html
set KDBLIB=%cd%\lib
set KDBBASEPORT=6000

REM Additional demo specific environment variables
set DEMOHDB=%cd%/hdb 
set PATH=%PATH%;%KDBLIB%\w32

REM the address emails will be sent to
REM DEMOEMAILRECEIVER=test@youremail.com

REM launch the discovery service
start "discovery" q torq.q -load code/processes/discovery.q -proctype discovery -procname discovery1 -U config/passwords/accesslist.txt -o 0 -localtime 

REM launch the tickerplant, rdb, hdb
start "tickerplant" q tickerplant.q database hdb -proctype tickerplant -procname tickerplant1 -U config/passwords/accesslist.txt -localtime 
start "rdb" q torq.q -load code/processes/rdb.q -proctype rdb -procname rdb1 -U config/passwords/accesslist.txt -localtime -g 1 -T 30
start "hdb1" q torq.q -load hdb/database -proctype hdb -procname hdb1 -U config/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000
start "hdb2" q torq.q -load hdb/database -proctype hdb -procname hdb2 -U config/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000

REM launch the gateway
start "gateway" q torq.q -load code/processes/gateway.q -proctype gateway -procname gateway1 -.servers.CONNECTIONS hdb rdb -U config/passwords/accesslist.txt -localtime -g 1 -w 4000 

REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -proctype monitor -procname monitor1 -localtime 

REM launch the reporter
start "reporter" q torq.q -load code/processes/reporter.q -proctype reporter -procname reporter1 -U config/passwords/accesslist.txt -localtime 

REM launch housekeeping
start "housekeeping" q torq.q -load code/processes/housekeeping.q -proctype housekeeping -procname housekeeping1 -U config/passwords/accesslist.txt -localtime 

REM launch the wdb and sort processes 
start "sort" q torq.q -load code/processes/wdb.q -proctype sort -procname sort1 -U config/passwords/accesslist.txt -localtime -g 1

start "wdb" q torq.q -load code/processes/wdb.q -proctype wdb -procname wdb1 -U config/passwords/accesslist.txt -localtime -g 1

REM launch compression
start "compression" q torq.q -load code/processes/compression.q -proctype compression -procname compression1 -localtime -g 1

REM launch feed
start "feed" q torq.q -load tick/feed.q -proctype feed -procname feed1 -U config/passwords/accesslist.txt -localtime 

REM to kill it, run this:
REM q torq.q -load code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS rdb wdb tickerplant hdb gateway housekeeping monitor discovery sort reporter compression feed -localtime 
