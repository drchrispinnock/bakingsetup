#!/bin/bash

# Restart a Mondaynet node
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.
#
# Run me out of cron on a Monday


killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet/mondaynet.conf
perlscript=$HOME/startup/mondaynet/last_monday.pl

# Terminate node gracefully
#
$killscript $startconf

# Cron will run this on a Monday... but get last monday
monday=""
if [ -f "$HOME/monday.txt" ]; then
	monday=`cat $HOME/monday.txt`
fi
newmonday=`/usr/bin/perl $perlscript`
echo $newmonday > $HOME/monday.txt

if [ "$monday" != "$newmonday" ]; then
	echo "New Monday! Will reset wallet on next boot."
	touch "$HOME/.resetwallet"
fi

# Update OS
#
sudo apt-get update
sudo apt-get upgrade -y

# Reboot
#
sudo shutdown -r now "===MondayNet Restart==="

