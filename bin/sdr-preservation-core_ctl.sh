#!/bin/bash

if [ -d ~/sdr-preservation-core/current ]; then
    cd ~/sdr-preservation-core/current
else
    echo "ERROR: There is no application installation in ~/sdr-preservation-core/current"
    exit 1
fi


# ----
# The ROBOT_ENVIRONMENT values here should match the config/environment/* files in the shared configs at
# https://github.com/sul-dlss/shared_configs/tree/sdr-preservation-core_{stage} where
# {stage} is a capistrano stage, like 'dev|stage|prod'.

HOSTNAME=$(hostname -s)
case "$HOSTNAME" in
    'sul-sdr-services')
        export ROBOT_ENVIRONMENT='production'
        ;;

    'sdr-services-test' | 'sdr-services-test2')
        export ROBOT_ENVIRONMENT='stage'
        ;;

    'sul-sdr-services-dev')
        export ROBOT_ENVIRONMENT='integration'
        ;;

    *)
        echo "WARNING: defaulting to localhost 'development'"
        export ROBOT_ENVIRONMENT='development'
        ;;
esac

echo "Using ROBOT_ENVIRONMENT=$ROBOT_ENVIRONMENT"


# ----
# Robot control commands:

case "$1" in
    start)
        bundle exec controller boot
        ;;

    stop)
        bundle exec controller stop
        bundle exec controller quit
        ;;

    status)
        bundle exec controller status
        ;;

    restart)
        bundle exec controller stop
        bundle exec controller quit
        bundle exec controller boot
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
esac

