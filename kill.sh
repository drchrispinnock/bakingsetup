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
pidfile=$piddir/_tezos_$name.pid

if [ -z "$name" ]; then
	echo "I need name set"
	exit 1
fi


if [ -f $pidfile ]; then
	pid=`cat $pidfile`
	sudo kill -TERM $pid
	rm $pidfile
fi
