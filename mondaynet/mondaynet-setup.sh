#!/bin/bash

# Setup or reset a Mondaynet node manually
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.
#

# Assuming a throw away AWS environment
#
if [ `whoami` != "ubuntu" ]; then
	echo "Must be run by ubuntu"
	exit 3;
fi

killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet/mondaynet-common.conf
perlscript=$HOME/startup/mondaynet/last_monday.pl
branch=96b50a69 # default
monday="2022-01-10"

# Set the software branch
#
if [ "$1" != "" ]; then
	branch=$1
fi
echo "Setting software branch to $branch"
echo $branch > "$HOME/branch.txt"


# Has Monday changed
#
if [ -f "$HOME/monday.txt" ]; then
	monday=`cat $HOME/monday.txt`
fi
newmonday=`/usr/bin/perl $perlscript`
echo $newmonday > $HOME/monday.txt

if [ "$monday" != "$newmonday" ]; then
	echo "New Monday! Will reset wallet on next boot."
	touch "$HOME/.resetwallet"
fi
echo "Setting network ID to $newmonday"

echo "Terminating node software"
# Terminate node gracefully
#
$killscript $startconf

exit 1

# Update OS
#
sudo apt-get update
sudo apt-get upgrade -y

echo "Rebooting in 15 seconds!"
sleep 15
# Reboot
#
sudo shutdown -r now "===MondayNet Restart==="

