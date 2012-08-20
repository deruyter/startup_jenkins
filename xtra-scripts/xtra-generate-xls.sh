#!/bin/sh
##
## DESC : Generate XLS comparison file between 2 sets of open64 branch and revision.
##
##
##
echo "module=" $module
echo "dev_branch=" $dev_branch
echo "dev_branch_revision=" $dev_branch_revision
echo "ref_branch=" $ref_branch
echo "ref_branch_revision=" $ref_branch_revision
echo "target=" $target
echo "workspace="$WORKSPACE
echo "options=" $options

MY_HOST="linux"
MY_MODULE=$module

cd ${WORKSPACE}

artifactsdir=${WORKSPACE}/artifacts
\rm -Rf $artifactsdir
mkdir -p $artifactsdir

OPTIONS=`echo $options | sed 's|,| |'`

echo ""
echo "Generating comparisons in excel_cmp/"
echo ""

normalize_branch_name() {
    TMP_BNAME=$1
    if [ "$TMP_BNAME" != "trunk" ]; then
        TMP_BNAME=`echo $TMP_BNAME | sed 's|^branches/||;s|/|-|'`
    fi
    echo $TMP_BNAME
}

CURRENT_BRANCH=`normalize_branch_name $dev_branch`
PARENT_BRANCH=`normalize_branch_name $ref_branch`

TARGETS=$target

#PERF_BASEDIR="/sw/gnu_compil/stxp70work/aci/results/performance"
PERF_BASEDIR="/work/aci-cec/aci-storage/performance/$MY_HOST/$MY_MODULE"

DUMMY_INFO=/home/theryt/bin/aci/INFO
SQA_REPORT=/work/aci-cec/aci/STxP70Valid/run_valid/lsf/sqa_report

do_big_echo() {
    echo "######"
    echo "###### $1"
    echo "######"
    echo ""
}

do_echo() {
    echo "------ $1"
    echo ""
}

register_error() {
    ((NB_ERROR=NB_ERROR+1))
    error_msg=$*
    echo '<field name="ERROR " titlecolor="#aa0000" detailcolor="#aa0000" value=" '$error_msg'"/>' >> $SUMMARY_XML
}

NB_ERROR=0
NB_XLS=0

SUMMARY_XML=$artifactsdir/10-summary.xml
RESULT_XML=$artifactsdir/20-result.xml
RESULT_YAML=$artifactsdir/20-result.yaml
RESULT_YAML_TMP=$artifactsdir/20-result.yaml.tmp
STDOUT_XML=$artifactsdir/30-stdout.xml

echo '<section name="Build Information">' > $SUMMARY_XML
echo '<field name="Development branch " value=" '$dev_branch' @ '$dev_branch_revision'"/>' >> $SUMMARY_XML
echo '<field name="Reference branch " value=" '$ref_branch' @ '$ref_branch_revision'"/>' >> $SUMMARY_XML
echo '<field name="target " value=" '$target'"/>' >> $SUMMARY_XML
if [ "x$options" != "x" ]; then
    echo '<field name="Options " value=" '$options'"/>' >> $SUMMARY_XML
else
    echo '<field name="Options " value=" (all)"/>' >> $SUMMARY_XML
fi

##
## Extract run-valid results
##
for target in $TARGETS; do

    \rm -Rf $target

    do_big_echo "Extract run-valid results for target $target"


    BASE_RES_DIR=${PERF_BASEDIR}/${CURRENT_BRANCH}/${target}
    if [ "x$dev_branch_revision" != "x" ]; then
        RES_DIR=${BASE_RES_DIR}/${dev_branch_revision}
        if [ ! -d ${RES_DIR} ]; then
            register_error "Cannot find directory that match Specified development branch/revision (${RES_DIR})"
            RES_DIR=""
        fi
    else
        RES_DIR=`ls ${BASE_RES_DIR} | tail -n1`
        if [ "x$RES_DIR" = "x" ]; then
            register_error "Cannot find directory that match development branch (${BASE_RES_DIR}/*)"
            RES_DIR=""
        else
            RES_DIR="${BASE_RES_DIR}/${RES_DIR}"
        fi
    fi
    if [ "x$RES_DIR" != "x" ]; then
        do_echo "Copying results from $RES_DIR"
        mkdir -p $target/branch
        pushd $target/branch
        tar xzf $RES_DIR/Run_Valid.tgz
        ##
        ## Create dummy INFO file
        ##
        cd Run_Valid
        for subdir in `ls`; do
            if [ -d $subdir ]; then
                do_echo "$PWD: cp $DUMMY_INFO $subdir"
                cp $DUMMY_INFO $subdir
            fi
        done
        popd
    fi
 
    BASE_RES_DIR=${PERF_BASEDIR}/${PARENT_BRANCH}/${target}
    if [ "x$ref_branch_revision" != "x" ]; then
        RES_DIR=${BASE_RES_DIR}/${ref_branch_revision}
        if [ ! -d ${RES_DIR} ]; then
            register_error "Cannot find directory that match Specified reference branch/revision (${RES_DIR})"
            RES_DIR=""
        fi
    else
        RES_DIR=`ls ${BASE_RES_DIR} | tail -n1`
        if [ "x$RES_DIR" = "x" ]; then
            register_error "Cannot find directory that match reference branch (${BASE_RES_DIR}/*)"
            RES_DIR=""
        else
            RES_DIR="${BASE_RES_DIR}/${RES_DIR}"
        fi
    fi
    if [ "x$RES_DIR" != "x" ]; then
        do_echo "Copying results from $RES_DIR"
        mkdir -p $target/parent
        pushd $target/parent
        tar xzf $RES_DIR/Run_Valid.tgz
        ##
        ## Create dummy INFO file
        ##
        cd Run_Valid
        for subdir in `ls`; do
            if [ -d $subdir ]; then
                do_echo "$PWD: cp $DUMMY_INFO $subdir"
                cp $DUMMY_INFO $subdir
            fi
        done
        popd
    fi
    
done

echo
echo

if [ $NB_ERROR -eq 0 ]; then
    echo "{section name: 'Result XLS', tabs: [ {name: 'Results', content: [" > $RESULT_YAML
    echo '<section name="Other Information">' > $STDOUT_XML
    echo "<field name=\"Stdout log \">" >> $STDOUT_XML
    echo "<![CDATA[" >> $STDOUT_XML


    ##
    ## Generate XLS files
    ##
    for target in $TARGETS; do

        do_big_echo "Compute excel summary"

        pushd $target/branch/Run_Valid

        if [ "x$OPTIONS" != "x" ]; then
            #
            # Only generate XLS for options specified as input
            #
            for opt in $OPTIONS; do
                echo "tt2: check option $opt"
                if [ ! -d $opt ]; then
                    register_error 'No result for option '$opt' in development branch archive'
                elif [ ! -d "../../parent/Run_Valid/$opt" ]; then
                    register_error 'No result for option '$opt' in reference branch archive'
                else
                    do_echo "$PWD: $SQA_REPORT -aci -aci-output ${RESULT_YAML_TMP} -o $opt.xls $opt ../../parent/Run_Valid/$opt"
                    $SQA_REPORT -aci -aci-output ${RESULT_YAML_TMP} \
                        -o $opt.xls $opt ../../parent/Run_Valid/$opt >> ${STDOUT_XML}
                    cat $RESULT_YAML_TMP >> $RESULT_YAML
                    rm $RESULT_YAML_TMP
                    ((NB_XLS=NB_XLS+1))
                fi
            done
            
        else
            #
            # Generate XLS for all options
            #
            for opt in `ls`; do
            
                if [ -d $opt ]; then
                    if [ ! -d "../../parent/Run_Valid/$opt" ]; then
                        register_error 'No result for option '$opt' in reference branch archive'
                    else
                        do_echo "$PWD: $SQA_REPORT -aci -aci-output ${RESULT_YAML_tmp} -o $opt.xls $opt ../../parent/Run_Valid/$opt"
                        $SQA_REPORT -aci -aci-output ${RESULT_YAML_TMP} \
                            -o $opt.xls $opt ../../parent/Run_Valid/$opt >> ${STDOUT_XML}
                        cat $RESULT_YAML_TMP >> $RESULT_YAML
                        rm $RESULT_YAML_TMP
                        ((NB_XLS=NB_XLS+1))
                    fi
                fi
            done
        fi

        echo "]} ]}" >> $RESULT_YAML


        if [ $NB_XLS -gt 0 ]; then
            mv *.xls ${artifactsdir}
            svn co http://codex.cro.st.com/svnroot/aci/projects/trunk/open64_valid
            cd open64_valid
            python2.7 generate_perf_report.py -xls-dir artifact/artifacts -o $RESULT_XML $RESULT_YAML
            cp -r reporting/* ${artifactsdir}
        fi

        popd
        
    done
fi

echo '</section>' >> $SUMMARY_XML

echo "]]></field></section>" >> $STDOUT_XML

echo "Done."

if [ $NB_ERROR -gt 0 ]; then
    false
else
    true
fi
