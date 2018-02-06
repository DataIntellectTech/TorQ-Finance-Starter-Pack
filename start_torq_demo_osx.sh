# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ Finance Starter Pack installation
export KDBHDB=${TORQHOME}/hdb/database
export KDBWDB=${TORQHOME}/wdbhdb
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m32

##### EMAILS #####
# this is where the emails will be sent to
export DEMOEMAILRECEIVER=test@youremail.com

# also set the email server configuration in config/settings/default.q
##### END EMAILS #####

# launch the discovery service
echo 'Starting discovery proc...'
q torq.q ${KDBSTACKID} -proctype discovery -procname discovery1 -load code/processes/discovery.q -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqdiscovery.txt 2>&1 &

# launch the tickerplant, rdb, ctp, hdb
echo 'Starting tp...'
q torq.q ${KDBSTACKID} -proctype tickerplant -procname tickerplant1 -load code/processes/tickerplant.q -schemafile database -tplogdir ${TORQHOME}/hdb -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqtp.txt 2>&1 &

echo 'Starting rdb...'
q torq.q ${KDBSTACKID} -proctype rdb -procname rdb1 -load code/processes/rdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 30 </dev/null >$KDBLOG/torqrdb.txt 2>&1 &

echo 'Starting ctp...'
q torq.q ${KDBSTACKID} -proctype chainedtp -procname chainedtp1 -load code/processes/chainedtp.q -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqchainedtp.txt 2>&1 &

echo 'Starting hdb1...'
q torq.q ${KDBSTACKID} -proctype hdb -procname hdb1 -load ${KDBHDB} -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb1.txt 2>&1 &
echo 'Starting hdb2...'
q torq.q ${KDBSTACKID} -proctype hdb -procname hdb2 -load ${KDBHDB} -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb2.txt 2>&1 &

# launch the gateway
echo 'Starting gw...'
q torq.q ${KDBSTACKID} -proctype gateway -procname gateway1 -load code/processes/gateway.q -U appconfig/passwords/accesslist.txt -.servers.CONNECTIONS hdb rdb -localtime -g 1 -w 4000 </dev/null >$KDBLOG/torqgw.txt 2>&1 &

# launch the monitor
echo 'Starting monitor...'
q torq.q ${KDBSTACKID} -proctype monitor -procname monitor1 -load code/processes/monitor.q -localtime </dev/null >$KDBLOG/torqmonitor.txt 2>&1 &

# launch the reporter
echo 'Starting reporter...'
q torq.q ${KDBSTACKID} -proctype reporter -procname reporter1 -load code/processes/reporter.q -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqreporter.txt 2>&1 &

# launch housekeeping
echo 'Starting housekeeping proc...'
q torq.q ${KDBSTACKID} -proctype housekeeping -procname housekeeping1 -load code/processes/housekeeping.q -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqhousekeeping.txt 2>&1 &

# launch sort processes
echo 'Starting sorting proc...'
q torq.q ${KDBSTACKID} -proctype sort -procname sort1 -load code/processes/wdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqsort.txt 2>&1 &

# launch wdb
echo 'Starting wdb...'
q torq.q ${KDBSTACKID} -proctype wdb -procname wdb1 -load code/processes/wdb.q -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqwdb.txt 2>&1 &

# launch compression process
echo 'Starting compression proc...'
q torq.q ${KDBSTACKID} -proctype compression -procname compression1 -load code/processes/compression.q -localtime </dev/null >$KDBLOG/torqcompress1.txt 2>&1 &

# launch feed
echo 'Starting feed...'
q torq.q ${KDBSTACKID} -proctype feed -procname feed1 -load code/tick/feed.q -localtime </dev/null >$KDBLOG/torqfeed.txt 2>&1 &

# launch metrics
q torq.q ${KDBSTACKID} -proctype metrics -procname metrics1 -load code/processes/metrics.q -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqcompress1.txt 2>&1 &
