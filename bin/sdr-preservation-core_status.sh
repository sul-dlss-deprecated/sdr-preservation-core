#!/bin/bash

# The ROBOT_ENVIRONMENT values here should match the
# environment files in the shared configs at
# https://github.com/sul-dlss/sdr-configs/tree/master/sdr-preservation-core/config/environments

if hostname | egrep -q '\-dev'; then
    export ROBOT_ENVIRONMENT='integration'
fi
if hostname | egrep -q '\-test|\-stage'; then
    export ROBOT_ENVIRONMENT='test'
fi
if hostname | egrep -q '\-prod'; then
    export ROBOT_ENVIRONMENT='production'
fi

echo "Using ROBOT_ENVIRONMENT=$ROBOT_ENVIRONMENT"
cd ~/sdr-preservation-core/current
bundle exec controller status
