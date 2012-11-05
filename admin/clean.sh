#!/bin/sh
#
# usage: clean.sh <project>
#
# Clean hudson/jenkins project files for <project>
# If <project> is one of:
# -all: clean all hudson/jenkins projects (logs and artifacts)
# -log: clean only hudson/jenkins logs
#
# parameters:
# ACI_ROOT_DIR: root of jenkins project
#

set -e
[ "$DEBUG" = "" ] || set -x

dir=`dirname $0`
dir=`cd $dir; pwd`
project=$1
DEF_ACI_ROOT_DIR=`readlink -f $dir/..`
[ "x$ACI_ROOT_DIR" = "x" ] && ACI_ROOT_DIR=$DEF_ACI_ROOT_DIR

if [ "x$project" = "x" ]; then
  echo "missing project name argument or option (-all) (-log)" >&2
  exit 1
fi

cd $ACI_ROOT_DIR
if [ "x$project" = "x-all" ]; then
  rm -rf *.log artifacts logs
  echo "Cleaned up all Hudson projects."
else
  if [ "x$project" = "x-log" ]; then
    rm -f hudson.log.* jenkins.log.*
    [ -f hudson.log ] && mv hudson.log hudson.log.bak
    [ -f jenkins.log ] && mv jenkins.log jenkins.log.bak
    echo "Cleaned up all logs. Last log backed up in *.log.bak"
  fi
fi
