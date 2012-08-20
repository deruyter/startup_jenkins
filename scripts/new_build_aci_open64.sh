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

pname=${JOB_NAME}_${BUILD_NUMBER}
SID=hudson-${pname}

echo arguments: $*

cleanup() {
    ${job_dir}/job-kill.sh sid=${SID} groupname=open64_valid
}

error() {
    echo "ERROR: $0: $projectname $*" >&2
    cleanup 
    exit 1
}

[ "${module}" != "" ] || error "missing component argument"
if [ "$comp_valid" = "" ]; then
    comp_valid=${module}_valid
fi

GUESS_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`
[ "$GUESS_PATH" != "" ] && PATH=$GUESS_PATH:$PATH
export PATH
GUESS_LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`
[ "$GUESS_LD_LIBRARY_PATH" != ":" ] && LD_LIBRARY_PATH=$GUESS_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
OS=`/sw/st/gnu_compil/gnu/scripts/guess-os`
[ "$OS" != "" ] || OS=linux-rh-ws-3
export OS

trap "error" 2 3 15 # trap on exit 

cmd() {
    failed=0
    echo Executing at `date +%y%m%d-%H%M%S`'>' $*
    $HUDSON_DRY ${1+"$@"} || failed=1
    [ "$failed" = "1" ] && echo Failed at `date +%y%m%d-%H%M%S`'>' $*
    [ "$failed" = "1" ] && exit 1
    echo Completed at `date +%y%m%d-%H%M%S`'>' $*

}

#<td value="Skipped" bgcolor="#99CCFF" align="center"/>
#<td value="Failure" fontcolor="#FFFFFF" bgcolor="#FF0000" align="center"/>
#<td value="Success" bgcolor="#00FF00" align="center"/>

[ "$STxP70V3" = "ON" -a "x$module" = "xopen64" -a "x$FORCE_V3" = "x" ] && STxP70V3="OFF"
get_report_status() {
  target=$1 
  if [ "$2" = "ON" ] ; then
    RStatus="Success"
    RColor="#000000"
    RBgcolor="#99CC66"
    Rclass="sc"
    duration=`${job_dir}/job-duration.sh sid=${SID} jname=${JOB_NAME}_${target}`
    minute=`expr $duration / 60`
    second=`expr $duration % 60`
    msg="${minute}m${second}s"
    echo "$JOB_NAME: $msg" >> ${workdir}/artifacts/Validation_Info.txt
    ${job_dir}/job-status.sh sid=${SID} jname=${JOB_NAME}_${target}
    [ $? != 0 ] && RStatus="Failure" && RColor="#FFFFFF" && RBgcolor="#CC6666" && Rclass="fl" && status=1
    cp ${JOB_NAME}_${target}.out ${workdir}/artifacts/
    #Check that valid failed was not issues in logs
    cat ${JOB_NAME}_${target}.out | grep '[v]alidfailed' >/dev/null && RStatus="Failure" && RColor="#FFFFFF" && RBgcolor="#CC6666" && Rclass="fl" && status=1
cat >> ${high_level_report} <<EOF
    <tr> 
      <td value="$target" align="center"/>
      <td value="$RStatus" fontcolor="$RColor" bgcolor="$RBgcolor" align="center"/>
      <td align="center">
         <![CDATA[<a href="http://gnx5796.gnb.st.com:8080/aci-results/${JOB_NAME}/${BUILD_NUMBER}/${target}_main_log.xml">Report</a>]]>
      </td>
      <td value="$msg" align="center"/>
    </tr>
EOF
cat >> ${mail_report} <<EOF
    <tr> 
      <td>$target</td>
      <td class="$Rclass">$RStatus</td>
      <td><a href="http://gnx5796.gnb.st.com:8080/aci-results/${JOB_NAME}/${BUILD_NUMBER}/${target}_main_log.xml">Report</a></td>
      <td>$msg</td>
    </tr>
EOF
  else
cat >> ${high_level_report} <<EOF
    <tr> 
      <td value="$target" align="center"/>
      <td value="Skipped" bgcolor="#99CCFF" align="center"/>
      <td value="-" align="center"/>
      <td value="-" align="center"/>
    </tr>
EOF
cat >> ${mail_report} <<EOF
    <tr> 
      <td>$target</td>
      <td class="sk">Skipped</td>
      <td>-</td>
      <td>-</td>
    </tr>
EOF
  fi
}

# Create working directory (already exists if ran from cruisecontrol)
workdir=$WORKSPACE
mkdir -p $workdir
cd $workdir || error "cannot chdir to $workdir"
if [ "$noclean_workspace" = "" ] ; then
  mkdir  ${workdir}/old_wspace
  [ -d ${workdir}/artifacts ] && mv ${workdir}/artifacts ${workdir}/old_wspace/.
  [ -d ${workdir}/log ] && mv ${workdir}/log ${workdir}/old_wspace/.
  [ -d ${workdir}/open64_valid ] && mv ${workdir}/open64_valid ${workdir}/old_wspace/.
  [ -d ${workdir}/valid ] && mv ${workdir}/valid ${workdir}/old_wspace/.
  mv *.out *.err *.sh ${workdir}/old_wspace/.
  rm -rf ${workdir}/old_wspace &
fi
high_level_report="${workdir}/artifacts/00_high_level_report.xml"
mail_report="${workdir}/artifacts/00_mail.txt"


normalized_branch=`echo $branch | sed 's![^_a-zA-Z0-9]!-!g'`
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
# First extract ccconfig and deptools
${aci_workdir}/scripts/extract_deptools || error "extraction of deptools failed"

DEP_FILE=${aci_workdir}/references/DEPENDENCIES
normalized_branch=`echo $branch | sed 's![^_a-zA-Z0-9]!-!g'`
[ -f ${aci_workdir}/references/DEPENDENCIES.${normalized_branch} ] && DEP_FILE=${aci_workdir}/references/DEPENDENCIES.${normalized_branch}

open64_dep=`grep -v '^#' <$DEP_FILE | grep '^open64_valid,svn'`
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

all_targets=""
[ "$STxP70V3" = "ON" ] && all_targets="$all_targets stxp70"
[ "$STxP70V4" = "ON" ] && all_targets="$all_targets stxp70v4"
[ "$ST200" = "ON" ] && all_targets="$all_targets st200"
[ "$ARM" = "ON" ] && all_targets="$all_targets arm"

index=1
for target in $all_targets; do
  cmd $job_submit jname=${JOB_NAME}_${target} index=$index -- env \
    WORKSPACE=${WORKSPACE} \
    BUILD_NUMBER=${BUILD_NUMBER} \
    BUILD_ID=${BUILD_ID} \
    JENKINS_URL=${JENKINS_URL} \
    SVN_REVISION=${SVN_REVISION} \
    JOB_NAME=${JOB_NAME} \
    ACI_ROOT_DIR=${aci_workdir} \
    pname=${pname} \
    branch=${branch} \
    build_host=${build_host} \
    confdir=${workdir}/open64_valid/config \
    artifactspublisherdir=${workdir}/artifacts \
    target=${target} \
    short_valid=${short_valid} \
    module=${module} \
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

touch  ${high_level_report}
touch  ${mail_report}

echo "<section name='Validation Report For ${JOB_NAME} build ${BUILD_NUMBER} ( ${BUILD_ID} )'>" >> ${high_level_report}

cat >> ${mail_report} <<EOF
<p class="thick"> 
Validation Report For ${JOB_NAME} build ${BUILD_NUMBER} ( ${BUILD_ID} ) <br /><br />
EOF



if [ "x$module" = "xstxp70-nightly" ]; then
    echo "<field name=\"Validation triggered by a toolset build \"><![CDATA[" >> ${high_level_report}
    echo "        <a href=\"${JENKINS_URL}/job/${TRIGGERED_BY}\">${TRIGGERED_BY}</a>" >> ${high_level_report}
    echo "]]></field>" >> ${high_level_report}
    
    echo "Validation triggered by a toolset build:<a href=\"${JENKINS_URL}/job/${TRIGGERED_BY}\">${TRIGGERED_BY}</a> <br />" >> ${mail_report}

else
    echo "<field name='Branch tested' value=' ${branch}@${SVN_REVISION}'/>" >> ${high_level_report}
    echo "Branch tested: ${branch}@${SVN_REVISION} <br />" >> ${mail_report}
fi

cat >> ${high_level_report} <<EOF
  <table>
    <tr> 
      <td value="Target Tested" fontattribute="bold" width="120" align="center"/>
      <td value="Functional Status" fontattribute="bold" width="60" align="center"/>
      <td value="Report Link" fontattribute="bold" width="60" align="center"/>
      <td value="Duration" fontattribute="bold" width="60" align="center"/>
    </tr>
EOF

cat >> ${mail_report} <<EOF
  <table id="reports">
    <tr> 
      <th>Target Tested</th>
      <th>Functional Status</th>
      <th>Report Link</th>
      <th>Duration</th>
    </tr>
EOF


status=0
get_report_status "stxp70" $STxP70V3
get_report_status "stxp70v4" $STxP70V4
get_report_status "st200" $ST200
get_report_status "arm" $ARM

cat  >>  ${high_level_report} <<EOF
  </table>
</section>
EOF

echo "</table></p>" >> ${mail_report}

exit $status
