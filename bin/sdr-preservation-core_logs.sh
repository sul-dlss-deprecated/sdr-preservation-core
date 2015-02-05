#!/bin/bash

if [ "$1" != "" ]; then
	tailN=$1
else
	tailN=40
fi

cd

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
		echo -e "$f\n"
		grep $today $f | grep -v -E 'bundle/ruby|/usr/local/rvm|resque-signals' > /tmp/sdr_today_tmp.log
		druid_count=$(cat /tmp/sdr_today_tmp.log | sed -e 's/.*\(druid:...........\).*/\1/' | sort -u | wc -l)
		echo "DRUID COUNT:  $druid_count "
		echo "LOG TAIL:"
		echo
		tail -n$tailN /tmp/sdr_today_tmp.log
	else
		echo -e "\n********************************************************************************"
		echo -e "EMPTY: $f"
	fi
done

rm /tmp/sdr_today_tmp.log
echo
echo

