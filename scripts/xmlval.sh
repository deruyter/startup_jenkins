#!/bin/sh

# configuration part
NSGMLS=/apa/gnu/Linux/bin/onsgmls
SGML_DIR=${SGML_DIR-/apa/comp/sgml}
REF_SGML_DIR=/apa/comp/sgml
#
SGML_CATALOG_FILES=$SGML_DIR/catalog:$REF_SGML_DIR/catalog:$SGML_CATALOG_FILES
export SGML_CATALOG_FILES

ignore=0 # if set ignores public identifier
options=
while [ $# != 0 ]
do
    opt=$1
 
    case $opt in
        -i) ignore=1
            shift;;
	-*)
           options="$options $opt"
           shift;;
        *) break;;
    esac
done
SP_ENCODING=XML
SP_CHARSET_FIXED=YES
export SP_ENCODING
export SP_CHARSET_FIXED
 
for file in $*
do 
$NSGMLS $options -s -wxml $SGML_DIR/dcl/xml.dcl $file 2>&1 | sed '/declaration was not implied/d'
done

