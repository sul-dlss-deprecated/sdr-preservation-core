#!/bin/bash
# test-run-robot-script.sh

source `dirname $0`/run-sdr-robots.sh

echo APP_HOME = $APP_HOME
echo ENVIRONMENT_HOME  = $ENVIRONMENT_HOME
echo ROBOT_SCRIPT_HOME = $ROBOT_SCRIPT_HOME
echo WORKSPACE         = $WORKSPACE
echo HOST              = $HOST
echo ROBOT_ENVIRONMENT = $ROBOT_ENVIRONMENT

run_robot fake.rb
run_robot dummy.rb a b c
run_robot dummy.rb
sleep 10
run_robot_if_space GB10 dummy.rb
GB10000=10000000000
run_robot_if_space $GB10000 dummy.rb
run_robot_if_space $GB10 dummy.rb
WORKSPACE=/abc
run_robot_if_space $GB10 dummy.rb

`dirname $0`/run-sdr-robots.sh dummy.rb
