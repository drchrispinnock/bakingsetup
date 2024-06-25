#!/bin/bash

# Start a Tezos baking setup.
# Chris Pinnock 2022
# MIT license

# Defaults - override in the configuration file (shell)
#
# bake=0 - just run a node; 1 run a baker & a accuser
bake=0
dal=0

# Yeah! Transitional binary name fun
#
octez="tezos"


# logging
#
logdir=$HOME/logs
logging=$logdir/logfile
dallogging=$logdir/logfile_dal
bakerlogging=$logdir/logfile_baking
accuselogging=$logdir/logfile_accuser

datadir=$HOME/.tezos-node
daldir=$HOME/.tezos-dal-node

# Since Protocol J, Liquidity Baking Votes must be declared
#
lvote=pass
lbakeropts="--liquidity-baking-toggle-vote $lvote"

# Don't or just config
#
dontconfig=0
justconfig=0

# ports
#
netport=9732
rpcport=8732
rpcaddr="[::]"
netaddr="[::]"

# Where to store PID files
#
piddir=/tmp

# Assume mainnet & full
#
name=mainnet
network=mainnet
mode=full

# If not set, set to me
#
username=`whoami`

# exit function
#
leave() {
	_code="$1"
	_msg="$2"
	echo "$_msg" >&2
	exit $_code
}
# Command line options
#
[ -z "$1" ] && leave 1 "Usage: $0 configfile"
[ "$2" = "justconfig" ] && 	justconfig=1

. $1
mkdir -p $logdir
mkdir -p $piddir

pidfilebase=$piddir/_pid_octez_$name
pidfile_node=${pidfilebase}_node
pidfile_baker=${pidfilebase}_baker
pidfile_dal=${pidfilebase}_dal
pidfile_accuser=${pidfilebase}_accuser

if [ -f "$HOME/localconfig.txt" ]; then
	. $HOME/localconfig.txt
fi

[ `whoami` != $username ] && leave 2 "Must be run by $username"

# Setup PID files
#
[ -f "$pidfile_node" ] && leave 3 "PID file already exists!"

# Attempt to find the installation if not set
#
[ -z "$tezosroot" ] && tezosroot=$HOME/tezos/$vers/tezos
[ ! -d "$tezosroot" ] && tezosroot=$HOME/tezos
[ ! -d "$tezosroot" ] && tezosroot=/usr/local/bin

if [ -x "$tezosroot/octez-node" ]; then
	octez="octez"
fi

octeznode=$tezosroot/${octez}-node
octezdal=$tezosroot/${octez}-dal-node

[ ! -x "$octeznode" ] && leave 4 "Cannot find node software"

if [ "$dal" != "0" ] && [ ! -x "$octezdal" ]; then
	echo "Cannot find DAL - won't use"
	dal=0	
fi

# The installation has a list of active protocol versions
#
protocols="NONE"

for loc in "$tezosroot" "$tezosroot/script-inputs" 	"/usr/local/share/tezos"; do

	if [ -f "$loc/active_protocol_versions_without_number" ]; then
		protocols=`cat $loc/active_protocol_versions_without_number`
		break
	fi
	
	if [ -f "$loc/active_protocol_versions" ]; then
		protocols=`cat $loc/active_protocol_versions`
		break
	fi
done

[ "$protocols" = "NONE" ] && leave 5 "Cannot location active protocol file"

# Setup
#
if [ ! -d "$datadir" ] || [ ! -f "$datadir/config.json" ]; then

	# Sometimes we will want to setup a node manually
	#
	[ "$dontconfig" = "1" ] && leave 0 "Skipping configuration"

	echo "===> Setting up configuration"
	mkdir -p "$datadir"
	$octeznode config init 	--data-dir=$datadir \
				--net-addr=$netaddr:$netport \
				--rpc-addr=$rpcaddr:$rpcport \
				--log-output=$logging \
				--network="$network" \
				--history-mode=$mode $otherconfigopts

	[ "$?" != "0" ] && leave 6 "Configuration failed"
	[ ! -f "$datadir/config.json" ] && leave 6 "Configuration failed"

	if [ ! -f "$datadir/identity.json" ]; then
		$octeznode identity generate --data-dir=$datadir
	fi

fi

[ "$justconfig" = "1" ] && leave 0 "Just configuring - exit"

# Check log directories
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

$octeznode run --data-dir=$datadir --log-output=$logging $otherrunopts &
pid=$!

[ "$?" != "0" ] && leave 8 "Failed to start node"

echo "Started with PID $pid"
echo "$pid" > $pidfile_node

if [ "$bake" = "1" ]; then
	# Let's cook!
	#
	sleep 10
	while [ 1 = 1 ]; do
		$tezosroot/${octez}-client -E http://127.0.0.1:$rpcport bootstrapped
	        [ "$?" = "0" ] && break;
		echo "===> Sleeping for node to come up"
		sleep 30
	done

	if [ "$dal" != "0" ]; then 
		$octezdal config init --endpoint=http://127.0.0.1:$rpcport \
				--net-addr="[::]"
		$octezdal run > $logging_dal 2>&1 &
		[ "$?" != "0" ] && leave 8 "Failed to start DAL"
	fi

	for protocol in $protocols; do

		opts=""
		if [ "$dal" != "0" ]; then
			opts="--dal-node http://127.0.0.1:10732"
		fi

		octezbaker=$tezosroot/${octez}-baker-$protocol
		octezaccuse=$tezosroot/${octez}-accuser-$protocol

		$octezbaker run with local node \
			$datadir $bakerid $lbakeropts $opts \
			--pidfile ${pidfile_baker}-${protocol} \
			>> ${bakerlogging}-${protocol} 2>&1 &

		$octezaccuse run --pidfile ${pidfile_accuser}-${protocol} \
			>> ${accuselogging}-${protocol}  2>&1 &

	done
fi
