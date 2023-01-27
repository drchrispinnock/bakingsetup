#!/bin/sh

# Run me from cron.
# Set s3bucket in the environment

[ -z "$snapshotdir" ] && snapshotdir="snaps"
[ -z "$name" ] && name="mondaynet"
[ -z "$s3bucket" ] && s3bucket="s3://mondaynet.snapshots/"

# Make a snapshot
mkdir -p $snapshotdir
now=`date +%Y%m%d%H%M`

$HOME/tezos/octez-node snapshot export $snapshotdir/$name-rolling-snapshot --block head --rolling
[ $? != "0" ] && echo "Snapshot failed!" && exit 2

echo "<html><a href=\"$name-rolling-snapshot\">Mondaynet Snapshot created at $now</a></html>" > $snapshotdir/index.html

aws s3 sync $snapshotdir/ $s3bucket
rm -f $snapshotdir/$name-rolling-snapshot



