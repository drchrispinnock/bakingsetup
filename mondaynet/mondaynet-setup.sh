#!/bin/bash

# Setup or reset a Mondaynet node manually
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.
#

sudo apt-get install -y libjson-perl

# Assuming a throw away AWS environment
#
if [ `whoami` != "ubuntu" ]; then
	echo "Must be run by ubuntu"
	exit 3;
fi

testnetrepos=https://teztnets.xyz
testnetfile=teztnets.json

killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet/mondaynet-common.conf
perlscript=$HOME/startup/mondaynet/last_monday.pl
parsejson=$HOME/startup/mondaynet/parse_testnet_json.pl
newbranch=96b50a69 # default
monday="2022-01-10"

mondaynet=0
dailynet=0
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	mondaynet=1
	testnetwork=mondaynet
	freq="50 0 * * 1" # Monday at 00:10
fi

grep dailynet /etc/hostname
if [ "$?" = "0" ]; then
	dailynet=1
	testnetwork=dailynet
	freq="40 0 * * *" # Daily at 00:10
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


# Has Monday changed
#
if [ -f "$HOME/monday.txt" ]; then
	monday=`cat $HOME/monday.txt`
fi
echo $newmonday > $HOME/monday.txt
fullname=$testnetwork-$newmonday
echo "$fullname" > $HOME/network.txt

if [ "$monday" != "$newmonday" ]; then
	echo "New Period! Will reset wallet and node on next boot."
	touch "$HOME/.resetwallet"
	touch "$HOME/.resetnode"
fi
echo "Setting network ID to $newmonday"

newbranch=$branch
if [ "$1" != "" ]; then
	newbranch=$1
else
	rm -f $testnetfile
	wget $testnetrepos/$testnetfile
	if [ "$?" != "0" ]; then
		echo "XXX Cannot get test repository!"
	else
		new=`perl $parsejson $testnetfile $testnetwork`
		if [ "$?" != "0" ]; then
			echo "XXX Cannot grok $testnetfile"
		else
			newbranch=$new
		fi
		rm -f $testnetfile
	fi

fi
echo $newbranch > "$HOME/branch.txt"

if [ "$branch" != "$newbranch" ]; then
	echo "Setting software branch old: $branch -> $newbranch"
	rm -f $HOME/tezos-$branch.tar.gz
fi



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

crontab -l > /tmp/_cron
grep mondaynet-setup.sh /tmp/_cron >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Adding start scripts to crontab"
	echo "$freq         /bin/bash $HOME/startup/mondaynet/mondaynet-setup.sh >$HOME/setup-log.txt 2>&1" >> /tmp/_cron
	crontab - < /tmp/_cron
fi


# Update OS
#
echo "Updating OS in 10 seconds"
sleep 10
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

echo "Update mondaynet scripts"
cd $HOME/startup && git pull

echo "Rebooting in 15 seconds!"
sleep 15
# Reboot
#
sudo shutdown -r now "===Restart==="

