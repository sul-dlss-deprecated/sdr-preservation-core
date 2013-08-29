#!/bin/bash

# path to a bagit object in the druidTree hierarchy

# $ echo druid:bm331mh9283 | druid-path.sh
# /services-disk/sdr2objects/deposit-complete/2010-11-18/druid:bm331mh9283

# $ echo druid:bb540rw7236 | druid-path.sh
# /services-disk/sdr2objects/druid/bb/540/rw/7236/druid:bb540rw7236

# cat test-druids | druid-path.sh
# /services-disk/sdr2objects/deposit-complete/2010-11-18/druid:bm331mh9283
# /services-disk/sdr2objects/druid/bb/540/rw/7236/druid:bb540rw7236


while read DRUID; do
    # skip blank lines
    if [[ "x$DRUID" == "x" ]]; then
      continue
    fi
    ID=${DRUID#*:}
    druidTree=`echo $ID | awk '{ print substr($0,1,2)"/"substr($0,3,3)"/"substr($0,6,2)"/"substr($0,8,4) }'`
    for WORKSPACE in `ls -rd /services-disk*/sdr2objects`;do
        # current SDR storage
        dpath=$WORKSPACE/$druidTree/$ID
        #echo $dpath
        if [[ -d $dpath ]]; then
            break
        fi
        # previous SDR storage
        dpath=$WORKSPACE/druid/$druidTree/$ID
        #echo $dpath
        if [[ -d $dpath ]]; then
            break
        fi
        # ancient SDR storage
        cpath=$WORKSPACE/deposit-complete.toc
        if [[ -f $cpath ]]; then
            dpath=$WORKSPACE/`grep $DRUID $cpath`
            #echo $dpath
            if [[ "$dpath" != "$WORKSPACE/" && -d "$dpath"  ]]; then
                break
            fi
        fi
    done
    if [[ "$dpath" != "$WORKSPACE/" && -d $dpath ]]; then
        echo $dpath
    else
        echo $DRUID not found
    fi
done
