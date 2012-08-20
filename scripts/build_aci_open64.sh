#!/bin/sh -x
#
# <cc-project-name> is the cruise control project name.
# It can be used to retrieve configuration for a project.
# the configuration files for each project are in config/<cc-project-name>
# The current directory is the cruisecontrol working dir ccconfig/work1.
#

mydir=`dirname $0`
mydir=`(cd $mydir ; pwd)`

GUESS_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`
[ "$GUESS_PATH" != "" ] && PATH=$GUESS_PATH:$PATH
export PATH
GUESS_LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`
[ "$GUESS_LD_LIBRARY_PATH" != ":" ] && LD_LIBRARY_PATH=$GUESS_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
OS=`/sw/st/gnu_compil/gnu/scripts/guess-os`
[ "$OS" != "" ] || OS=linux-rh-ws-3
export OS

aci_workdir=`readlink -f ${ACI_ROOT_DIR}`

cleanup() {
    ${job_dir}/job-kill.sh sid=${SID} groupname=open64_valid
}

trap "error" 2 3 15 # trap on exit 

error() {
    echo "ERROR: $0: $projectname $*" >&2
    cleanup 
    exit 1
}

cmd() {
    failed=0
    echo Executing at `date +%y%m%d-%H%M%S`'>' $*
    $HUDSON_DRY ${1+"$@"} || failed=1
    [ "$failed" = "1" ] && echo Failed at `date +%y%m%d-%H%M%S`'>' $*
    [ "$failed" = "1" ] && exit 1
    echo Completed at `date +%y%m%d-%H%M%S`'>' $*

}

[ "$1" != "" ] || error "missing project name argument"

pname=$1_${BUILD_NUMBER}
SID=cec-aci-${pname}
shift
echo arguments: $*

# Create working directory (already exists & required)
workdir=$WORKSPACE
mkdir -p $workdir
cd $workdir || error "cannot chdir to $workdir"
if [ "$noclean_workspace" = "" ] ; then
  mkdir old_wspace
  mv * old_wspace/.
  rm -rf old_wspace &
fi

d_branch=`echo $branch | sed 's![^_a-zA-Z0-9]!-!g'`
job_dir=`readlink -f /sw/st/gnu_compil/comp/scripts/jobtools`
if [ -f ${aci_workdir}/references/jobtools.dep.${d_branch} ] ; then 
  JOBTOOLS_REF_FILE=${aci_workdir}/references/jobtools.dep.${d_branch}
  /sw/st/gnu_compil/comp/scripts/deptools/deptools/deptool.py -f ${JOBTOOLS_REF_FILE} extract
  job_dir=`readlink -f jobtools`
fi
[ -d $job_dir ] || error "Jobtools are not available" 
queue=reg
job_submit="${job_dir}/job-submit.sh sid=${SID} queue=$queue cond=RH4_only groupname=open64_valid"

####################################
# Get branch and revision of open64_nightly
# Get revison file. If the project has its own revision take it
REVISION_FILE=${aci_workdir}/references/O64_REVISION

[ -f ${aci_workdir}/references/O64_REVISION.${d_branch} ] && REVISION_FILE=${aci_workdir}/references/O64_REVISION.${d_branch}

open64_dep=`grep -v '^#' <$REVISION_FILE | grep '^open64_valid,svn'`
[ "$open64_dep" != "" ] && open64_branch=`echo $open64_dep|cut -d, -f3|cut -d@ -f1`
[ "$open64_dep" != "" ] && open64_revision=`echo $open64_dep|cut -d, -f3|cut -d@ -f2`
[ "$open64_dep" != "" ] && open64_location=`echo $open64_dep|cut -d, -f4`

[ "$open64_branch" != "" -a "$open64_revision" != "" ] || error "cannot determine open64_valid revision to use: file missing: REVISION"

actual_revision=`svn info --non-interactive -r $open64_revision $open64_location/$open64_branch/open64_valid  | grep "Last Changed Rev" | awk '{print $4;}'`
[ "$actual_revision" != "" ] || error "cannot determine open64_valid actual revision at revision: $open64_branch $open64_revision"

# Extract open64_valid
if [ -d ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision} ] ; then
  echo "Import already existing scripts from ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}"
  while [ -f ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/.checkout_started ] ; do
    echo "wait for end of checkout"
    sleep 10
  done
  tar xzf ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/open64_valid.tgz 
  status=$?
  if [ $status != 0 ]; then
    rm -rf ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}
    mkdir -p ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}
    touch ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/.checkout_started
    [ -d open64_valid ] && rm -rf open64_valid
    echo "Extract open64_valid at revision: $open64_branch $open64_revision (actual revision: $actual_revision)"
    svn export --quiet --non-interactive -r $actual_revision $open64_location/$open64_branch/open64_valid open64_valid || error "unable to extract open64_valid at revision: $open64_branch $actual_revision"
    tar czf ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/open64_valid.tgz open64_valid
    rm ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/.checkout_started
  fi
else
  mkdir -p ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}
  touch ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/.checkout_started
  echo "Extract open64_valid at revision: $open64_branch $open64_revision (actual revision: $actual_revision)"
  svn export --quiet --non-interactive -r $actual_revision $open64_location/$open64_branch/open64_valid open64_valid || error "unable to extract open64_valid at revision: $open64_branch $actual_revision"
  tar czf ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/open64_valid.tgz open64_valid
  rm ${aci_workdir}/open64_scripts/open64_valid_${open64_branch}_${actual_revision}/.checkout_started
fi
######################################


#Dump info
mkdir -p ${workdir}/artifacts
info_log=${workdir}/artifacts/Open64_valid.log
echo "open64_valid_branch=$open64_branch"  > $info_log
echo "open64_valid_revision=$actual_revision" >> $info_log
echo "open64_valid_request_revision=$open64_revision" >> $info_log

if [ "x$module" != "xopen64" ]; then
    # if current module is not open64, then SVN_REVISION must not be propagated
    SVN_REVISION=""
fi

build_cmd=open64_valid/build_and_valid.sh
[ -x $build_cmd ] || error "build command missing: $build_cmd"

job_name=build_and_valid

[ "$all_targets" = "" ] && all_targets=${target}

index=1

for target in $all_targets; do
  cmd $job_submit jname=${job_name}_${target} index=$index -- env \
    WORKSPACE=${WORKSPACE} \
    BUILD_NUMBER=${BUILD_NUMBER} \
    SVN_REVISION=${SVN_REVISION} \
    ACI_ROOT_DIR=${aci_workdir} \
    module=${module} \
    pname=${pname} \
    branch=${branch} \
    build_host=${build_host} \
    confdir=${workdir}/open64_valid/config \
    cruisecontroldir=${workdir}/logs \
    artifactspublisherdir=${workdir}/artifacts \
    refrelease=${refrelease} \
    ref_parent=${ref_parent} \
    ref_baseline=${ref_baseline} \
    perf_parent=${perf_parent} \
    perf_baseline=${perf_baseline} \
    gdb_parent=${gdb_parent} \
    gdb_baseline=${gdb_baseline} \
    target=${target} \
    short_valid=${short_valid} \
    unique=$unique \
    ref_gdb_variant=$ref_gdb_variant \
    force_project=$force_project \
    really_force_project=$really_force_project \
    substitute=$substitute \
    opt_suffix="$opt_suffix" \
    st200gdb_no_skip="$st200gdb_no_skip" \
    BINOPTtarname=$BINOPTtarname \
    RTKbranch=$RTKbranch \
    RTKrevision=$RTKrevision \
    open64_build=$open64_build $* \
    ./$build_cmd 
  ((index=index+1))
done

#Wait for jobs completion
${job_dir}/job-wait.sh sid=${SID} jname=open64_valid index=1

status=0
for target in $all_targets; do
  duration=`${job_dir}/job-duration.sh sid=${SID} jname=${job_name}_${target}`
  minute=`expr $duration / 60`
  second=`expr $duration % 60`
  msg="${minute}m${second}s"
  echo "$job_name: $msg" >> ${workdir}/artifacts/Validation_Info.txt
  ${job_dir}/job-status.sh sid=${SID} jname=${job_name}_${target}
  [ $? != 0 ] &&  status=1
  cp ${job_name}_${target}.out ${workdir}/artifacts/
  #Check that valid failed was not issues in logs
  cat ${job_name}_${target}.out | grep  '[v]alidfailed' >/dev/null && status=1
done

exit $status
