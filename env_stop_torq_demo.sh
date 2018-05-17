# load env script
. ./setenv.sh

#kill all torq procs
echo 'Shutting down TorQ...'
q ${TORQHOME}/torq.q -load ${TORQHOME}/code/processes/kill.q -proctype kill -procname killtick -.servers.CONNECTIONS tickerplant discovery rdb hdb wdb sort gateway monitor housekeeping reporter compression feed chainedtp sortslave metrics iexfeed checker wap summary dqe </dev/null >$KDBLOG/torqkill.txt 2>&1 &
