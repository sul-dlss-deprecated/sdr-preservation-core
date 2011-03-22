#!/bin/sh

timestamp=`date +%Y%m%d_%H%M%S`
logdir=~/log
errordir=${logdir}/errors
errorfile=${errordir}/SDRErrors_${timestamp}
mkdir -p $errordir
grep -r Error ${logdir} | grep -v "Errors: 0" >  ${errorfile}
mail -s "SDRErrors-${timestamp}" alpana@stanford.edu < ${errorfile}
