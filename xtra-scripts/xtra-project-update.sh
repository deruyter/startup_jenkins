#!/bin/sh -x

fromdir=`pwd`
mydir=`dirname $0`
mydir=`(cd $mydir ; pwd)`
pname=`basename $0`
list_project=""

DATE=`date +%y%m%d-%H%M`

tmpdir=${WORKSPACE:-/tmp/addnewproject-$$}
[ -d ${tmpdir} ] || mkdir -p $tmpdir
cd $tmpdir
project_dir=${ACI_ROOT_DIR/projects:-$tmpdir/projects}
[ -d ${project_dir} ] || mkdir -p  ${project_dir}


script_name=""
[ "x$action" = "xadd" ] && script_name=${ACI_ROOT_DIR}/scripts/add_project.sh
[ "x$action" = "xupdate" ] && script_name=${ACI_ROOT_DIR}/scripts/add_project.sh
[ "x$action" = "xremove" ] && script_name=${ACI_ROOT_DIR}/scripts/rem_project.sh


env branch=$branch \
 module=$module \
 target=$target \
 valid_type=$valid_type \
 username=$username \
 unique=$unique \
 debug=$debug \
 build_host=$build_host \
 sh -x ${script_name} ${1+"$@"} 

