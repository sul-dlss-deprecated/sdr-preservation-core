#!/bin/bash

export KRB5CCNAME=/tmp/sdr-kerb5.tkt

# -U the service principal will be taken from the first entry in the keytab.
# -f The location of the keytab file
# -b detach from the controlling terminal and run in thebackground.
# -K minutes between checks on ticket expiration

/usr/bin/k5start -U -f /var/sdr2service/sulair-lyberservices -b -K 20 "$@"

