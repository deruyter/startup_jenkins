#!/usr/bin/env bash
#
# usage: safe_activate.sh
#
# Re-activate all jobs after a safe_start.sh
#
# parameters:
# ACI_ROOT_DIR: root dir of jenkins project (default to root dir of the script)
#

set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir;pwd`
cur_dir=`pwd`

DEF_ACI_ROOT_DIR=`readlink -f $dir`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR

error () {
  echo $1
  [ $2 = -1 ] && exit
  exit $2
}

## Step 3 - Restart paused jobs
if [ "x$1" != "x" ] ; then
  echo "Restarting jobs matching $1"
  cd ${ACI_ROOT_DIR}/aci_home/jobs/
  for dir in `find * -maxdepth 0 -type d | grep $1` ; do
    if [ `grep $dir ${ACI_ROOT_DIR}/paused_jobs.txt | wc -l` -eq 0 ] ; then
      echo "Activating job $dir"
      ${ACI_ROOT_DIR}/jenkins-cli.sh enable-job $dir
    fi
  done
  cd ${cur_dir}
else
  cd ${ACI_ROOT_DIR}/aci_home/jobs/
  for dir in `find * -maxdepth 0 -type d` ; do
    if [ `grep "^$dir\$" ${ACI_ROOT_DIR}/paused_jobs.txt | wc -l` -eq 0 ] ; then
      echo "Activating job $dir"
      failed=false
      ${ACI_ROOT_DIR}/jenkins-cli.sh enable-job $dir || failed=true
      if $failed; then
	  echo "WARNING: The job $dir could not be activated, this probably means that the job does not exist anymore in Jenkins." >&2
	  echo "WARNING: Check whether the ${ACI_ROOT_DIR}/aci_home/jobs/$dir exists and is obsolete. Optionally remove this directory" >&2
      fi
    fi
  done
  cd ${cur_dir}
fi
