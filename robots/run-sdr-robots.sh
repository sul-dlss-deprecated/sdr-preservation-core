#!/bin/bash
# run-sdr-robots.sh

source $HOME/.bashrc
# echo $PATH

# Location of shell scripts
# http://hustoknow.blogspot.com/2011/01/what-bashsource-does.html
SHELL_SCRIPT_HOME=`dirname $BASH_SOURCE`

source ${SHELL_SCRIPT_HOME}/../.rvmrc
rvm list gemsets
# rvm info

# Location of global environment scripts
ENVIRONMENT_HOME=${SHELL_SCRIPT_HOME}/../config/environments

# Location of robot scripts
ROBOT_SCRIPT_HOME=${SHELL_SCRIPT_HOME}/sdrIngest

# The name of the current computer without the domain
HOST=`hostname -s`

# Number of Bytes in 100GB and 10GB
GB100=100000000
GB10=10000000

# Make sure a value is set for ROBOT_ENVIRONMENT
if [[ "$ROBOT_ENVIRONMENT" == "" ]]; then
    # Variable has not been previously set
    if [[ -f ${ENVIRONMENT_HOME}/${HOST}.rb ]]; then
        # using enviroment based on hostname
        ROBOT_ENVIRONMENT=${HOST}
    else
        # default is test
        ROBOT_ENVIRONMENT="test"
    fi
fi
echo "ROBOT_ENVIRONMENT = $ROBOT_ENVIRONMENT"

# WORKSPACE filesystem
if [[ "$ROBOT_ENVIRONMENT" == "test" ]]; then
    WORKSPACE=/
else
    WORKSPACE=/services-disk
fi
echo "WORKSPACE = $WORKSPACE"

function run_robot() {
    ROBOT=${1}
    ROBOT_SCRIPT=${ROBOT_SCRIPT_HOME}/${ROBOT}
    if [[ -f ${ROBOT_SCRIPT} ]]; then
        if [[ `ps -ef | grep ${ROBOT} | grep -v 'run-sdr-robots.sh' | grep -v 'grep' | wc -l` -eq 0 ]]; then
            echo "running $*"
            ruby ${ROBOT_SCRIPT_HOME}/$* &
            sleep 5
            echo ""
        else
            echo "${ROBOT} already running"
            ps -ef | grep ${ROBOT} | grep -v 'grep' 
        fi
    else
	    echo "Robot script not found: ${ROBOT_SCRIPT}"
    fi
}

function run_robot_if_space() {
    MIN_SPACE=$1
    if [[ ( "$MIN_SPACE" =~ ^[0-9]+$ ) ]]; then
        if [[ `df ${WORKSPACE} 2>/dev/null | wc -l` -gt 0 ]]; then
            FREE_SPACE=`df -k  ${WORKSPACE}| tail -1 | awk '{ print $3 }'`
            if [ $FREE_SPACE -ge  $MIN_SPACE ]; then
                shift
                run_robot $*
            else
                echo "${ROBOT} not run. Filesystem ${WORKSPACE} has dropped below ${MIN_SPACE}"
                return
            fi
        else
            echo "Not a filesystem: ${WORKSPACE}"
        fi
    else
        echo "Mininum space specification not a number: $MIN_SPACE"
    fi
}


# Run all the google robots every 100 seconds in test or 1800 seconds in prod
function run_all_robots() {
    run_robot register_sdr.rb
    run_robot_if_space $GB10 transfer_object.rb
    run_robot validate_bag.rb
    run_robot populate_metadata.rb
    run_robot verify_agreement.rb
    run_robot complete_deposit.rb
}


if  [[ "$1" != "" ]]; then
    # Make sure there is an environment script file
    if [[ -f ${ENVIRONMENT_HOME}/${ROBOT_ENVIRONMENT}.rb ]]; then
        export ROBOT_ENVIRONMENT
        kinit -k -t /var/sdr2service/sulair-lyberservices service/sulair-lyberservices && aklog
        if [[ "$1" == "all" ]]; then
            run_all_robots
        else
            run_robot $*
        fi
    else
        echo "ERROR: environment script not found - ${ENVIRONMENT_HOME}/${ROBOT_ENVIRONMENT}.rb"
    fi
fi

