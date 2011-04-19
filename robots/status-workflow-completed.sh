#!/bin/bash

# Script to report
# (1) total number of objects that have gone through the SDR workflow successfully
# (2) total size of all objects in the storage area

# Number of objects
WORKFLOW_COUNT=~/sdr2/robots/workflow-count.sh
OBJECT_COUNT=`${WORKFLOW_COUNT} 'completed=complete-deposit' | sed -s 's/^ *//'| cut -f1 -d' '`

# Size of storage area
WORKSPACE="/services-disk"
STORAGE_KB=`df -P $WORKSPACE | tail -1 | cut -f3 -d' '`
STORAGE_TB=`echo "scale=3;${STORAGE_KB}/1000000000" | bc`

# Output the report
echo "SDR Production Report - `date +'%F %R'`"
echo "======================================================================"
echo "${OBJECT_COUNT} = Total number of bags deposited successfully"
echo   "${STORAGE_TB} = Total size of successful deposits in Terabytes"

