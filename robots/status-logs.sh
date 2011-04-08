#!/bin/bash

PROJECT=sdr2
# ROBOTLIST="register-sdr transfer-object validate-bag populate-metadata verify-agreement complete-deposit"
ROBOTLIST="transfer-object validate-bag populate-metadata verify-agreement complete-deposit"
LOGDIR=~/log
WORKSPACE="/services-disk"
NOTIFY=rnanders@stanford.edu

cd ${LOGDIR}
mkdir -p status
rptout=status/report
errall=status/errors.all
errold=status/errors.old
errnew=status/errors.new
offsetdate=status/offset.date

function reset_offsets() {
    for robot in $ROBOTLIST ; do
        log=${robot}.log
        offset=1
        size=0
        if [[ -s $log ]]; then
           offset=`cat $log | wc -l`
        fi
        echo $offset > status/${robot}.offset
        echo $size   > status/${robot}.size
    done
    cat /dev/null > $errold
    now=`date +'%F %R'`
    echo "$now" > $offsetdate
}

function report_activity() {
    cat /dev/null > $rptout
    cat /dev/null > $errall
    then=`cat $offsetdate`
    now=`date +'%F %R'`
    printf "Robot activity between\n$then\n$now\n" >> $rptout

    printf "\n======== WORKSPACE ==========\n\n" >> $rptout
    df -hP $WORKSPACE | column -t  >> $rptout

    printf "\n======== LOGS ==========\n\n" >> $rptout
    printf "%-16s %10s %10s  %s\n" "Date" "Success" "Error" "Robot" >> $rptout
    for robot in $ROBOTLIST ; do
        log=${robot}.log
        if [[ -s $log ]]; then
            logsize=`stat -c '%s' $log`
            oldsize=`cat status/${robot}.size`
            # echo "log= $log logsize=$logsize oldsize=$oldsize"
            if [[ $logsize -gt $oldsize ]]; then
                logdate=`stat -c '%y' $log | cut -f1,2 -d':'`
                offset=`cat status/${robot}.offset`
                success=`sed -n "$offset,$"p $log | grep -c 'completed in'`
                error=`sed -n "$offset,$"p $log | grep -c 'set to error for'`
                sed -n "$offset,$"p $log | egrep '(ERROR|FATAL)' > status/${robot}.errors
                printf "%-16s %10d %10d  %s\n" "$logdate" "$success" "$error" "$robot" > status/${robot}.counts
                echo $logsize > status/${robot}.size
    		fi
            cat status/${robot}.counts >> $rptout
            cat status/${robot}.errors >> $errall
        fi
	done
    comm -23 $errall $errold >> $errnew
    if [[ `cat $errnew | wc -l` -gt 0 ]]; then
       printf "\n======== ERROR DETAIL ==========\n\n" >> $rptout
       tail -1 $errnew >> $rptout
    fi
}

function report_to_screen() {
    tty -s
    if [[ $? -gt 0 ]]; then
       echo "status-logs.sh screen error: Not an interactive session"
       exit
    fi
    while [[ "1" == "1" ]]; do
        report_activity
        clear
        cat $rptout
        sleep 60
    done
}

function report_to_email() {
    report_activity
    cat $rptout | mail -s "${PROJECT} Robot Status" $NOTIFY
    if [[ -s $errnew ]]; then
       cat $errnew  | mail -s "${PROJECT} Robot Error Detail" $NOTIFY
       cp $errall $errold
    fi
}

if [[ "$1" == "screen" ]]; then
   report_to_screen
elif [[ "$1" == "email" ]]; then
   report_to_email
elif [[ "$1" == "reset" ]]; then
   reset_offsets
fi
