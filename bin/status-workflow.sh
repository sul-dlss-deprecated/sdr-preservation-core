#!/bin/bash

printf '\n======== WORKFLOW COUNTS    ==========\n'
WORKFLOW_COUNT=~/sdr2/robots//workflow-count.sh
${WORKFLOW_COUNT} 'completed=register-sdr'
${WORKFLOW_COUNT} 'waiting=transfer-object&completed=register-sdr'
${WORKFLOW_COUNT} 'waiting=validate-bag&completed=transfer-object'
${WORKFLOW_COUNT} 'waiting=populate-metadata&completed=validate-bag'
${WORKFLOW_COUNT} 'waiting=verify-agreement&completed=populate-metadata'
${WORKFLOW_COUNT} 'waiting=complete-deposit&completed=verify-agreement'
${WORKFLOW_COUNT} 'completed=complete-deposit'

echo ''
echo '======== PROCESSES =========='
ps -ef | grep ruby | grep -v grep
echo ''
