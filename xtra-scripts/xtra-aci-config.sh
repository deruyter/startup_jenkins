#!/bin/sh -x

mydir=`dirname $0`
mydir=`cd $mydir; pwd`

ACI_ROOT_DIR=${ACI_ROOT_DIR:-/work/aci-cec/hudson/hconfig}

aci_workdir=`cd ${ACI_ROOT_DIR}; pwd`
pname=$1_${BUILD_NUMBER}

my_host=`hostname`
WORKSPACE=${WORKSPACE:-/tmp}
JOB_NAME=${JOB_NAME:-xtra-aci-config}


echo "Run at date `date` from `hostname`:`pwd` with command: $0 $*"
GUESS_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`
[ "$GUESS_PATH" != "" ] && PATH=$GUESS_PATH:$PATH
export PATH
GUESS_LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`
[ "$GUESS_LD_LIBRARY_PATH" != ":" ] && LD_LIBRARY_PATH=$GUESS_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
OS=`/sw/st/gnu_compil/gnu/scripts/guess-os`
[ "$OS" != "" ] || OS=linux-rh-ws-3
export OS

[ "${projectname}" != "" ] && echo "Running ACI Project ${projectname}"


# Update ccconfig
cd $aci_workdir || exit 1
#detect conflicts
which svn
svn update . | grep "^C " && echo validfailed


[ -f ${WORKSPACE}/modif_svn.txt ] && mv ${WORKSPACE}/modif_svn.txt ${WORKSPACE}/modif_svn.txt.bak

${ACI_ROOT_DIR}/jenkins-cli.sh list-changes ${JOB_NAME} ${BUILD_NUMBER} | grep "projects/" > ${WORKSPACE}/modif_svn.txt
while read line; do
  PRJ=`echo $line | sed -e "s#projects/##g"`
  if [ -f ${ACI_ROOT_DIR}/projects/${PRJ} ] ; then 
    if [ ! -d ${ACI_ROOT_DIR}/aci_home/jobs/${PRJ} ] ; then
      echo "Create Project ${PRJ}" 
      ${ACI_ROOT_DIR}/jenkins-cli.sh create-job  $PRJ < ${aci_workdir}/projects/${PRJ}
    else
      echo "Update Project ${PRJ}" 
      ${ACI_ROOT_DIR}/jenkins-cli.sh update-job  $PRJ < ${aci_workdir}/projects/${PRJ}
    fi
  else
    echo "Remove Project ${PRJ}"  
    ${ACI_ROOT_DIR}/jenkins-cli.sh delete-job  $PRJ 
  fi
done < ${WORKSPACE}/modif_svn.txt
 
## Update in Crolles

my_module=hconfig
my_script=update_${my_module}.sh

remote_host=`grep HOST ${aci_workdir}/references/crolles.config | cut -d "=" -f 2`
remote_user=`grep USER ${aci_workdir}/references/crolles.config | cut -d "=" -f 2`
remote_dir=`grep ACI_LOCATION ${aci_workdir}/references/crolles.config | cut -d "=" -f 2` 

echo Create Crolles Update Script
cat >${mydir}/${my_script} <<EOF
#!/bin/sh -x

error() {
    echo "ERROR: [validfailed]: $0: $1" >&2
    exit 1
}

cd ${remote_dir}
if [ ! -d ${my_module} ] ; then
  svn co --force --quiet --non-interactive https://codex.cro.st.com/svnroot/aci/${my_module}/trunk  ${my_module} || error "unable to extract ${my_module} at revision: $svn_branch $svn_revision"
else
  cd ${my_module}
  svn update . | grep "^C " && echo validfailed
fi  
true
EOF

scp ${mydir}/${my_script} $remote_user@$remote_host:${remote_dir}/${my_script}
ssh $remote_user@$remote_host chmod +x ${remote_dir}/${my_script}
ssh $remote_user@$remote_host ${remote_dir}/${my_script}
ssh $remote_user@$remote_host rm ${remote_dir}/${my_script}

true
