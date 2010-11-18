#!/bin/bash
# run-sdr-robots.sh
ROBOT_ENVIRONMENT=${1:-test}
SDR2_OBJECTS=${2:-"/var/sdr2objects"}
# ROBOT_DIRECTORY=${3:-sdrIngest}

# Test if previous invocation of a script is still active
function robot_running() {
    robot=$1
    echo  `ps -ef | grep ${robot}.rb | grep -v 'grep' | wc -l`
}

# Test available free disk space
function workspace_free() {
    # On Linux print $3 to get available space
    # On Mac print $4 to get available space

    echo `df -k ${SDR2_OBJECTS} | tail -1 | awk '{ print $3 }'`
    #echo `df -k ${SDR2_HOME}/sdr2/sdr2_example_objects  | tail -1 | awk '{ print $3 }'`
}


# Run all the google robots
function run_all_robots() {

    kinit -k -t /var/sdr2service/sulair-lyberservices service/sulair-lyberservices && aklog

    (cd ${SDR2_HOME}/sdr2/robots/sdrIngest ;
	echo cwd=`pwd`
    robot="register_sdr"
    if [ `robot_running $robot` -eq 0 ]; then
        echo "running $robot"
        echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot 
        sleep 5
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""

    robot="transfer_object"
    GB100=100000000
    GB10=10000000
    if [ `robot_running $robot` -eq 0 ]; then
        if [ `workspace_free` -gt  ${GB10} ]; then
            echo "running $robot"
            echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot &
             sleep 5
        else
            echo "$robot" not run
            echo "Available free workspace has dropped below 100 GB"
        fi
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""

    robot="validate_bag"
    if [ `robot_running $robot` -eq 0 ]; then
        echo "running $robot"
        echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot &
        sleep 5
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""

    robot="populate_metadata"
    if [ `robot_running $robot` -eq 0 ]; then
	echo "running $robot"
        echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot &
        sleep 5
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""

    robot="verify_agreement"
    if [ `robot_running $robot` -eq 0 ]; then
	echo "running $robot"
        echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot &
        sleep 5
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""

    robot="complete_deposit"
    if [ `robot_running $robot` -eq 0 ]; then
	echo "running $robot"
        echo_execute ../run-robot.sh $ROBOT_ENVIRONMENT $robot &
        sleep 5
    else
        echo "$robot already running"
        ps -ef | grep $robot
    fi
    echo ""
    )
}

function echo_execute() {
  echo
  echo "*************************  Executing: $@  "
  echo "AT : `date`"
  # Uncomment on Mac
  #$@
  # Comment this on Mac - time -f not supported
  # Supported on Linux
  /usr/bin/time -f 'Time elapsed = %E' $@
  result=$?
  echo "Completed at: `date`"
  return $result
}

# run script every 3 minutes
while [ 0 ]
do
timestamp=`date +%Y%m%d_%H%M%S`
run_all_robots 
#mail -s "run-sdr-robots $timestamp" alpana@stanford.edu
echo "RELAUNCH ROBOTS after 100 seconds ..."
sleep 100
done
