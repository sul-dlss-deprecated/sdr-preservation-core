#!/bin/bash

# https://consul.stanford.edu/display/DLSSINFRAAPP/SUL+Statistics
# http://graphite.readthedocs.org/en/latest/feeding-carbon.html
# https://rubygems.org/gems/graphite
# https://github.com/otherinbox/graphite

#echo "222222" | awk '{ printf "sul-sdr.objects.count:%s|g", $1 }' >
# /dev/udp/sulstats.stanford.edu/8125
#
# (There's also a ruby library for pushing data, if that'd be better..)
#
# And that data will appear:
#
# sulstats-raw.stanford.edu—render
# <http://sulstats-raw.stanford.edu/render/?width=586&height=308&_salt=1362678496.494&target=stats.gauges.sul-sdr.objects.count&lineMode=connected&areaMode=stacked&from=-24hours>
#
# Until we can promote it into a permanent graph at
# sulstats.stanford.edu—graphs <https://sulstats.stanford.edu/graphs>
# or onto the radiator.

export BIN=`dirname $0`
cd $BIN
objects=`./bundle-exec.sh status_workflow.rb sdrIngestWF archived | cut -f3 -d' '`
terabytes=`./bundle-exec.sh status_storage.rb terabytes | cut -f3 -d' '`
timestamp=`date +%s`
echo "stats.sdr.preservation.objects $objects $timestamp" | nc sulstats.stanford.edu 2003
echo "stats.sdr.preservation.terabytes $terabytes $timestamp" | nc sulstats.stanford.edu 2003
