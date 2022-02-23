#!/bin/bash

# Stop a node, vacuum it and start it again
# Chris Pinnock 2022
# MIT license

# Defaults - override in the configuration file (shell)
#
username=`whoami`
whereami=`dirname $0`
stopscript="$whereami/kill.sh"
startscript="$whereami/start.sh"
configstore=$HOME/_configs

mastersite=xtzshots
#mastersite=giganode

snapfile=""
snapshot=""

if [ -z "$1" ]; then
	echo "Usage: $0 configfile [mastersite]"
	exit 1
fi

if [ ! -z "$2" ]; then
	mastersite=$2
fi

configfile=$1
source $configfile 

if [ `whoami` != $username ]; then
	echo "Must be run by $username"
	exit 3;
fi

[ -z "$tezosroot" ] && tezosroot=$HOME/tezos/$vers/tezos
[ ! -d "$tezosroot" ] && tezosroot=$HOME/tezos

tezosnode=$tezosroot/tezos-node
[ ! -x "$tezosnode" ] && echo "Cannot find node software" && exit 1

# Set the network to mainnet if not specified
#
[ -z "$network" ] && network=mainnet
[ -z "$snapnet" ] && snapnet="$network"
[ "$mode" = "" ] && mode="full"

echo $datadir
[ ! -d "$datadir" ] && echo "Cannot find $datadir" && exit 1

if [ "$mode" = "archive" ]; then
	echo "Cannot refresh an archive node"
	exit 1
fi

mode=${mode%%:*}  # Remove trailing :n (e.g. for rolling)
echo "===> Setting up for $snapnet $mode node refresh from $mastersite"
snapfile="tezos-$snapnet.$mode"
snapshot=""

if [ "$mastersite" = "xtzshots" ]; then
	snapfile="tezos-$snapnet.$mode"
	snapshot="https://$snapnet.xtz-shots.io/$mode -O $snapfile"
fi

#if [ "$mastersite" = "giganode" ]; then
#	snapfile="tezos-$snapnet.$mode"
#	snapshot="https://$snapnet.xtz-shots.io/$mode -O $snapfile"
#fi


echo "===> Fetching snapshot $snapfile"

if [ -f "$snapfile" ]; then 
	echo "Already present $snapfile"
else
	if [ "$snapshot" != "" ]; then
		wget -q $snapshot
		if [ "$?" != "0" ]; then
			echo "Failed to get snapshot - fetch $snapfile manually"
			exit 1
		fi
	else
		echo "Fetch $snapfile manually"
		exit 1
fi

echo "===> Stopping node"
$stopscript $configfile

echo "===> Preserving current node directory"
[ -d "${datadir}.1" ] && mv "${datadir}.1" "${datadir}.d"
mv "${datadir}" "${datadir}.1"
if [ "$?" != "0" ]; then
	echo "Cannot preserve $datadir"
	exit 1
fi
mkdir -p $configstore
cp -p "${datadir}.1/config.json" $configstore
cp -p "${datadir}.1/peers.json" $configstore
cp -p "${datadir}.1/identity.json" $configstore

mkdir -p ${datadir}
cp -p "${configstore}/config.json" $datadir

echo "===> Importing snapshot"
$tezosnode snapshot import "$snapfile" --data-dir ${datadir} --network $network
if [ "$?" != "0" ]; then
	echo "Import failed"
	exit 1
fi

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

