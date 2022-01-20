#!/bin/sh

mv startup backingsetup
host=`hostname -s`
mv backingsetup/mondaynet/wallet-$host ~/wallet-$host

crontab - < /dev/null

echo "Now run setup!"
