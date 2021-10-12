#!/bin/bash

# This script has the Ming Vase license. If you use the script
# and it breaks you get to keep the pieces.

# Defaults - override in the configuration file (shell)
#
piddir=/tmp

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

source $1
pidfilebase=$piddir/_pid_tezos_$name

if [ -z "$name" ]; then
	echo "I need name set"
	exit 1
fi

if [ `whoami` != $username ]; then
        echo "Must be run by $username"
        exit 3;
fi


for pidfile in ${pidfilebase}_node ${pidfilebase}_baker \
		${pidfilebase}_endorser ${pidfilebase}_accuser; do


	if [ -f $pidfile ]; then
		pid=`cat $pidfile`
		kill -TERM $pid
		rm $pidfile
	fi
done


