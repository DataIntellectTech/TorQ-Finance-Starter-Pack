#!/bin/sh

OLD="localhost"
NEW=`hostname`
DPATH=`find . -type f -name '*.csv'`
TFILE="/tmp/out.tmp.$$"
for f in $DPATH
do
  if [ -f $f -a -r $f ]; then
        sed "s/$OLD/$NEW/g" "$f" > $TFILE && mv $TFILE "$f"
    else
        echo "Error: Cannot read $f"
    fi
done
if [ -e $TFILE ]
then
    rm $TFILE
fi
