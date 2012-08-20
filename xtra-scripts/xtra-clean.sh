#!/bin/sh -x

mydir=`dirname $0`
mydir=`cd $mydir; pwd`

error() {
  echo $1 >&2
  exit 1
}

aci_workdir=`cd ${ACI_ROOT_DIR}; pwd`
MY_ACI_ROOT_DIR=${aci_workdir}

if [ `echo $HOST | grep crx | wc -l` -eq 1 ] ; then
  MY_ACI_WSPACE_DIR=/sw/gnu_compil/stxp70work/aci/workspace
else 
  MY_ACI_WSPACE_DIR=/work/aci-cec/aci_slaves/workspace
fi

local_dir=`pwd`
cd ${aci_workdir}/../results/compilers
## Keep only the latest built toolset for each target.
for radix in `${MY_ACI_ROOT_DIR}/scripts/find_monitored_branches.sh -p` ; do
  if [ `ls | grep ${radix} | wc -l` -gt 1 ] ; then
    arm_found=0
    st200_found=0
    stxp70_found=0
    stxp70v4_found=0
    echo should work on ${radix}
    for dir in `ls | grep ${radix} | grep -v debug | sort -r` ; do
      if [ -d ${dir}/arm ] ; then 
        if [ $arm_found -gt 0 ] ; then 
          \rm -rf ${dir}/arm
          [ -f ${dir}/comp.tgz ] && \rm -rf ${dir}/comp.tgz
          [ -f ${dir}/extract.end ] && \rm -rf ${dir}/extract.end
        else
          arm_found=1
        fi
      fi
      if [ -d ${dir}/st200 ] ; then 
        if [ $st200_found -gt 0 ] ; then 
          \rm -rf ${dir}/st200
          [ -f ${dir}/comp.tgz ] && \rm -rf ${dir}/comp.tgz
          [ -f ${dir}/extract.end ] && \rm -rf ${dir}/extract.end
        else
          st200_found=1
        fi
      fi
      if [ -d ${dir}/stxp70 ] ; then 
        if [ $stxp70_found -gt 0 ] ; then 
          \rm -rf ${dir}/stxp70
          [ -f ${dir}/comp.tgz ] && \rm -rf ${dir}/comp.tgz
          [ -f ${dir}/extract.end ] && \rm -rf ${dir}/extract.end
        else
          stxp70_found=1
        fi
      fi
      if [ -d ${dir}/stxp70v4 ] ; then 
        if [ $stxp70v4_found -gt 0 ] ; then 
          \rm -rf ${dir}/stxp70v4
          [ -f ${dir}/comp.tgz ] && \rm -rf ${dir}/comp.tgz
          [ -f ${dir}/extract.end ] && \rm -rf ${dir}/extract.end
        else
          stxp70v4_found=1
        fi
      fi
    done
  fi
done  

## Clean compilers if project not registered anymore
cd ${MY_ACI_ROOT_DIR}/../results/compilers
all_projects=`${MY_ACI_ROOT_DIR}/scripts/list_aci_project`
if [ "x$all_projects" != "x" ]; then
  for dir in `find * -maxdepth 0 -type d | grep open64-linux | grep -v trunk` ; do
    my_branch=`echo $dir | sed -e 's#open64-linux-##g' | sed -e 's#hudson-##g'`
    my_branch=`echo $my_branch | sed -e 's/-debug//' | sed -e 's/-for_experiment//' | sed -e 's/-st200gdb-noskip//' `
    my_branch=`echo $my_branch | sed -e 's/\(.*\)-[0-9][0-9][0-9][0-9][0-9]/\1/'`
    if [ `echo $all_projects | grep $my_branch | wc -l` -eq 0 ] ; then
      echo should remove $my_branch : $dir
      rm -rf $dir
    fi
  done
fi

## Clean compilers dir if empty
cd ${MY_ACI_ROOT_DIR}/../results/compilers
for dir in `find * -maxdepth 0 -type d | grep open64-linux` ; do
  [ -d $dir/arm ] && continue
  [ -d $dir/st200 ] && continue
  [ -d $dir/stxp70 ] && continue
  [ -d $dir/stxp70v4 ] && continue
  echo "$dir can be removed"
  rm -rf $dir
done

#### Execute cleanup script from workspace
cd  ${MY_ACI_WSPACE_DIR}
[ -f cleanup.py ] && /sw/st/gnu_compil/gnu/linux-rh-ws-3/bin/python cleanup.py
[ -f cleanup.sh ] && sh -x cleanup.sh

#### Execute cleanup script from job space
cd ${MY_ACI_ROOT_DIR}/aci_home/jobs
[ -f cleanup.py ] && /sw/st/gnu_compil/gnu/linux-rh-ws-3/bin/python cleanup.py
[ -f cleanup.sh ] && sh -x cleanup.sh

cd $WORKSPACE

[ "x$LOCAL_ONLY" != "x" ] && exit 0

# Update in Crolles
my_module=hudson_cleaning
my_script=update_${my_module}.sh
remote_host=`grep HOST ${aci_workdir}/references/crolles.config | cut -d "=" -f 2`
remote_user=`grep USER ${aci_workdir}/references/crolles.config | cut -d "=" -f 2`
remote_dir=`grep ACI_LOCATION ${aci_workdir}/references/crolles.config | cut -d "=" -f 2` 

echo Create Crolles Update Script
cat >${mydir}/${my_script} <<EOF
!/bin/sh -x
error() {
  echo "ERROR: [validfailed]: $0: $1" >&2
  exit 1
}
env ACI_ROOT_DIR=${remote_dir}/hconfig LOCAL_ONLY=1 ${remote_dir}/hconfig/xtra-scripts/xtra-clean.sh || error "command did not work"
true
EOF

scp ${mydir}/${my_script} $remote_user@$remote_host:${remote_dir}/${my_script}
ssh $remote_user@$remote_host chmod +x ${remote_dir}/${my_script}
ssh $remote_user@$remote_host ${remote_dir}/${my_script}
ssh $remote_user@$remote_host rm ${remote_dir}/${my_script}
