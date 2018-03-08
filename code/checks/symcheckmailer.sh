#!/bin/bash
#crontab usage
#*/5 * * * 1-5 . /home/jburrows/proddev/TorQ-Finance-Starter-Pack/code/checks/symcheckmailer.sh

#cd into directory to load files and log dest
cd "/home/jburrows/proddev/TorQ-Finance-Starter-Pack/code/checks/"

#set email var
EMAIL="james.burrows@aquaq.co.uk"

#set rdb port and tm check
rdb="::13402:admin:admin"
tm1="00:05:00.000"

#create empty logfile to mail, -Es sends mail if file has content
touch logs/missingsyms.log

#set q vars and rlwrap executable to launch, with cmdline args
QLIC=/opt/kdb/QLIC QHOME=/opt/kdb/3.5/2017.11.30 rlwrap -r /opt/kdb/3.5/2017.11.30/l64/q symcheck.q -rdb $rdb -init 1 -noexit 1 -tm1 $tm1 | mail -Es "Missing Syms Detected!" $EMAIL < /home/jburrows/prodsupport2/TorQ-Finance-Starter-Pack/code/checks/logs/missingsyms.log

#If file is there, remove it once mail sent
if [ `ls /home/jburrows/proddev/TorQ-Finance-Starter-Pack/code/checks/logs/ | wc -l` -gt 0 ]; then
  rm logs/missingsyms.log
fi
