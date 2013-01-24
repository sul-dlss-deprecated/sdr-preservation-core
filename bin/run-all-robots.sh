#!/bin/bash
# run-all-robots.sh

# Ensure that only one copy of the program is running
SCRIPT=`basename $BASH_SOURCE`
if [[ `pgrep $SCRIPT | wc -l` -gt 1 ]]; then
  echo "Only one copy of this script can be run at one time"
  exit
fi

# Location of shell scripts
# http://hustoknow.blogspot.com/2011/01/what-bashsource-does.html
BIN_DIR=`dirname $BASH_SOURCE`
APP_HOME=`dirname $BIN_DIR`

# The name of the current computer without the domain
HOST=`hostname -s`
echo "HOST = $HOST"

# Make sure a value is set for ROBOT_ENVIRONMENT
if [[ "$ROBOT_ENVIRONMENT" == "" ]]; then
    if [[ ${HOST} == "sdr-services" ]]; then
        export ROBOT_ENVIRONMENT='production'
    elif [[ ${HOST} == "sdr-services-test" ]]; then
        export ROBOT_ENVIRONMENT='test'
    else
        export ROBOT_ENVIRONMENT='development'
    fi
fi
echo "ROBOT_ENVIRONMENT = $ROBOT_ENVIRONMENT"

kinit -k -t /var/sdr2service/sulair-lyberservices service/sulair-lyberservices && aklog

cd $BIN_DIR; bundle exec $BIN_DIR/run-all-robots.rb "$@"