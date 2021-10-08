#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

source $1

tezosroot=$HOME/tezos/$vers/tezos
tezosnode=$tezosroot/tezos-node

# Sanity
#
[ ! -x "$tezosnode" ] && echo "Cannot find node software" && exit 1

# Setup
#
if [ ! -d "$datadir" ] || [ ! -f "$datadir/config.json" ]; then
	echo "Setting up configuration"
	mkdir -p "$datadir"
	$tezosnode config init 	--data-dir=$datadir \
				--net-addr=[::]:$netport \
				--history-mode=$mode
fi

# Let's go then
#
echo "Starting $name node"

$tezosnode run --data-dir=$datadir
