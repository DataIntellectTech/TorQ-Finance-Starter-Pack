#This script is designed to be run on cron, such that the eodsummary process can be regularly run, example cronjob below:
#```*/1 * * * * QLIC=/opt/kdb/QLIC QHOME=/opt/kdb/3.5/2017.11.30 rlwrap -r /opt/kdb/3.5/2017.11.30/l64/q $HOME/devbranch/prodDev/TorQ-Finance-Starter-Pacl/eodsummary.sh```

. ../setenv.sh

iiexport KDBHDB=${PWD}/../hdb/database
export KDBWDB=${PWD}/../wdbhdb
export KDBTOP=${PWD}/..
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32
export KDBSYM=${PWD}/../hdb/symrecs

q ${TORQHOME}/torq.q -load ${KDBAPPCODE}/eodsummary/runEodSummary.q ${KDBSTACKID} -proctype metrics -procname eodsummary1 ${KDBAPPCONFIG}/passwords/accesslist.txt

