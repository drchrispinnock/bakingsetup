#!/bin/sh

# Run me from cron.
# Set s3bucket in the environment

[ -z "$snapshotdir" ] && snapshotdir="/tmp/snaps"
[ -z "$s3bucket" ] && echo "Set s3bucket to the target in the environment" \
		&& exit 1

# Make a snapshot
mkdir -p $snapshotdir
now=`date +%Y%m%d%H%M`

octez-node snapshot export $snapshotdir/$now."snapshot" --block head
[ $? = "0" ] && echo "Snapshot failed!" && exit 2

aws s3 cp $snapshotdir/$now."snapshot" $s3bucket



