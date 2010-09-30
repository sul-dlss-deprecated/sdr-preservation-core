#!/bin/sh
ROBOT_ENVIRONMENT=${1:-test}
export ROBOT_ENVIRONMENT
ROBOT=$2

if [[ $# -gt 0  && -f ${ROBOT}.rb ]]
then
	timestamp=`date +%Y%m%d_%H%M%S`
	robot=${ROBOT}.rb
	logdir=${HOME}/log
	mkdir -p $logdir
	logfile=${logdir}/${ROBOT}_${timestamp}.log
	shift
	shift
	echo "running robot $ROBOT with env = $ROBOT_ENVIRONMENT "
	ruby $robot $* 2>&1 | tee $logfile 
	mail -s $logfile alpana@stanford.edu < $logfile
else
	echo "you must specify a ruby script name (without the .rb extension)"
	exit
fi
