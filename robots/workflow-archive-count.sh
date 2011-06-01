#!/bin/bash

CERTHOME=~/sdr2/config/certs

if [[ `hostname | grep -c 'sdr-services'` -eq 1 ]]; then
    export HOSTENV='prod'
elif [[ `hostname | grep -c 'sdr-services-test'` -eq 1 ]]; then
    export HOSTENV='test'
else
     export HOSTENV='dev'
fi

URL="https://lyberservices-${HOSTENV}.stanford.edu/workflow/workflow_archive?repository=sdr&workflow=sdrIngestWF&count-only=true"

CERT=${CERTHOME}/ls-${HOSTENV}.crt
KEY=${CERTHOME}/ls-${HOSTENV}.key
PW=ls${HOSTENV}
CURLBASE="curl -s --cert ${CERT}:${PW} --key ${KEY}"

COUNT=`${CURLBASE} ${URL} | cut -f2 -d'"'`
echo ${COUNT} 
