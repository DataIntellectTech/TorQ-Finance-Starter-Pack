. ../setenv.sh

iiexport KDBHDB=${PWD}/../hdb/database
export KDBWDB=${PWD}/../wdbhdb
export KDBTOP=${PWD}/..
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32
export KDBSYM=${PWD}/../hdb/symrecs

q ${TORQHOME}/torq.q -load ${KDBAPPCODE}/eodsummary/runEodSummary.q ${KDBSTACKID} -proctype metrics -procname eodsummary1 ${KDBAPPCONFIG}/passwords/accesslist.txt

