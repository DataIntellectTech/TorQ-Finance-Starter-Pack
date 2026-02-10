REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -proctype monitor -procname monitor1 -localtime

REM launch the reporter
start "reporter" q torq.q -load code/processes/reporter.q -proctype reporter -procname reporter1 -U appconfig/passwords/accesslist.txt -localtime
