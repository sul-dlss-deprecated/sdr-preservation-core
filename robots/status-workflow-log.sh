#!/bin/bash

function queue_size() {
	WORKFLOW_COUNT=~/sdr2/robots/workflow-count.sh
	${WORKFLOW_COUNT} "$1" | sed -s 's/^ *//'| cut -f1 -d' '
}

transfer=`queue_size 'waiting=transfer-object&completed=register-sdr'`
validate=`queue_size 'waiting=validate-bag&completed=transfer-object'`
populate=`queue_size 'waiting=populate-metadata&completed=validate-bag'`
agreement=`queue_size 'waiting=verify-agreement&completed=populate-metadata'`
complete=`queue_size 'waiting=complete-deposit&completed=verify-agreement'`

if [[ ! -s ~/log/queue.log ]]; then 
printf '%s|%s|%s|%s|%s|%s\n' "Date" "transfer-object" "validate-bag" "populate-metadata" "verify-agreement" "complete-deposit" >> ~/log/queue.log
fi
printf '%s|%s|%s|%s|%s|%s\n' `date +'%FT%R'` $transfer $validate $populate $agreement $complete >> ~/log/queue.log
