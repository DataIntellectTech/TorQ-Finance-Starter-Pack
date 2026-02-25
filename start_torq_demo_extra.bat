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

REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -proctype monitor -procname monitor1 -localtime

REM launch the reporter
start "reporter" q torq.q -load code/processes/reporter.q -proctype reporter -procname reporter1 -U appconfig/passwords/accesslist.txt -localtime
