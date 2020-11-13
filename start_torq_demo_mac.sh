# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ Finance Starter Pack installation
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m32 

##### EMAILS #####
# this is where the emails will be sent to 
export DEMOEMAILRECEIVER=test@youremail.com

# also set the email server configuration in config/settings/default.q
##### END EMAILS #####

# launch the discovery service
echo 'Starting discovery proc...'
q torq.q -load code/processes/discovery.q ${KDBSTACKID} -proctype discovery -procname discovery1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqdiscovery.txt 2>&1 &

# launch the tickerplant, rdb, ctp, hdb
echo 'Starting tp...'
q torq.q -load code/processes/tickerplant.q -schemafile database -tplogdir ${KDBTPLOG} ${KDBSTACKID} -proctype tickerplant -procname tickerplant1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqtp.txt 2>&1 &

echo 'Starting rdb...'
q torq.q -load code/processes/rdb.q ${KDBSTACKID} -proctype rdb -procname rdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 180 </dev/null >$KDBLOG/torqrdb.txt 2>&1 &

echo 'Starting ctp...'
q torq.q -load code/processes/chainedtp.q ${KDBSTACKID} -proctype chainedtp -procname chainedtp1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqchainedtp.txt 2>&1 &

echo 'Starting hdb1...'
q torq.q -load ${KDBHDB} ${KDBSTACKID} -proctype hdb -procname hdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb1.txt 2>&1 &
echo 'Starting hdb2...'
q torq.q -load ${KDBHDB} ${KDBSTACKID} -proctype hdb -procname hdb2 -U appconfig/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb2.txt 2>&1 &

# launch the gateway
echo 'Starting gw...'
q torq.q -load code/processes/gateway.q ${KDBSTACKID} -proctype gateway -procname gateway1 -U appconfig/passwords/accesslist.txt -.servers.CONNECTIONS hdb rdb -localtime -g 1 -w 4000 </dev/null >$KDBLOG/torqgw.txt 2>&1 &

# launch the monitor
echo 'Starting monitor...'
q torq.q -load code/processes/monitor.q ${KDBSTACKID} -proctype monitor -procname monitor1 -localtime </dev/null >$KDBLOG/torqmonitor.txt 2>&1 &

# launch the reporter
echo 'Starting reporter...'
q torq.q -load code/processes/reporter.q ${KDBSTACKID} -proctype reporter -procname reporter1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqreporter.txt 2>&1 &

# launch housekeeping
echo 'Starting housekeeping proc...'
q torq.q -load code/processes/housekeeping.q ${KDBSTACKID} -proctype housekeeping -procname housekeeping1 -U appconfig/passwords/accesslist.txt -localtime </dev/null >$KDBLOG/torqhousekeeping.txt 2>&1 &

# launch sort processes
echo 'Starting sorting proc...'
q torq.q -load code/processes/wdb.q ${KDBSTACKID} -proctype sort -procname sort1 -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqsort.txt 2>&1 & # sort process

# launch wdb
echo 'Starting wdb...'
q torq.q -load code/processes/wdb.q ${KDBSTACKID} -proctype wdb -procname wdb1 -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqwdb.txt 2>&1 &  # pdb process

# launch compress
echo 'Starting compression proc...'
q torq.q -load code/processes/compression.q ${KDBSTACKID} -proctype compression -procname compression1 -localtime </dev/null >$KDBLOG/torqcompress1.txt 2>&1 &  # compression process

# launch feed
echo 'Starting feed...'
q torq.q -load code/tick/feed.q ${KDBSTACKID} -proctype feed -procname feed1 -localtime </dev/null >$KDBLOG/torqfeed.txt 2>&1 &

# launch iexfeed
echo 'Starting iexfeed...'
q torq.q -load code/processes/iexfeed.q ${KDBSTACKID} -proctype iexfeed -procname iexfeed1 -localtime </dev/null >$KDBLOG/torqfeed.txt 2>&1 &

# launch metrics
q torq.q -load code/processes/metrics.q ${KDBSTACKID} -proctype metrics -procname metrics1 -U appconfig/passwords/accesslist.txt -localtime -g 1 </dev/null >$KDBLOG/torqcompress1.txt 2>&1 &  # compression process
