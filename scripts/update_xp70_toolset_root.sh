#!/bin/sh

update_files () {
    BASE=$1
    cat ${BASE}.sh | sed -e "s#SX=.*;#SX=${TOOLSET};#" > ${BASE}.sh.$$
    mv ${BASE}.sh.$$ ${BASE}.sh
    chmod a+r ${BASE}.sh

    cat ${BASE}.csh | sed -e "s#setenv SX .*#setenv SX ${TOOLSET}#" > ${BASE}.csh.$$
    mv ${BASE}.csh.$$ ${BASE}.csh
    chmod a+r ${BASE}.csh
}


OLDPWD=`pwd`

if [ $# -eq 0 ]
then
    TOOLSET=`pwd`
else
    LOCALTS=$1
    OLDPWD=`pwd`
    cd $LOCALTS
    TOOLSET=`pwd`
    cd $OLDPWD
    shift
fi

cd ${TOOLSET}


if [ -r configure ]
then
    ./configure
else 
    cd ${TOOLSET}/bin
    if [ -r STxP70.sh ] ; then
	update_files STxP70
    fi
    
    if [ -r STxP70_v3.sh ] ; then
	update_files STxP70_v3
    fi
    
    if [ -r STxP70_v4.sh ] ; then
	update_files STxP70_v4
    fi
    echo "path=${TOOLSET}/stworkbench_extension" > ${TOOLSET}/stworkbench/links/stxp70.link

#    cat ${TOOLSET}/sxext/stxp70extrc | sed -e "s#/.*/sxext#${TOOLSET}/sxext#g" >  ${TOOLSET}/sxext/stxp70extrc.new
#    mv ${TOOLSET}/sxext/stxp70extrc.new ${TOOLSET}/sxext/stxp70extrc

    echo File STxP70*.sh and STxP70*.csh updated to new SX ${TOOLSET}
fi

cd ${OLDPWD}
