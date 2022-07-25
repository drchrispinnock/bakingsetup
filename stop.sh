#!/bin/bash

# Stop a baking setup.
# Chris Pinnock 2022
# MIT license
#

# Defaults - override in the configuration file (shell)
#
username=`whoami`
name=mainnet
piddir=/tmp
pidfilebase=$piddir/_pid_tezos_$name
pidfile_node=${pidfilebase}_node
pidfile_baker=${pidfilebase}_baker
pidfile_accuser=${pidfilebase}_accuser

# exit function
#
leave() {
	_code="$1"
	_msg="$2"
	echo "$_msg" >&2
	exit $_code
}

[ -z "$1" ] && leave 1 "Usage: $0 configfile"
source $1

[ `whoami` != $username ] && leave 2 "Must be run by $username"

for pidfile in ${pidfile_node}* ${pidfile_baker}* ${pidfile_accuser}*; do

if [ -f $pidfile ]; then
		pid=`cat $pidfile`
		kill -TERM $pid
		rm $pidfile
	fi
done
