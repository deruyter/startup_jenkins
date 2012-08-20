#!/bin/sh
#
# usage: jenkins-cli.sh <command...>
#
# Use ssh command line interface of jenkins (or java CLI if requested).
#
# parameters:
# STRICT: yes or no (default yes). If no, the first attempt to connect will create the key file
# KEYFILE: keyfile for the host key. Default: $dir/jenkins.key
# USE_JAVA_CLI: 1|0: use legacy JAVA CLI if 1. default to 0
#
set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir; pwd`

. $dir/aci.info

USE_JAVA_CLI=${USE_JAVA_CLI:-0}
#USE_JAVA_CLI=${USE_JAVA_CLI:-1}
error() {
    echo $* >&2
    exit 1
}


if [ "$USE_JAVA_CLI" = 1 ]; then
    # Use legacy Java based CLI
    KEYRSA=`readlink -f ~/.ssh/id_rsa.pub`
    ACI_URL=${ACI_URL:-http://aci-cec.gnb.st.com:8000}
    [ -f $dir/aci_home/war/WEB-INF/hudson-cli.jar ] && aci_cli_tool="$dir/aci_home/war/WEB-INF/hudson-cli.jar"
    [ -f $dir/aci_home/war/WEB-INF/jenkins-cli.jar ] && aci_cli_tool="$dir/aci_home/war/WEB-INF/jenkins-cli.jar"
    [ "x$aci_cli_tool" = "x" ] && error "Unable to find command line tool" -1
    JAVA_OPTIONS="-Xmx128m"
    JAVA=java
    jenkins_cli="$JAVA -jar $JAVA_OPTIONS $aci_cli_tool -s ${ACI_URL} -i $KEYRSA"
else
    JENKINS_HOST=${JENKINS_HOST:-gnx5796.gnb.st.com}
    JENKINS_SSH_PORT=${JENKINS_SSH_PORT:-22222}
    STRICT=${STRICT:-yes}
    KEYFILE=${KEYFILE:-$dir/jenkins.key}
    SERVER_IP_FILE=${SERVER_IP_FILE:-$dir/jenkins.ip}
    if [ "$STRICT" = no ] ; then
      rm -f $KEYFILE
      MY_IP=`hostname -I | head -1`
      [ "$MY_IP" = "" ] && MY_IP=`/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
      echo $MY_IP >$SERVER_IP_FILE
    fi
    SERVER_IP=`cat $SERVER_IP_FILE || true`
    [ "$SERVER_IP" != "" ] || error "unable to determine server IP from $SERVER_IP_FILE"
    jenkins_cli="ssh -oHostKeyAlias=$SERVER_IP -oServerAliveInterval=60 -oStrictHostKeyChecking=$STRICT -oUserKnownHostsFile=$KEYFILE -p $JENKINS_SSH_PORT $JENKINS_HOST"
fi

exec ${jenkins_cli} ${1+"$@"}
