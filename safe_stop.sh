#!/usr/bin/env bash
#
# usage: safe_stop.sh
#
# Stops the aci jenkins server, killing the spawned process launches by safe_start.sh
#
# parameters:
# ACI_ROOT_DIR: root dir of the jenkins server (default to current dir)
#

set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir;pwd`
host=`hostname`
user=$USER

ACI_ROOT_DIR=${ACI_ROOT_DIR:-$dir}
PIDFILE=$ACI_ROOT_DIR/aci_${host}.pid

if [ "$host" != "gnx5796" -a "$user" != "acicecmg" -a "$1" != "test" -a "x$test" = "x" ]; then
  echo "$0: error: must be launched from gnx5796 with username acicecmg" >&2
  exit 1
fi

if [ ! -f $PIDFILE ]; then
  echo "$0: error: ACI is apparently not launched" >&2
  echo "pid file $PIDFILE not present" >&2
  exit 1
fi

kill_safe() {
    local tokill=${1:?}
    local tries=10
    local pid=`ps $tokill | awk '($1 == '"$tokill"') { print $1;}'`
    if [ "$pid" = "$tokill" ] ; then
	echo "Killing $tokill, may take up to $tries secs..."
	kill -15 $tokill || true
	while [ "$pid" = $tokill -a $tries -gt 0 ]; do
	    sleep 1
	    pid=`ps $tokill | awk '($1 == '"$tokill"') { print $1;}'`
	    tries=$((tries-1))
	done
	if [ $tries = 0 ]; then
	    kill -9 $tokill || true
	fi
    fi
}

pid=`cat $PIDFILE`

# The java process may be a child of the spawned process, try to guess it
java_child=`ps -el | awk '($5 == '"$pid"' && $14 == "java") { print $4;}'`
[ "$java_child" = "" ] || kill_safe $java_child

# Anyway try to kill session leader
kill_safe $pid

rm $PIDFILE
