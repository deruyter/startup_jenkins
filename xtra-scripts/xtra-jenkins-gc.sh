#!/bin/sh

mydir=`dirname $0`
mydir=`cd $mydir; pwd`

passwd=`cat ${ACI_ROOT_DIR}/../.passwd.hudson`

port=8000

java_pid=`ps uwx | grep jenkins.war | grep java | grep -v -- '-c java' | grep "httpPort=${port}" | awk '{ print $2}'`
before=`ls -la /proc/${java_pid}/fd | wc -l`

curl -s http://acicecmg:${passwd}@aci-cec.gnb.st.com:${port}/gc

after=`ls -la /proc/${java_pid}/fd | wc -l`

echo "Before cleanup,After cleanup" > report.csv
echo "$before,$after" >> report.csv
