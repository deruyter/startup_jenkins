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
