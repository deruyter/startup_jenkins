#!/usr/bin/env bash
#
# usage: archive_tgz.sh file.tgz ...
#
# Does a tar/gzip archive of the given arguments into file.tgz.
#
# Parameters through envvars:
# GZIP="gzip command": gzip command to use [default: "gzip --fast"]
# NICE=<nice_value>: nice value (for gzip) or 0 for no nice [default: 10]
# DEBUG=0|1: DEBUG (set -x) mode
# 
set -e

[ "$DEBUG" = "" ] || set -x
 
# Command line
outfile="${1:?}"
shift

# Parameters
NICE="${NICE:-10}"
GZIP="${GZIP:-gzip --fast}"
TAR="${TAR:-tar}"

[ "$NICE" = 0 ] || NICE_COMMAND="nice -n $NICE"

rm -f "${outfile}"
${TAR} cf - ${1+"$@"} | ${NICE_COMMAND} ${GZIP} -c - > "${outfile}"
exit ${PIPESTATUS[0]} # return left side of pipe status, right side errors are handled by set -e

