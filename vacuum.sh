#!/bin/sh

# Stop a node, vacuum it and start it again
# Chris Pinnock 2022
# MIT license

# Defaults - override in the configuration file (shell)
#
username=`whoami`
whereami=`dirname $0`
stopscript="$whereami/stop.sh"
startscript="$whereami/start.sh"
configstore=$HOME/_configs
network=mainnet
mode="full"

snapfile=""
snapshot=""
cliurl=""

# exit function
#
leave() {
	_code="$1"
	_msg="$2"
	echo "$_msg" >&2
	exit $_code
}

[ -z "$2" ] && leave 1 "Usage: $0 configfile http(s)://path_to_snapshot"
configfile=$1
cliurl=$2

. $configfile

[ `whoami` != $username ] && leave 2 "Must be run by $username"

[ -z "$tezosroot" ] && tezosroot=$HOME/tezos/$vers/tezos
[ ! -d "$tezosroot" ] && tezosroot=$HOME/tezos
[ ! -d "$tezosroot" ] && tezosroot=/usr/local/bin

tezosnode=$tezosroot/tezos-node
[ ! -x "$tezosnode" ] && leave 3 "Cannot find node software"

# Set the network to mainnet if not specified
#
[ -z "$snapnet" ] && snapnet="$network"

[ ! -d "$datadir" ] && leave 4 "Cannot find $datadir"

[ "$mode" = "archive" ] && leave 5 "Cannot refresh an archive node"

mode=${mode%%:*}  # Remove trailing :n (e.g. for rolling)
echo "===> Setting up for $snapnet $mode node refresh from $cliurl"
echo "===> Fetching snapshot $snapfile"

snapfile="tezos-$snapnet.$mode"
snapshot="$cliurl -O $snapfile"

if [ -f "$snapfile" ]; then
	echo "Already present $snapfile"
else
	wget -q $snapshot
	[ "$?" != "0" ] && leave 6 "Failed to get snapshot - fetch $snapfile manually"
fi

echo "===> Stopping node"
$stopscript $configfile

echo "===> Preserving current node directory"
[ -d "${datadir}.1" ] && mv "${datadir}.1" "${datadir}.d"
mv "${datadir}" "${datadir}.1"
[ "$?" != "0" ] && leave 7 "Cannot preserve $datadir"

mkdir -p $configstore
cp -p "${datadir}.1/config.json" $configstore
cp -p "${datadir}.1/peers.json" $configstore
cp -p "${datadir}.1/identity.json" $configstore

mkdir -p ${datadir}
cp -p "${configstore}/config.json" $datadir

echo "===> Importing snapshot"
$tezosnode snapshot import "$snapfile" --data-dir ${datadir} --network $network
[ "$?" != "0" ] && leave 8 "Import failed"

echo "===> Restoring configuration"
cp -p "${configstore}/config.json" $datadir
cp -p "${configstore}/peers.json" $datadir
cp -p "${configstore}/identity.json" $datadir

echo "===> Restarting node"
$startscript $configfile

echo "===> Cleaning up"
rm -f "$snapshot"
rm -rf "${datadir}.d"
echo "If you are happy, you can remove"
echo "   ${datadir}.1"
echo "   ${snapfile}"
