#!/bin/sh

# Run me from cron.
# Set s3bucket in the environment

[ -z "$snapshotdir" ] && snapshotdir="snaps"
[ -z "$name" ] && name="mondaynet"
[ -z "$s3bucket" ] && s3bucket="mondaynet.snapshots"

# Make a snapshot
mkdir -p $snapshotdir
now=`date +%Y%m%d%H%M`

$HOME/tezos/octez-node snapshot export $snapshotdir/$name-$now."snapshot" --block head --rolling
[ $? != "0" ] && echo "Snapshot failed!" && exit 2

aws s3 cp $snapshotdir/$name-$now."snapshot" $s3bucket
rm -f $name-$now."snapshot"



