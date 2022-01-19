#!/bin/bash

# Setup or reset a Mondaynet node manually
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.
#

# Dependency
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

mondaynet=0
dailynet=0
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	echo "MondayNet"
	mondaynet=1
	testnetwork=mondaynet
	freq="50 0 * * 1" # Monday at 00:10
fi

grep dailynet /etc/hostname
if [ "$?" = "0" ]; then
	echo "DailyNet"
	dailynet=1
	testnetwork=dailynet
	freq="40 0 * * *" # Daily at 00:10
fi

# Experiment	
freq="30 * * * *" # Every hour check

# Setup Cron
#
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

# Setup monday
monday=""
if [ -f "$HOME/monday.txt" ]; then
	monday=`cat $HOME/monday.txt`
fi

# Set the software branch
#
if [ -f "$HOME/branch.txt" ]; then
	branch=`cat $HOME/branch.txt`
fi

newbranch=$branch
rm -f $testnetfile
wget $testnetrepos/$testnetfile
if [ "$?" != "0" ]; then
	echo "XXX Cannot get test repository dump!"
	exit 1
else
	new=`perl $parsejson $testnetfile $testnetwork`
	if [ "$?" != "0" ]; then
		echo "XXX Cannot grok $testnetfile"
		exit 1
	else
		newbranch=`echo $new | awk -F' ' '{print $2}'`
		newmonday=`echo $new | awk -F' ' '{print $1}'`
	fi
	rm -f $testnetfile
fi
echo $newbranch > "$HOME/branch.txt"

if [ "$branch" != "$newbranch" ]; then
	echo "Setting software branch old: $branch -> $newbranch"
	rm -f $HOME/tezos-$branch.tar.gz
fi

# Has Monday changed
#
echo $newmonday > $HOME/monday.txt
fullname=$newmonday
echo "$fullname" > $HOME/network.txt

if [ -f "$HOME/.cleanup" ]; then
	monday=""
fi

if [ "$monday" != "$newmonday" ]; then
	echo "$monday -> $newmonday"
	echo "New Period! Will reset wallet and node on next boot."
	touch "$HOME/.resetwallet"
	touch "$HOME/.resetnode"
	echo "Setting network ID to $newmonday"

	echo "Terminating node software"
	# Terminate node gracefully
	#
	$killscript $startconf
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
else
	echo "Network has not changed - .cleanup to reset"
fi
