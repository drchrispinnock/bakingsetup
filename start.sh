#!/bin/bash

# This script has the Ming Vase license. If you use the script
# and it breaks you get to keep the pieces.

# Defaults - override in the configuration file (shell)
#
bake=0
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

if [ `whoami` != $username ]; then
	echo "Must be run by $username"
	exit 3;
fi

[ "$bake" = "1" ] && background=1

pidfilebase=$piddir/_pid_tezos_$name
pidfile=${pidfilebase}_node

[ -f "$pidfile" ] && echo "PID file already exists!" && exit 1

[ -z "$tezosroot" ] && tezosroot=/home/cjep/tezos/$vers/tezos

# On a proper installation, this is in a file
protocols="010-PtGRANAD 011-PtHangz2 alpha"
if [ -f "$tezosroot/active_protocol_versions" ]; then
	protocols=`cat $tezosroot/active_protocol_versions`
fi

tezosnode=$tezosroot/tezos-node

# Sanity
#
[ ! -x "$tezosnode" ] && echo "Cannot find node software" && exit 1

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

	if [ "$bake" = "1" ]; then

		for protocol in $protocols; do
			tezosbaker=$tezosroot/tezos-baker-$protocol
			tezosendorse=$tezosroot/tezos-endorser-$protocol
			tezosaccuse=$tezosroot/tezos-accuser-$protocol

			$tezosbaker run with local node $datadir $ledger --pidfile ${pidfilebase}_baker-$protocol >> $bakerlogging 2>&1 &

			# Future protocols will not have endorsers
			#
			if [ -x "$tezosendorse" ]; then 
				$tezosendorse run >> $endorselogging  2>&1 &
				echo "$!" > ${pidfilebase}_endorser-$protocol
			fi
			
			$tezosaccuse run >> $accuselogging  2>&1 &
			echo "$!" > ${pidfilebase}_accuser-$protocol
		done
	fi

else
	$com
fi
