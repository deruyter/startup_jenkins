#!/bin/sh
# this script should be sourced, not executed

error() {
if [ "x$cruisecontrol" = "x1" ]; then
    info_xml=$cruisecontroldir/error.xml
    echo " <testsuite name=\"$0\" tests=\"2\" " > $info_xml
    echo "  failures=\"1\" errors=\"1\" time=\"0\">   " >> $info_xml
    echo "     <testcase name=\"$0\"  time=\"0\">" >> $info_xml
    echo "       <failure >">> $info_xml
    echo "[validfailed]ERROR in $0: $1" >> $info_xml
    echo "</failure>">> $info_xml
    echo "    </testcase> ">> $info_xml
    echo "   </testsuite> ">> $info_xml
    # Archive log file if any
    [ "$logfile" != "" ] && cp $logfile $artifactspublisherdir/

else
    echo "ERROR: $0: $1"
fi
    exit 1
}

while [ $# != 0 ]
do
    case $1 in
    *=*)
	var_="`echo $1 | sed 's/=.*//'`"
	value_="`echo $1 | sed 's/[^=]*=//'`"
	eval $var_=\"$value_\"
	eval export $var_
	;;
    *)
	break
	;;
    esac

    shift
done
# Ensure $USER is set
true ${USER:=$LOGNAME}
export USER

