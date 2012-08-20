#!/bin/sh -x
#
# <cc-project-name> is the cruise control project name.
# It can be used to retrieve configuration for a project.
# the configuration files for each project are in config/<cc-project-name>
# The current directory is the cruisecontrol working dir ccconfig/work1.
#

mydir=`dirname $0`
mydir=`(cd $mydir ; pwd)`

aci_workdir=`cd ${ACI_ROOT_DIR}; pwd`

[ "$1" != "" ] || error "missing project name argument"

pname=$1_${BUILD_NUMBER}
SID=hudson-${pname}
shift
echo arguments: $*

cleanup() {
    ${job_dir}/job-kill.sh sid=${SID}
    echo "ERROR: $0: $1"
}

trap "cleanup 'Interrupted by signal'" 2 3 15

error() {
    echo "ERROR: $0: $projectname $*" >&2
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

GUESS_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`
[ "$GUESS_PATH" != "" ] && PATH=$GUESS_PATH:$PATH
export PATH
GUESS_LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`
[ "$GUESS_LD_LIBRARY_PATH" != ":" ] && LD_LIBRARY_PATH=$GUESS_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
OS=`/sw/st/gnu_compil/gnu/scripts/guess-os`
[ "$OS" != "" ] || OS=linux-rh-ws-3
export OS



# Create working directory (already exists if ran from cruisecontrol)
workdir=$WORKSPACE
mkdir -p $workdir
cd $workdir || error "cannot chdir to $workdir"
[ -d artifacts ] && rm -rf artifacts
[ -d log ] && rm -rf log
[ -d gcc_valid ] && rm -rf gcc_valid
# [ -d aci_svn_valid ] && rm -rf aci_svn_valid
[ -d valid ] && rm -rf valid
[ -d deptools ] && rm -rf deptools
# rm -rf build_and_valid*
# rm -rf *

d_branch=`echo $branch | sed 's![^_a-zA-Z0-9]!-!g'`
job_dir=`readlink -f /sw/st/gnu_compil/comp/scripts/jobtools`
if [ -f ${aci_workdir}/references/jobtools.dep.${d_branch} ] ; then 
  JOBTOOLS_REF_FILE=${aci_workdir}/references/jobtools.dep.${d_branch}
  /sw/st/gnu_compil/comp/scripts/deptools/deptools/deptool.py -f ${JOBTOOLS_REF_FILE} extract
  job_dir=`readlink -f jobtools`
fi
[ -d $job_dir ] || error "Jobtools are not available" 
queue=reg
job_submit="${job_dir}/job-submit.sh sid=${SID} queue=$queue cond=RH4_only groupname=gcc_valid"

#cp -r /home/compwork/alfonsi/Tests/ACI/aci/projects/gcc_valid .
svn checkout --quiet --non-interactive https://codex.cro.st.com/svnroot/aci/projects/trunk/gcc_valid gcc_valid

gcc_valid_branch=`svn info gcc_valid | grep 'Revision:' | cut -d' ' -f2`
gcc_valid_revision=`svn info gcc_valid | grep 'URL:' | sed -e 's|.*/gcc_valid/||' -e 's|branches/||'`

#Dump info
mkdir -p ${workdir}/artifacts
info_log=${workdir}/artifacts/gcc_valid.log
echo "gcc_valid_branch=$gcc_valid_branch"  > $info_log
echo "gcc_valid_revision=$gcc_valid_revision" >> $info_log

if [ "x$module" != "xgcc" ]; then
    # if current module is not gcc, then SVN_REVISION must not be propagated
    SVN_REVISION=""
fi

build_cmd=gcc_valid/build_and_valid.sh
[ -x $build_cmd ] || error "build command missing: $build_cmd"

job_name=build_and_valid

[ "$all_targets" = "" ] && all_targets=${target}

index=1

for target in $all_targets; do
  cmd $job_submit jname=${job_name}_${target} index=$index -- env \
    WORKSPACE=${WORKSPACE} \
    SVN_REVISION=${SVN_REVISION} \
    ACI_ROOT_DIR=${aci_workdir} \
    BUILD_URL=${BUILD_URL} \
    JOB_NAME=${JOB_NAME} \
    BUILD_NUMBER=${BUILD_NUMBER} \
    pname=${pname} \
    branch=${branch} \
    build_host=${build_host} \
    confdir=${workdir}/gcc_valid/config \
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
    gcc_build=$gcc_build $* \
    ./$build_cmd 
  ((index=index+1))
done

#Wait for jobs completion
${job_dir}/job-wait.sh sid=${SID} jname=gcc_valid index=1

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
  echo '================================='
  grep '[v]alidfailed' ${job_name}_${target}.out && status=1
  echo '================================='
  if [ ! -f ${workdir}/artifacts/log/email.html ]; then 
    echo '<pre>'                                    >  ${workdir}/artifacts/log/email.html
    grep  '[v]alidfailed' ${job_name}_${target}.out >> ${workdir}/artifacts/log/email.html
    echo '</pre>'                                   >> ${workdir}/artifacts/log/email.html
  fi    
done

exit $status
