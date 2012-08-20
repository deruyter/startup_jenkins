#!/bin/sh
#
# Usage: log.sh <logfile> cmd arguments...
#
# Lauch the command and logs into logfile
# This command will not propagate the return value of <cmd>.
# Though if the resturn valie of <cmd> if non zero it will output a message 
# containing "validfailed".
#
logfile=$1
shift
logdir=`dirname $logfile`
if [ ! -d $logdir ];then
  mkdir -p $logdir
fi

(${1+$@} 2>&1 || echo "VALID FAILED: validfailed: $1 returned non zero status") | tee ${logfile}  

