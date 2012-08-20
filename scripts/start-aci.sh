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

###
#
# Please add here any path required by the hudson processes
#
PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`:$PATH
export PATH
LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
OS=`/sw/st/gnu_compil/gnu/scripts/guess-os`
export OS

if [ "x$host" = "xgnx5796" ]; then
  ACI_PORT=8000
  DOMAIN_NAME=gnb.st.com
else
  ACI_PORT=8080
  [ `echo $host | grep -c gnx` -gt 0 ] && DOMAIN_NAME=gnb.st.com
  [ `echo $host | grep -c crx` -gt 0 ] && DOMAIN_NAME=cro.st.com
fi

DEF_ACI_ROOT_DIR=`readlink -f $dir/..`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR
ACI_TOOL_NAME=jenkins

HUDSON_HOME=${ACI_ROOT_DIR}/aci_home
JENKINS_HOME=${ACI_ROOT_DIR}/aci_home


JAVA=java
#JAVA_HOME=/prj/hvd-aci/jdk1.7.0
JAVA_HEAP_DEBUG_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${ACI_ROOT_DIR}"
JAVA_JDB_DEBUG_OPTIONS="-Xdebug -Xrunjdwp:transport=dt_socket,address=8003,server=y,suspend=n"

# uncomment this to activate heap dumps and debug (jdb -attach 8000) support
#JAVA_OPTIONS="-Xmx8192m $JAVA_HEAP_DEBUG_OPTIONS $JAVA_JDB_DEBUG_OPTIONS"
# uncomment this for normal (non debug) runnin mode
JAVA_OPTIONS="-Xmx8192m"

WAR="${ACI_ROOT_DIR}/${ACI_TOOL_NAME}.war"

PATH=/usr/ucb:/usr/atria/bin:/usr/atria/doc/man:/usr/atria/etc/utils:$PATH

export HUDSON_HOME
export JENKINS_HOME
export PATH

echo "setup environment"
cat > ${ACI_ROOT_DIR}/aci.info << EOF
#!/bin/sh
ACI_ROOT_DIR=${ACI_ROOT_DIR}
JENKINS_HOST=${host}.${DOMAIN_NAME}
ACI_URL=http://${host}.${DOMAIN_NAME}:${ACI_PORT}
EOF


cd ${ACI_ROOT_DIR}
echo "Launching aci java war file"
echo "exec ${JAVA} ${JAVA_OPTIONS} -jar ${WAR} --httpPort=${ACI_PORT} $@"
exec ${JAVA} ${JAVA_OPTIONS} -jar ${WAR} --httpPort=${ACI_PORT}  $@

