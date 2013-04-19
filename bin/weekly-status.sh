#!/bin/bash
export BIN=`dirname $0`
cd $BIN
status='/tmp/sdr-weekly-status-report.txt'
./bundle-exec.sh status_workflow.rb sdrIngestWF summary > $status
./bundle-exec.sh status_storage.rb | grep -v 'Production Status' >> $status
cat $status | mail -s 'SDR Weekly Production Report' sdr-discuss@lists.stanford.edu