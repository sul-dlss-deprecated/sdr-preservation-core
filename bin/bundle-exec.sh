#!/bin/bash

# bundle-exec.sh

# used to call a program by changing to the program's containing directory,
# then invoking the program using "bundle exec"

export BIN=`dirname $0`
cd $BIN
bundle exec $BIN/"$@"

