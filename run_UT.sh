# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBHDB=${PWD}/../hdb/database
export KDBWDB=${PWD}/../wdbhdb
export KDBTOP=${PWD}/..
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

# run unit tests
#q TorQ/torq.q -procname unittests1 -proctype unittests -load $KDBAPPCODE/iexfeed/iex.q -test TorQ-Finance-Starter-Pack/utests/testCSV -debug
rlwrap q TorQ/torq.q -procname gateway2 -proctype gateway -load ${TORQHOME}/code/processes/gateway.q -test ${KDBTORQFSP}/unitTesting/testCSV -debug
