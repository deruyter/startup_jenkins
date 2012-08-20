#!/usr/bin/env bash
##############################################################################
##
## Name : get_toolset_path.sh
##
## Desc : 
##
##############################################################################


# Safe checks
[ "x$module" != "xgcc" -a "x$module" != "xopen64" ] && error "module should be either gcc or open64"
[ "x$target" != "x" ] || error "need to know the target (st40, arm, st200, stxp70, stxp70v4, ..)"
[ "x$build_host" == "xlinux" ] || error "only supports linux projects for the moment"
[ "x$branch" != "x" ] || error "need to specify one branch"
[ "x$WORKSPACE" != "x" ] || error "WORKSPACE is not set by hudson.. might be a problem somewhere"

# get revision out of sources dir
[ "x$module" == "xgcc" ] && svn_src_dir=${WORKSPACE}/gcc-src
[ "x$module" == "xopen64" ] && error "No location specified for source repository"
[ -d ${svn_src_dir} ] || error "WORKSPACE doesnot contain gcc-src directory"
rev=`svn info ${svn_src_dir} | grep "Last Changed Rev" | cut -d' ' -f4`

# branch name
d_branch=`echo ${branch} | sed 's![^_a-zA-Z0-9]!-!g'`

echo "/work/aci-cec/aci/results/compilers/hudson-${module}-${build_host}-${d_branch}-${rev}/${target}/toolset"
