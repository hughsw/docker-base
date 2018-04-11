#!/bin/bash -eu

# Yell on unexepected pain
set -eu
set -o pipefail
trap 'rc=$?;set +x;if [ $rc -ne 0 ];then trap - ERR EXIT INT;echo;echo;echo "*** fail *** : code $rc : $0";echo;exit $rc;fi' ERR EXIT INT

HOST=$1
PORT=$2
TIMEOUT=${3:-100}


DELAY=3

isListening () {
  if nc -z $HOST $PORT >/dev/null 2>&1 ; then echo yes ; else echo no ; fi
}

getSec () {
  cat /proc/uptime | awk -F . '{print $1}'
}
START=$(getSec)
getElapsed () {
  echo $(($(getSec) - $START))
}


while [ $(getElapsed) -lt $TIMEOUT -a $(isListening) != yes ] ; do sleep $DELAY && echo . ; done

isAlive=$(isListening)
echo $HOST $PORT listening=$isAlive
[ "$isAlive" = yes ]
