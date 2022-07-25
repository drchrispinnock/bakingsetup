#!/bin/bash

# Start a Tezos baking setup.
# Chris Pinnock 2022
# MIT license

# Defaults - override in the configuration file (shell)
#
bake=0
logging=stdout
bakerlogging=$HOME/logs/logfile_baking
accuselogging=$HOME/logs/logfile_accuser

lvote=pass

dontconfig=0
justconfig=0
netport=9732
rpcport=8732
rpcaddr="[::]"
netaddr="[::]"
piddir=/tmp

if [ -z "$1" ]; then
	echo "Usage: $0 configfile"
	exit 1
fi

if [ "$2" = "justconfig" ]; then
	justconfig=1
fi

source $1

if [ -f "$HOME/localconfig.txt" ]; then
	source $HOME/localconfig.txt
fi

if [ `whoami` != $username ]; then
	echo "Must be run by $username"
	exit 3;
fi

# Setup PID files
#
pidfilebase=$piddir/_pid_tezos_$name
pidfile=${pidfilebase}_node

[ -f "$pidfile" ] && echo "PID file already exists!" && exit 1

# Attempt to find the installation if not set
#
[ -z "$tezosroot" ] && tezosroot=$HOME/tezos/$vers/tezos
[ ! -d "$tezosroot" ] && tezosroot=$HOME/tezos

tezosnode=$tezosroot/tezos-node
[ ! -x "$tezosnode" ] && echo "Cannot find node software" && exit 1

# Set the network to mainnet if not specified
#
[ -z "$network" ] && network=mainnet

# Usually an installation has a list of active protocol versions
#
protocols="011-PtHangz2 012-Psithaca alpha"

if [ -f "$tezosroot/active_protocol_versions" ]; then
	protocols=`cat $tezosroot/active_protocol_versions`
fi

if [ -f "$tezosroot/script-inputs/active_protocol_versions" ]; then
	protocols=`cat $tezosroot/script-inputs/active_protocol_versions`
fi

# Setup
#
if [ ! -d "$datadir" ] || [ ! -f "$datadir/config.json" ]; then

	# Sometimes we will want to setup a node manually
	#
	[ "$dontconfig" = "1" ] && echo "Skipping configuration!" && exit 1


	echo "===> Setting up configuration"
	mkdir -p "$datadir"
	$tezosnode config init 	--data-dir=$datadir \
				--net-addr=$netaddr:$netport \
				--rpc-addr=$rpcaddr:$rpcport \
				--log-output=$logging \
				--network="$network" \
				--history-mode=$mode $otherconfigopts

	if [ "$?" != "0" ]; then
		echo "XXX Configuration failed"
		exit 1
	fi

	if [ ! -f "$datadir/config.json" ]; then
		echo "XXX Configuration failed"
		exit 1
	fi

	if [ ! -f "$datadir/identity.json" ]; then
		$tezosnode identity generate --data-dir=$datadir
	fi

fi

[ "$justconfig" = "1" ] && echo "Just configuring - exit" && exit 0

# Logs
#
if [ "$logging" != "stdout" ] && [ "$logging" != "stderr" ] && \
		[ "${logging%%:*}" != "syslog" ]; then
	mkdir -p `dirname $logging`
fi

mkdir -p `dirname $bakerlogging`
mkdir -p `dirname $accuselogging`


# Let's go then
#
echo "===> Starting $name node"

$tezosnode run --data-dir=$datadir --log-output=$logging $otherrunopts &
$pid=$!
[ "$?" != "0" ] && echo "Failed to start" && exit 1

echo "Started with PID $pid"
echo "$pid" > $pidfile

if [ "$bake" = "1" ]; then
	# Let's cook!
	#
	sleep 10
	while [ 1 = 1 ]; do
		$tezosroot/tezos-client -E http://127.0.0.1:$rpcport bootstrapped
	        [ "$?" = "0" ] && break;
		echo "===> Sleeping for node to come up"
		sleep 30
	done

	for protocol in $protocols; do
		tezosbaker=$tezosroot/tezos-baker-$protocol
		tezosaccuse=$tezosroot/tezos-accuser-$protocol

		lbakeropts="--liquidity-baking-toggle-vote $lvote"

		$tezosbaker -E http://127.0.0.1:$rpcport run with local node $datadir $bakerid $lbakeropts --pidfile ${pidfilebase}_baker-$protocol >> $bakerlogging-$protocol 2>&1 &

		$tezosaccuse -E http://127.0.0.1:$rpcport run >> $accuselogging  2>&1 &
		echo "$!" > ${pidfilebase}_accuser-$protocol
	done
fi
