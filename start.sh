#!/bin/bash

# Defaults - override in the configuration file (shell)
#
logging=stdout
background=0
dontconfig=0
netport=8732
rpcport=9732
piddir=/tmp

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

source $1

[ -z "$tezosroot" ] && tezosroot=/home/cjep/tezos/$vers/tezos

tezosnode=$tezosroot/tezos-node

# Sanity
#
[ ! -x "$tezosnode" ] && echo "Cannot find node software" && exit 1

# Adjust for sudo
#
if [ ! -z "$username" ]; then
	# Do something
	tezosnode="sudo -u $username $tezosnode"
fi

# Setup
#
if [ ! -d "$datadir" ] || [ ! -f "$datadir/config.json" ]; then

	# Sometimes we will want to setup a node manually
	#
	[ "$dontconfig" = "1" ] && echo "Skipping configuration!" && exit 1

	echo "Setting up configuration"
	mkdir -p "$datadir"
	$tezosnode config init 	--data-dir=$datadir \
				--net-addr=[::]:$netport \
				--rpc-addr=[::]:$rpcport \
				--log-output=$logging \
				--history-mode=$mode $otherconfigopts
fi

# Let's go then
#
echo "Starting $name node"
com="$tezosnode run --data-dir=$datadir --log-output=$logging $otherrunopts"
if [ "$background" = "1" ]; then
	$com &
	pid=$!
	if [ "$?" != "0" ]; then
		echo "Failed to start"
		exit 1
	fi
	echo "Started with PID $pid"
	echo "$pid" > $piddir/_tezos_$name.pid
else
	$com
fi
