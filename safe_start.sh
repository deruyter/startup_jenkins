#!/usr/bin/env bash
#
# usage: safe_start.sh
#
# Starts ACI safely
#
set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir;pwd`


# Internal FIX [ -d  $dir/aci_home/plugins/ldap/WEB-INF ] && cp -f $dir/admin/LDAPBindSecurityRealm.groovy $dir/aci_home/plugins/ldap/WEB-INF/classes/hudson/security/LDAPBindSecurityRealm.groovy 

$dir/admin/check-and-start-aci.sh $dir/admin/pause-and-start-aci.sh $@
$dir/admin/wait-for-aci.sh

echo 
echo "Jenkins started."
echo "Use $dir/safe_acticate.sh to re-activate all jobs."
echo "Use $dir/safe_stop.sh to stop the server from command line when no jobs are running."
echo
