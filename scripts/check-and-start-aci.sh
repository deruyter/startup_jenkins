#!/usr/bin/env bash
#
#
# usage: check-and-start-aci.sh <start_script>
#
# Checks whether an aci is already running before starting the <start_script>.
# Must be run from the Master node unser account stsaci.
# Parameters passed as envvars:
# FORCE=1: force start even if some processes are running a jenkins war.
# CHECK=1: only check if already running and exit, ignores tht start_script argument.
# ACI_ROOT_DIR: root dir of jenkins project 
#

set -e
MY_ENV=
[ "$DEBUG" = "" ] || set -x
[ "$DEBUG" = "" ] || MY_ENV="DEBUG=1"
[ "$test" =  "" ] || MY_ENV="$MY_ENV test=1"
[ "$MY_ENV" =  "" ] || MY_ENV="env $MY_ENV"


dir=`dirname $0`
dir=`cd $dir;pwd`
host=`hostname`
user=$USER

 
###
#
# Please add here expected running host/user
#
EXPECTED_HOST=gnx5796
DOMAIN_NAME=gnb.st.com
EXPECTED_USER=acicecmg

DEF_ACI_ROOT_DIR=`readlink -f $dir/..`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR
ACI_TOOL_NAME=jenkins

LOG="${ACI_ROOT_DIR}/${ACI_TOOL_NAME}.log"
PIDFILE=$ACI_ROOT_DIR/aci_${host}.pid

###
# Returns a list of pids corresponding to the aci war file if exists.
pid_of_aci() {
    ps uxwww | grep java | grep ${ACI_TOOL_NAME}.war | grep -v grep | awk '{print $2}'
}

###
# Check whether the machine is the expected one
if [ "$host" != "$EXPECTED_HOST" -a "x$test" = "x" ]; then
  echo "$0: expected to be run on $EXPECTED_HOST or in test mode" >&2
  echo "log first on $EXPECTED_HOST before running" >&2
  exit 1
fi

###
# Check whether the user name is correct
if [ "$user" != "$EXPECTED_USER" -a "x$test" = "x" ]; then
  echo "$0: expected to be run as user $EXPEXCTED_USER or in test mode" >&2
  echo "log first as $EXPECTED_USER before running" >&2
  exit 1
fi

###
# Check whether the pid file is existing
if [ -f $PIDFILE ]; then
  echo "$0: error: aci already launched or is under maintenance" >&2
  echo "use safe_stop.sh or remove $PIDFILE if aci is no running" >&2
  echo "Pid file $PIDFILE contains:" >&2
  cat <$PIDFILE >&2
  exit 1
fi

###
# Check whether another instance is running
existing_pid=`pid_of_aci`
if [ "$FORCE" != 1 -a "$existing_pid" != "" ]; then
  echo "$0: error: another aci process is already running on this machine" >&2
  echo "This process pid is: $existing_pid" >&2
  echo "It is not expected that two server runs on the same machine" >&2
  echo "If so pass FORCE=1 in environment" >&2
  exit 1
fi

# Exit if check only (CHECK=1)
[ "$CHECK" != 1 ] || exit 0
 
cd ${ACI_ROOT_DIR}
echo "Cleaning logs"
$dir/clean.sh -log
echo "Launching aci in background"
exec $dir/spawn -s /bin/sh -n -p $PIDFILE "$MY_ENV $@ 2>&1 | $dir/log_split.sh ${LOG}"
#exec $dir/spawn -s /bin/sh -n -p $PIDFILE "$MY_ENV $@ 2>&1 > ${LOG}"
