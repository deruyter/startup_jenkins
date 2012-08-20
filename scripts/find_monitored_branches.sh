#!/bin/sh 
#

mydir=`dirname $0`
mydir=`(cd $mydir ; pwd)`

aci_workdir=`cd ${ACI_ROOT_DIR}; pwd`

All_Branches=""

add_branch()
{
  for branch in $All_Branches ; do
    [ "$1" = "$branch" ] && return
  done
  All_Branches="$All_Branches $1"
}

dump_branches()
{
  for branch in $All_Branches ; do
    echo $branch
  done
}

dump_project()
{
  for branch in $All_Branches ; do
    proj=`echo $branch | sed -e 's#branches/##g' | sed -e 's#/#-#g'`
    echo open64-linux-${proj}
  done
}


if [ -d ${aci_workdir}/projects ] ; then 
  for file in `ls ${aci_workdir}/projects` ; do
    if [ `cat ${aci_workdir}/projects/$file | grep "<remote>" | grep "/svnroot/open64/" | wc -l` = 1  ] ; then
      My_branch=`cat ${aci_workdir}/projects/$file | grep "<remote>" | sed -s 's#<remote>https://codex.cro.st.com/svnroot/open64/##g'`
      My_branch=`echo $My_branch| sed -s 's#</remote>##g'`
      add_branch $My_branch
    fi
  done
else
  ACI_SVN_ROOT_DIR=https://codex.cro.st.com/svnroot/aci/hconfig/trunk
  for file in `svn ls ${ACI_SVN_ROOT_DIR}/projects` ; do
    if [ `svn cat ${ACI_SVN_ROOT_DIR}/projects/$file | grep "<remote>" | grep "/svnroot/open64/" | wc -l` = 1  ] ; then
      My_branch=`svn cat ${ACI_SVN_ROOT_DIR}/projects/$file | grep "<remote>" | sed -s 's#<remote>https://codex.cro.st.com/svnroot/open64/##g'`
      My_branch=`echo $My_branch| sed -s 's#</remote>##g'`
      add_branch $My_branch
    fi
  done
fi

[ "$1" = "-b" ] && dump_branches
[ "$1" = "-p" ] && dump_project
