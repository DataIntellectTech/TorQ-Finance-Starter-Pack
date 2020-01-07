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
set KDBTPLOG=%TORQHOME%/tplogs

REM App specific configuration directory
set KDBAPPCONFIG=%TORQHOME%\appconfig

set KDBBASEPORT=6000

set PATH=%PATH%;%KDBLIB%\w32

REM to kill it, run this:
start "kill" q torq.q -load code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS rdb wdb tickerplant chainedtp hdb gateway housekeeping monitor discovery sort sortslave reporter compression iexfeed feed metrics
