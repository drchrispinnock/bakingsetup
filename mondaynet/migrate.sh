#!/bin/sh

mv startup bakingsetup
host=`hostname -s`
mv bakingsetup/mondaynet/wallet-$host ~/wallet-$host

crontab - < /dev/null

echo "Now run setup!"
