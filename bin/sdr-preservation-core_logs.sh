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

tmp_file="/tmp/sdr_pc_tmp_$$.log"

#regex_druid='[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}'
regex_druid='[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'

for f in ${LOG_FILES}; do
    if [ -s ${f} ]; then
        echo -e "\n\n********************************************************************************"
        echo -e "LOG for $today in $f\n"
        grep ${today} ${f} | grep -v -E 'bundle/ruby|/usr/local/rvm|resque-signals' > ${tmp_file}
        if [ -s ${tmp_file} ]; then
            # Stats on DRUIDS
            cat ${tmp_file} | sed -n -r -e "/$regex_druid/s/.*($regex_druid).*/\1/p" | sort -u > /tmp/sdr_pc_druids.log
            druid_count=$(cat /tmp/sdr_pc_druids.log | wc -l)
            echo
            echo "DRUID count: $druid_count"
            echo
            echo "Log tail for $today:"
            echo
            tail -n${tailN} ${tmp_file}
        else
            echo
            echo "No activity today; latest activity was:"
            echo
            tail -n${tailN} ${f}
        fi
    else
        echo -e "\n********************************************************************************"
        echo -e "EMPTY: $f"
    fi
done

rm /tmp/sdr_pc*
echo
echo

