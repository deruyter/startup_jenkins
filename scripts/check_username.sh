#!/bin/sh
#Check that all username in config.xml are well defined in mapuser.txt
mydir=`dirname $0`
mydir=`cd $mydir; pwd`

for i in `grep username $mydir/../config.xml | awk ' { print $7 }' `; 
do eval $i;  
    grep -w $username $mydir/mapuser.txt >/dev/null; 
    if [ $? != 0 ]; then 
	echo $username not found; 
    fi; 
done
