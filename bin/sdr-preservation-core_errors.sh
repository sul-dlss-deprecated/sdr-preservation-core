#!/bin/bash

LOG_PATH="${HOME}/sdr-preservation-core/shared/log"
LOG_FILES=$(cat <<FILENAMES
	${LOG_PATH}/sdr_sdrIngestWF_register-sdr.log
	${LOG_PATH}/sdr_sdrIngestWF_transfer-object.log
	${LOG_PATH}/sdr_sdrIngestWF_validate-bag.log
	${LOG_PATH}/sdr_sdrIngestWF_verify-agreement.log
	${LOG_PATH}/sdr_sdrIngestWF_complete-deposit.log
	${LOG_PATH}/sdr_sdrIngestWF_update-catalog.log
	${LOG_PATH}/sdr_sdrIngestWF_create-replica.log
	${LOG_PATH}/sdr_sdrIngestWF_ingest-cleanup.log
FILENAMES
)

today=$(date +%Y-%m-%d)

for f in $LOG_FILES; do
	if [ -s $f ]; then
		echo -e "\n\n********************************************************************************"
		echo -e "ERRORS TODAY in $f\n"
		grep -B1 -F 'ERROR' $f | grep $today
	else
		echo -e "\n********************************************************************************"
		echo -e "EMPTY: $f"
	fi
done
for f in $LOG_FILES; do
	if [ -s $f ]; then
		echo -e "\n\n********************************************************************************"
		echo -e "WARNINGS TODAY in $f\n"
		grep -F 'WARN' $f | grep -v 'resque-signals' | grep $today
	fi
done
echo
echo

