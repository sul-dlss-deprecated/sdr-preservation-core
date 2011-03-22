#!/bin/bash

# Reorganizes druid-named bagit objects from flat storage to a druidTree hierarchy

# The directory to be reorganized
WORKSPACE=$1

for MEMBER in `ls $WORKSPACE`; do
    # make sure the child object has a druid name beginning with a pattern like druid:ab123cd4567
    if [[ $MEMBER =~ ^(druid):([a-z]{2})([0-9]{3})([a-z]{2})([0-9]{4}) ]]; then
        druidTree=$WORKSPACE/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}
        mkdir -p $druidTree
        mv $WORKSPACE/$MEMBER $druidTree
    fi
done