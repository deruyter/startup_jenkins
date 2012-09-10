#!/bin/sh
#
# usage: start-aci.sh
#
# Must be run from the Master node unser account stsaci.
# WARNING: do not use directly unless you know what you are doing
#          Use the safe_start.sh script instead.
#

set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir;pwd`
host=`hostname`

DEF_ACI_ROOT_DIR=`readlink -f $dir/..`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR

. ${ACI_ROOT_DIR}/aci_config.sh

HUDSON_HOME=${ACI_ROOT_DIR}/aci_home
JENKINS_HOME=${ACI_ROOT_DIR}/aci_home


JAVA_HEAP_DEBUG_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${ACI_ROOT_DIR}"
JAVA_JDB_DEBUG_OPTIONS="-Xdebug -Xrunjdwp:transport=dt_socket,address=8003,server=y,suspend=n"

# uncomment this to activate heap dumps and debug (jdb -attach 8000) support
#JAVA_OPTIONS="-Xmx8192m $JAVA_HEAP_DEBUG_OPTIONS $JAVA_JDB_DEBUG_OPTIONS"
# uncomment this for normal (non debug) runnin mode
JAVA_OPTIONS="-Xmx8192m"

WAR="${ACI_ROOT_DIR}/${ACI_TOOL_NAME}.war"

export HUDSON_HOME
export JENKINS_HOME

cd ${ACI_ROOT_DIR}
echo "Launching aci java war file"
echo "exec ${JAVA} ${JAVA_OPTIONS} -jar ${WAR} --httpPort=${ACI_PORT} $@"
exec ${JAVA} ${JAVA_OPTIONS} -jar ${WAR} --httpPort=${ACI_PORT}  $@

