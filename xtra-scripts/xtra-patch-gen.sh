#!/bin/sh -x
#
# xtra-patch-gen <project_name> <verbose> [<module> <revision>]
#

mydir=`dirname $0`
mydir=`cd $mydir; pwd`
pname=$1_${BUILD_NUMBER}
verbose=$2

if [ "$3" != "" ]; then
    userdef_module=$3
fi

if [ "$4" != "" ]; then
    userdef_revision=$4
fi

# ensure logs and artifacts dir exist
artifactsdir=${WORKSPACE:-/tmp/svnwatch}
[ ! -d ${artifactsdir} ] && mkdir -p ${artifactsdir}

date=`date +%y%m%d-%H%M`

# Set PATH for svn
export PATH=`/sw/st/gnu_compil/gnu/scripts/guess-path`${PATH+:$PATH}
export LD_LIBRARY_PATH=`/sw/st/gnu_compil/gnu/scripts/guess-lib-path`${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}
export PATH=/sw/st/gnu_compil/gnu/Linux-RH-WS-3/.package/perl-5.8.8/bin:${PATH}


# Support function
function svn_last_revision() {
    local -r svn_url=${1:?}
    ${svnwatch_svn} info ${svn_url} | grep "Last Changed Rev" | awk '{print $4;}'
}

function mktempfile() {
    local -r tmpfile=`mktemp -q /tmp/temp.XXXXXX`
    true ${tmpfile:?}
    echo $tmpfile
}

function svn_actual_revision() {
    local -r svn_url=${1:?}
    local -r svn_revision=${2:?}
    ${svnwatch_svn} info -r ${svn_revision} ${svn_url} | grep "Last Changed Rev" | awk '{print $4;}'
}

function svn_get_changed() {
    local -r svn_url=${1:?}
    local -ri svn_revision=${2:?}
    ${svnwatch_svn} log --verbose -r ${svn_revision} ${svn_url} | (
	declare -i changed_=0
	while read line ; do
	    [ $changed_ = 0 -a "$line" = 'Changed paths:' ] && changed_=1
	    [ $changed_ -gt 1 -a "$line" = "" ] && changed_=0
	    [ $changed_ = 2 ] && echo "$line " | awk '{print $2;}'
	    [ $changed_ = 1 ] && changed_=2
	done
    )
}

function find_common_path() {
    local path1=${1:?}
    local path2=${2:?}
    [ `echo "$path1" | grep '^/'` = "" ] && return
    [ `echo "$path2" | grep '^/'` = "" ] && return
    [ "$path1" = "/" ] && path2="/"
    [ "$path2" = "/" ] && path1="/"
    if [ "$path1" != "$path2" ]; then
	declare common=`echo "$path2" | grep "$path1"`
	while [ "$path1" != "/" -a "$common" = "" ]; do
	    path1=`dirname $path1`
	    common=`echo "$path2" | grep "$path1"`
	done
    fi
    echo "$path1"
}
    

function find_list_common_path() {
    local current=""
    while read line ; do
	[ "$current" = "" ] && current="$line"
	current=`find_common_path "$current" "$line"`
	[ "$current" = "" ] && return
    done
    echo "$current"
}

function get_parent_branch() {
    local -r svn_url=${1:?}
    local -r svn_rev=${2:?}
    local path=${3:?}
    local parent=`${svnwatch_svn} pg -r ${svn_rev} svnbranch:parent "${svn_url}/${path}" 2>/dev/null`
    if [ "$parent" != "trunk" -a "`echo $parent | grep '^branches/'`" = "" ]; then
	parent="branches/$parent"
    fi
    echo "$parent"
}

function get_parent_revision() {
    local -r svn_url=${1:?}
    local -r svn_rev=${2:?}
    local path=${3:?}
    local -i baseline=`${svnwatch_svn} pg -r ${svn_rev} svnbranch:baseline "${svn_url}/${path}" 2>/dev/null`
    echo "$baseline"
}

function find_svnbranch_dir() {
    local -r svn_url=${1:?}
    local -r svn_rev=${2:?}
    local path=${3:?}
    local baseline
    path=`echo $path | sed 's!/.*/branches!/branches!'`
    baseline=`${svnwatch_svn} pg -r ${svn_rev} svnbranch:baseline "${svn_url}${path}" 2>/dev/null`
    while [ "$path" != "/" -a "$baseline" = "" ]; do
	path=`dirname "$path"`
	baseline=`${svnwatch_svn} pg -r ${svn_rev} svnbranch:baseline "${svn_url}${path}" 2>/dev/null`
    done
    path=`echo "${path}" | sed -e 's!^/*!!'`
    [ "`echo ${path} | grep branches/`" = "" ] && return
    echo "$path"
}

function svn_patch() {
    local -r svn_url=${1:?}
    local -r branch_path=${2:?}
    local -r branch_rev=${3:?}
    local -r parent_path=${4:?}
    local -r parent_rev=${5:?}
    svn diff  --old=${svn_url}/${parent_path}@${parent_rev} --new=${svn_url}/${branch_path}@${branch_rev}
}

function svnmkpatch() {
  declare -r module=${1:?}
  declare -r requested_revision=${2:?}

  # Local variables
  declare -r svnurl=${svnroot}/${module}

  # Initialization
  [ ! -d ${svnwatch_dir} ] && mkdir -p ${svnwatch_dir}

  # Get current revision
  declare -ri revision=`svn_actual_revision $svnurl $requested_revision`

  declare common_path
  declare svnbranch_dir
  declare svnbranch_name

  (( $verbose > 0 )) && echo "Revision ${revision}:" >&2
  (( $verbose > 0 )) && echo "Changed path:" && svn_get_changed "$svnurl" ${revision}  >&2
  (( $verbose > 0 )) && echo "Common:"  >&2
  common_path=`svn_get_changed "${svnurl}" ${revision} | find_list_common_path`
  (( $verbose > 0 )) && echo "$common_path"  >&2
  (( $verbose > 0 )) && echo "svnbranch dir:"  >&2
  svnbranch_dir=`find_svnbranch_dir "${svnurl}" "${revision}" "${common_path}"`
  svnbranch_name=`echo ${svnbranch_dir} | sed -e 's!branches/!!' -e 's!/!-!g'`
  (( $verbose > 0 )) && echo "$svnbranch_dir"  >&2
  if [ "$svnbranch_dir" != "" ]; then
    declare parent_branch=`get_parent_branch "${svnurl}" ${revision} "$svnbranch_dir"`
    declare -i parent_revision=`get_parent_revision "${svnurl}" ${revision} "$svnbranch_dir"`
    if [ "$parent_branch" != "" -a "$parent_revision" != 0 ]; then
	declare tmpfile=`mktempfile`
	mkdir -p ${svnwatch_dir}/${module}/patches/${revision}
	mkdir -p ${svnwatch_dir}/${module}/branches/${svnbranch_name}
	(cd ${svnwatch_dir}/${module}/branches/${svnbranch_name}; ln -s ../../patches/${revision} .)
	echo "Patch for $svnurl" >$tmpfile
	echo "Baseline: ${parent_branch}@${parent_revision}" >>$tmpfile
	echo "Current: ${svnbranch_dir}@${revision}" >>$tmpfile
	echo "" >>$tmpfile
	${mydir}/patch2html/svnbranch-patch -r ${revision} ${module} ${svnbranch_dir} ${svnroot} >>$tmpfile || exit 1
	(cd ${svnwatch_dir}/${module}/patches/${revision}; mv $tmpfile patch-r${revision}.patch; ${mydir}/patch2html/patch2html <patch-r${revision}.patch >patch-r${revision}.html; chmod 644 patch-r${revision}.*)
	echo "Long Patch for $svnurl" >$tmpfile
	echo "Baseline: ${parent_branch}@${parent_revision}" >>$tmpfile
	echo "Current: ${svnbranch_dir}@${revision}" >>$tmpfile
	echo "" >>$tmpfile
	${mydir}/patch2html/svnbranch-patch -l -r ${revision} ${module} ${svnbranch_dir} ${svnroot} >>$tmpfile || exit 1
	(cd ${svnwatch_dir}/${module}/patches/${revision}; mv $tmpfile patch-r${revision}.long.patch; ${mydir}/patch2html/patch2html <patch-r${revision}.long.patch >patch-r${revision}.long.html; chmod 644 patch-r${revision}.long.*)
    fi
  fi
}



function svnwatch {
  # Parameters
  declare -r module=${1:?}
  declare -r requested_revision=${2} # optional parameter

  # Directory 
  declare -r home=${HOME:?}
  declare -r svnwatch_dir=${SVNWATCH_DIR:-${home}/.svnwatch}

  # Initialization
  [ ! -d ${svnwatch_dir} ] && mkdir -p ${svnwatch_dir}

  # Read config file and per module config file
  [ -f ${svnwatch_dir}/config ] && . ${svnwatch_dir}/config
  [ -f ${svnwatch_dir}/${module}.config ] && . ${svnwatch_dir}/${module}.config

  # Environment
  declare -r svnroot=${SVNROOT:?}
  declare -r svnwatch_svn=${SVNWATCH_SVN:-svn}

  # Test tools
  $svnwatch_svn --version >/dev/null

  # If specific revision is provided, generate patch only for this one
  if [ "$requested_revision" != "" ]; then
      svnmkpatch ${module} ${requested_revision} || exit 1
      return
  fi

  # Local variables
  declare -r svnurl=${svnroot}/${module}
  declare -r svnwatch_cooky=${svnwatch_dir}/${module}.info
  declare -i i


  # Get current revision
  declare -ri current_revision=`svn_last_revision $svnurl`

  if [ ! -f ${svnwatch_cooky} ]; then
    # If it does not exist consider that the last 
    # revision is the revision - 1
    declare -i rev_
    (( rev_ = ${current_revision} - 1 ))
    echo "LAST_REVISION=$rev_" >${svnwatch_cooky}
  fi

  . ${svnwatch_cooky}

  declare -ri last_revision=${LAST_REVISION:?"LAST_REVISION not defined in ${svnwatch_dir}/${module}.info"}

  for (( i = $last_revision + 1 ; i <= $current_revision ; i++ )); do
    svnmkpatch ${module} ${i} || exit 1
    echo "LAST_REVISION=${i}" >${svnwatch_cooky}
  done

}


if [ "$1" = "test" ] ; then
    SVNWATCH_DIR=/local/dt25/svnwatch
    if [ "$userdef_module" != "" ]; then
        svnwatch ${userdef_module} ${userdef_revision}
    else
	svnwatch open64
    fi
fi


if [ "$pname" = "xtra-patch-gen_${BUILD_NUMBER}" ] ; then
    SVNWATCH_DIR=/prj/aci-storage/svnwatch
    if [ "$userdef_module" != "" ]; then
        svnwatch ${userdef_module} ${userdef_revision}
    else
	svnwatch open64                    
	svnwatch mds                       
	svnwatch stxp71archi/mmarchi               
	svnwatch svnbranch                     
	svnwatch ecc/ecl                   
	svnwatch ecc/cdt                   
	svnwatch ecc/pro                   
	svnwatch ecc/lao                   
	svnwatch embednet/pvm              
	svnwatch embednet/nightly          
	svnwatch embednet/tools            
	svnwatch embednet/elfio            
	svnwatch embednet/libffi           
	svnwatch embednet/parse.NET            
	svnwatch embednet/RL_LIB           
	svnwatch gcc4net/gcc               
	svnwatch gcc4net/binutils          
	svnwatch gcc4net/nightly           
	svnwatch lisa/mds_fe               
	svnwatch stxp70cc/stxp70-release   
	svnwatch stxp70cc/stxp70-binutils  
	svnwatch gbu           
	svnwatch binopt/binopt       
    fi
fi

## Cleaning is not done

true
