#!/bin/bash

# run-pipelines.sh

# cron:
#       /var/sdr2service/sdr2/current/bin/run-pipelines.sh {workflow} [robot_runner options]
#
# command line:
#               cd ~/sdr2/current/bin
#               echo ./run-pipelines.sh sdrIngestWF | at now

export BIN=`dirname $0`
cd $BIN

while [ `bundle exec $BIN/status_process.rb $1 start?` == "true" ] ; do
  bundle exec $BIN/robot_runner.rb "$@" \
     | egrep -v  '(^Loaded datastream|^SOLRIZER|^resetting mappings for Solrizer)' &
  sleep 20
done

