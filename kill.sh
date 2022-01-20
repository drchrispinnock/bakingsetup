#!/bin/bash

# Stop a baking setup. 
# Chris Pinnock 2022
# MIT license
#

# Defaults - override in the configuration file (shell)
#
piddir=/tmp

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

if [ `whoami` != $username ]; then
        echo "Must be run by $username"
        exit 3;
fi

source $1

if [ -z "$name" ]; then
	echo "I need name set"
	exit 1
fi

pidfilebase=$piddir/_pid_tezos_$name

for pidfile in ${pidfilebase}_node* ${pidfilebase}_baker* \
		${pidfilebase}_endorser* ${pidfilebase}_accuser*; do

if [ -f $pidfile ]; then
		pid=`cat $pidfile`
		kill -TERM $pid
		rm $pidfile
	fi
done


