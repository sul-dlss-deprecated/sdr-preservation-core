#!/bin/bash

WORKFLOW="repository=sdr&workflow=sdrIngestWF&"
CERTHOME=~/sdr2/config/certs

if [[ `hostname | grep -c 'sdr-services'` -eq 1 ]]; then
    export HOSTENV='prod'
elif [[ `hostname | grep -c 'sdr-services-test'` -eq 1 ]]; then
    export HOSTENV='test'
else
     export HOSTENV='dev'
fi

QUERY=$1
QTYPE=`echo $QUERY | cut -f1 -d'&' | cut -f1 -d'='`
STEP=`echo $QUERY | cut -f1 -d'&' | cut -f2 -d'='`

WORKURL="https://lyberservices-${HOSTENV}.stanford.edu/workflow/workflow_queue?count-only=true&${WORKFLOW}"
QUEUEURL="${WORKURL}${QUERY}"

CERT=${CERTHOME}/ls-${HOSTENV}.crt
KEY=${CERTHOME}/ls-${HOSTENV}.key
PW=ls${HOSTENV}
CURLBASE="curl -s --cert ${CERT}:${PW} --key ${KEY}"

COUNT=`${CURLBASE} ${QUEUEURL} | cut -f2 -d'"'`
printf "%7i %s %s\n" ${COUNT} ${QTYPE} ${STEP}
