#!/bin/sh

# Restart a node
# Chris Pinnock 2022
# MIT license

# Fun!
octez=tezos

# Defaults - override in the configuration file (shell)
#
username=`whoami`
whereami=`dirname $0`
stopscript="$whereami/stop.sh"
startscript="$whereami/start.sh"

# exit function
#
leave() {
	_code="$1"
	_msg="$2"
	echo "$_msg" >&2
	exit $_code
}

[ -z "$1" ] && leave 1 "Usage: $0 configfile"
configfile=$1

. $configfile

[ `whoami` != $username ] && leave 2 "Must be run by $username"

echo "===> Stopping node"
$stopscript $configfile

sleep 10 

echo "===> Restarting node"
$startscript $configfile

