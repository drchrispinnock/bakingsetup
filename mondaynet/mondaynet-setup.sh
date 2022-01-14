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
newbranch=96b50a69 # default
monday="2022-01-10"

mondaynet=0
dailynet=0
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	mondaynet=1
	testnetwork=mondaynet
fi

grep dailynet /etc/hostname
if [ "$?" = "0" ]; then
	dailynet=1
	testnetwork=dailynet
fi

if [ "$mondaynet" = "1" ]; then
	echo "MondayNet"
	newmonday=`/usr/bin/perl $perlscript`

fi
if [ "$dailynet" = "1" ]; then
	echo "DailyNet"
	newmonday=`date +%Y-%m-%d`
fi

if [ "$dailynet" != "1" && "$mondaynet" != 1 ]; then
	echo "Set hostname to include mondaynet or dailynet please!"
	exit 1
fi

# Set the software branch
#
if [ -f "$HOME/branch.txt" ]; then
	branch=`cat $HOME/branch.txt`
fi

newbranch=$branch
if [ "$1" != "" ]; then
	newbranch=$1
fi
echo "Setting software branch old: $branch $newbranch"
echo $newbranch > "$HOME/branch.txt"

# Has Monday changed
#
if [ -f "$HOME/monday.txt" ]; then
	monday=`cat $HOME/monday.txt`
fi
echo $newmonday > $HOME/monday.txt
echo "$testnetwork-$newmonday" > $HOME/network.txt

if [ "$monday" != "$newmonday" ]; then
	echo "New Period! Will reset wallet on next boot."
	touch "$HOME/.resetwallet"
fi
echo "Setting network ID to $newmonday"

echo "Terminating node software"
# Terminate node gracefully
#
$killscript $startconf

crontab -l > /tmp/_cron
grep mondaynet-start.sh /tmp/_cron >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Adding start scripts to crontab"
	echo "@reboot         /bin/bash $HOME/startup/mondaynet/mondaynet-start.sh >$HOME/start-log.txt 2>&1" >> /tmp/_cron
	crontab - < /tmp/_cron
fi


# Update OS
#
echo "Updating OS in 10 seconds"
sleep 10
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

echo "Rebooting in 15 seconds!"
sleep 15
# Reboot
#
sudo shutdown -r now "===Restart==="

