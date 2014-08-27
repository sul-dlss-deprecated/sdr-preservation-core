#!/bin/bash

if hostname | grep -q '\-test'; then
    export ROBOT_ENVIRONMENT=staging
fi

cd ~/sdr-preservation-core/current
bundle exec controller stop
bundle exec controller quit
bundle exec controller boot

