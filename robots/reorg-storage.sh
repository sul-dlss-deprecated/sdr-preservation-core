#!/bin/bash

# Reorganizes druid-named bagit objects from flat storage to a druidTree hierarchy

# The directory to be reorganized
WORKSPACE=$1

# Bash > 3.2 supports pattern match with capture groups.  sdr-thumper2 has bash 3.0
# for MEMBER in `ls $WORKSPACE`; do
#    # make sure the child object has a druid name beginning with a pattern like druid:ab123cd4567
#    if [[ $MEMBER =~ ^(druid):([a-z]{2})([0-9]{3})([a-z]{2})([0-9]{4}) ]]; then
#        druidTree=$WORKSPACE/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}
#        mkdir -p $druidTree
#        mv $WORKSPACE/$MEMBER $druidTree
#    fi
# done

# More generic mechanism using AWK
PATTERN='druid:[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]'
for MEMBER in `ls $WORKSPACE`; do
    BASE=`echo $MEMBER | cut -c1-17`
    # make sure the directory entry has a druid name beginning with a pattern like druid:ab123cd4567
    if [[ $BASE =~ $PATTERN ]]; then
        #echo matched $MEMBER
        druidTree=$WORKSPACE/druid/`echo $BASE | cut -c7-17 | awk '{ print substr($0,1,2)"/"substr($0,3,3)"/"substr($0,6,2)"/"substr($0,8,4) }'`
        #echo $druidTree
        mkdir -p $druidTree
        mv $WORKSPACE/$MEMBER $druidTree
        ls -d $druidTree/$MEMBER
    fi
done

