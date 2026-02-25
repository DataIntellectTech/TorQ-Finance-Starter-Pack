. ./setenv.sh

# sets the base port for a default TorQ Finance Starter Pack installation
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m32 

# launch the monitor
echo 'Starting monitor...'
q torq.q -load code/processes/monitor.q ${KDBSTACKID} -proctype monitor -procname monitor1 -localtime </dev/null >$KDBLOG/torqmonitor.txt 2>&1 &

# launch the reporter
echo 'Starting reporter...'
q torq.q -load code/processes/reporter.q ${KDBSTACKID} -proctype reporter -procname reporter1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqreporter.txt 2>&1 &
