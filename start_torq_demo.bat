REM see README.txt
REM SET UP ENVIRONMENT VARIABLES 

set KDBCODE=%cd%\code
set KDBCONFIG=%cd%\config
set KDBLOG=%cd%\logs
set KDBHTML=%cd%\html
set KDBLIB=%cd%\lib

REM Additional demo specific environment variables
set DEMOHDB=%cd%/hdb 
set PATH=%PATH%;%KDBLIB%\w32

REM the address emails will be sent to
REM DEMOEMAILRECEIVER=test@youremail.com

REM launch the discovery service
start "discovery" q torq.q -load code/processes/discovery.q -p 31000 -U config/passwords/accesslist.txt -o 0 -localtime 

REM launch the tickerplant, rdb, hdb
start "tickerplant" q tickerplant.q database hdb -p 31100 -U config/passwords/accesslist.txt -localtime 
start "rdb" q torq.q -load code/processes/rdb.q -p 31200 -U config/passwords/accesslist.txt -localtime -g 1 -T 30
start "hdb1" q torq.q -load hdb/database -p 31300 -U config/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000
start "hdb2" q torq.q -load hdb/database -p 31301 -U config/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000

REM launch the gateway
start "gateway" q torq.q -load code/processes/gateway.q -p 30000 -.servers.CONNECTIONS hdb rdb -U config/passwords/accesslist.txt -localtime -g 1 -w 4000 

REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -p 30200 -localtime 

REM launch the reporter
start "reporter" q torq.q -load code/processes/reporter.q -p 30500 -U config/passwords/accesslist.txt -localtime 

REM launch housekeeping
start "housekeeping" q torq.q -load code/processes/housekeeping.q -p 30400 -U config/passwords/accesslist.txt -localtime 

REM launch the wdb and sort processes 
start "sort" q torq.q -load code/processes/wdb.q -p 31450 -U config/passwords/accesslist.txt -localtime -g 1

start "wdb" q torq.q -load code/processes/wdb.q -p 31400 -U config/passwords/accesslist.txt -localtime -g 1

REM launch compression
start "compression" q torq.q -load code/processes/compression.q -p 30600 -localtime -g 1

REM launch feed
start "feed" q torq.q -load tick/feed.q -p 30700 -U config/passwords/accesslist.txt -localtime 

REM to kill it, run this:
REM q torq.q -load code/processes/kill.q -p 30100 -.servers.CONNECTIONS rdb wdb tickerplant hdb gateway housekeeping monitor discovery sort reporter compression feed -localtime 
