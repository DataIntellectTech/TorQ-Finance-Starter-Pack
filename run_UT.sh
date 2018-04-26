# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBHDB=${PWD}/../hdb/database
export KDBWDB=${PWD}/../wdbhdb
export KDBTOP=${PWD}/..
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

echo "Select an option!" 
echo""
printf "%-15s | %-50s\n" "gateway" "test checkQuery function inside gateway.q"
printf "%-15s | %-50s\n" "symbackup" "test symbackup functionality"
printf "%-15s | %-50s\n" "dbmigration" "test data base migration"
printf "%-15s | %-50s\n" "vizsum" "test the vizualisation script"
printf "%-15s | %-50s\n" "Exit" "-"
echo""
printf "Input:"
read -r inp

inp=` echo $inp | tr '[:upper:]' '[:lower:]'` 
case $inp in 
  gateway)
    rlwrap q TorQ/torq.q -procname gateway2 -proctype gateway -load ${TORQHOME}/code/processes/gateway.q -test ${KDBTORQFSP}/unitTesting/testCSV/checkQGW.csv -debug;;
  dbmigration)
     echo "NOT YET IMPLEMENTED";;
  symbackup)
    rlwrap q TorQ/torq.q -procname gateway2 -proctype gateway -load ${TORQHOME}/code/processes/gateway.q -test ${KDBTORQFSP}/unitTesting/testCSV -debug;;
  vizsum)   
    rlwrap q TorQ/torq.q -procname vizSum1 -proctype summary -load ${KDBTORQFSP}/code/vizSum/vizSum.q -test ${KDBTORQFSP}/unitTesting/testCSV/vizSum.csv -debug;;
  exit) 
    exit 1;; 
  *)
    echo "NOT YET IMPLEMENTED";;
esac 




