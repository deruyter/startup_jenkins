#!/usr/bin/env bash
#
# usage: pause-and-start-aci.sh
#
# Pauses previous jobs and start aci
# WARNING: do not use directly unless you know what you are doing
#          Use safe_start.sh script instead
#
# parameters:
# ACI_ROOT_DIR: root dir of jenkins project 
#
set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir;pwd`

DEF_ACI_ROOT_DIR=`readlink -f $dir/..`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR

## Step 1 - Collect already paused job & set all other jobs in paused mode
if [ -d ${ACI_ROOT_DIR}/aci_home/jobs ] ; then
  [ -f ${ACI_ROOT_DIR}/paused_jobs.txt ] && mv ${ACI_ROOT_DIR}/paused_jobs.txt ${ACI_ROOT_DIR}/paused_jobs.txt.bak
  touch ${ACI_ROOT_DIR}/paused_jobs.txt
  cd ${ACI_ROOT_DIR}/aci_home/jobs/
  for job in `find * -maxdepth 0 -type d` ; do
    if [ -f ${ACI_ROOT_DIR}/aci_home/jobs/${job}/config.xml ]; then
      if [ `grep "<disabled>true</disabled>" ${ACI_ROOT_DIR}/aci_home/jobs/${job}/config.xml | wc -l` -gt 0 ] ; then
	echo $job >> ${ACI_ROOT_DIR}/paused_jobs.txt
      else
	sed -i -e 's#<disabled>false</disabled>#<disabled>true</disabled>#g' ${ACI_ROOT_DIR}/aci_home/jobs/${job}/config.xml
      fi
    else
      echo "warning: job $job does not have a config.xml file: file not found: ${ACI_ROOT_DIR}/aci_home/jobs/${job}/config.xml" >&2
    fi
  done
fi

## Step 2 - Start server & wait node to be online
cd ${ACI_ROOT_DIR}
exec $dir/start-aci.sh $@
