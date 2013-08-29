#!/bin/bash
export BIN=`dirname $0`
cd $BIN
objects=`./bundle-exec.sh status_workflow.rb sdrIngestWF archived | cut -f3 -d' '`
terabytes=`./bundle-exec.sh status_storage.rb terabytes | cut -f3 -d' '`
timestamp=`date +%s`
echo "stats.sdr.preservation.objects $objects $timestamp" | nc sulstats.stanford.edu 2003
echo "stats.sdr.preservation.terabytes $terabytes $timestamp" | nc sulstats.stanford.edu 2003