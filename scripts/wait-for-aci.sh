#!/usr/bin/env bash
#
# usage: wait-for-aci.sh
#
# Waits until jenkins is started an ready to accept command line conection
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

secs=5
max=180
echo "Waiting for jenkins availability, may take up to $((secs*max/60)) mins..."
version=
while [ $max -gt 0 -a "$version" = "" ]; do
    version=`STRICT=no $ACI_ROOT_DIR/jenkins-cli.sh version 2>/dev/null || true`
    [ "$version" != "" ] || sleep $secs
    max=$((max-1))
done
if [ "$version" != "" ]; then
    echo "Jenkins version $version was succesfully started"
else
    echo "Jenkins does not seem to be started, aborting" >&2
    exit 1
fi


