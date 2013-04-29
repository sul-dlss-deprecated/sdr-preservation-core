#!/bin/bash

# run-pipelines.sh

# cron:
#       /var/sdr2service/sdr2/current/bin/run-pipelines.sh {workflow} [robot_runner options]
#
# command line:
#               cd ~/sdr2/current/bin
#               echo ./run-pipelines.sh {sdrIngestWF|sdrMigrationWF|sdrRecoveryWF} | at now

# exit the script if simple command fails
set -e

export BIN=`dirname $0`
cd $BIN

# exit the loop below if any of the commands in the pipeline fail
set -o pipefail

while [ `bundle exec $BIN/status_process.rb $1 start?` == "true" ] ; do
  bundle exec $BIN/robot_runner.rb "$@" \
     | egrep -v  '(^Loaded datastream|^SOLRIZER|^resetting mappings for Solrizer)' &
  sleep 20
  # Test whether last forked background process is still running
  kill -0 $!
done

