#!/bin/bash

# This script has the Ming Vase license. If you use the script
# and it breaks you get to keep the pieces.

# Defaults - override in the configuration file (shell)
#
logging=stdout
background=0
dontconfig=0
justconfig=0
netport=8732
rpcport=9732
rpcaddr="[::]"
netaddr="[::]"
piddir=/tmp
snapshot=""

#snapfile="tezos-mainnet.full"
#snapshot="https://mainnet.xtz-shots.io/full -O $snapfile"

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

if [ "$2" = "justconfig" ]; then
	justconfig=1
fi

source $1

pidfile=$piddir/_tezos_$name.pid

[ -z "$tezosroot" ] && tezosroot=/home/cjep/tezos/$vers/tezos

[ -f "$pidfile" ] && echo "PID file already exists!" && exit 1

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
				--net-addr=$netaddr:$netport \
				--rpc-addr=$rpcaddr:$rpcport \
				--log-output=$logging \
				--history-mode=$mode $otherconfigopts
fi

[ "$justconfig" = "1" ] && echo "Just configuring - exit" && exit 0

# Import a snapshot
#
if [ ! -z "$snapshot" ]; then

	[ -z "$snapfile" ] && snapfile=`basename $snapshot`
	echo "Fetching $snapshot"
	wget $snapshot
	echo "Importing $snapshot"
	$tezosnode --data-dir=$datadir snapshot import "$snapfile"
	rm -f "$snapfile"
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
	echo "$pid" > $pidfile
else
	$com
fi
