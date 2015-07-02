# load env script
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBBASEPORT=6000

#kill all torq procs
echo 'Shutting down TorQ...'
q torq.q -load code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS feed rdb tickerplant chainedtp hdb gateway housekeeping monitor discovery wdb sort reporter compression </dev/null >$KDBLOG/torqkill.txt 2>&1 &
