# Load the environment
. ./setenv.sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

##### EMAILS #####
# this is where the emails will be sent to 
# export DEMOEMAILRECEIVER=user@torq.co.uk

# also set the email server configuration in config/settings/default.q
##### END EMAILS #####

# launch the discovery service
echo 'Starting discovery proc...'
q torq.q -load code/processes/discovery.q -localtime -p 31000 -U config/passwords/accesslist.txt 1 </dev/null >$KDBLOG/torqdiscovery.txt 2>&1 &

# launch the tickerplant, rdb, hdb
echo 'Starting tp...'
q tickerplant.q database hdb -localtime -p 31100 -U config/passwords/accesslist.txt 1 </dev/null >$KDBLOG/torqtp.txt 2>&1 &

echo 'Starting rdb...'
q torq.q -load code/processes/rdb.q -localtime -p 31200 -U config/passwords/accesslist.txt 1 -g 1 -T 30 </dev/null >$KDBLOG/torqrdb.txt 2>&1 &

echo 'Starting hdb1...'
q torq.q -load hdb/database -localtime -p 31300 -U config/passwords/accesslist.txt 1 -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb1.txt 2>&1 &
echo 'Starting hdb2...'
q torq.q -load hdb/database -localtime -p 31301 -U config/passwords/accesslist.txt 1 -g 1 -T 60 -w 4000 </dev/null >$KDBLOG/torqhdb2.txt 2>&1 &

# launch the gateway
echo 'Starting gw...'
q torq.q -load code/processes/gateway.q -localtime -p 30000 -U config/passwords/accesslist.txt 1 -g 1 -w 4000 </dev/null >$KDBLOG/torqgw.txt 2>&1 &

# launch the monitor
echo 'Starting monitor...'
q torq.q -load code/processes/monitor.q -localtime -p 30200 1 </dev/null >$KDBLOG/torqmonitor.txt 2>&1 &

# launch the reporter
echo 'Starting reporter...'
q torq.q -load code/processes/reporter.q -localtime -p 30500 -U config/passwords/accesslist.txt 1 </dev/null >$KDBLOG/torqreporter.txt 2>&1 &

# launch housekeeping
echo 'Starting housekeeping proc...'
q torq.q -load code/processes/housekeeping.q -localtime -p 30400 -U config/passwords/accesslist.txt 1 </dev/null >$KDBLOG/torqhousekeeping.txt 2>&1 &

# launch sort processes
echo 'Starting sorting proc...'
q torq.q -load code/processes/wdb.q -localtime -p 31450 -U config/passwords/accesslist.txt 1 -g 1 </dev/null >$KDBLOG/torqsort.txt 2>&1 & # sort process

# launch wdb
echo 'Starting wdb...'
q torq.q -load code/processes/wdb.q -localtime -p 31400 -U config/passwords/accesslist.txt 1 -g 1 </dev/null >$KDBLOG/torqwdb.txt 2>&1 &  # pdb process

# launch compress
echo 'Starting compression proc...'
q torq.q -load code/processes/compression.q -localtime -p 30600 1 </dev/null >$KDBLOG/torqcompress1.txt 2>&1 &  # compression process

# launch feed
echo 'Starting feed...'
q torq.q -load tick/feed.q -localtime -p 30700 1 </dev/null >$KDBLOG/torqfeed.txt 2>&1 &
