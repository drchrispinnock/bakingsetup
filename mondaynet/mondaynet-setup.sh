#!/bin/bash

<<<<<<< HEAD
# Setup or reset a Mondaynet node manually
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces. Run this on a AWS Ubuntu instance
# with nothing else that you want to keep.
#

# Dependency for JSON parsing
#
sudo apt-get install -y libjson-perl
=======
# Setup or reset a Mondaynet/Dailynet node
# Chris Pinnock 2022
# MIT license
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e

# Assuming a throw away AWS environment
#
if [ `whoami` != "ubuntu" ]; then
	echo "Must be run by ubuntu"
	exit 3;
fi

<<<<<<< HEAD
testnetrepos=https://teztnets.xyz
testnetfile=teztnets.json
=======
# Dependency for JSON parsing
#
sudo apt-get install -y libjson-perl
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e

me=$HOME/bakingsetup
killscript=$me/kill.sh
startconf=$me/mondaynet/mondaynet-common.conf
starter=$me/mondaynet/mondaynet-start.sh
startlog=$HOME/start-log.txt
parsejson=$me/mondaynet/parse_testnet_json.pl

<<<<<<< HEAD
mondaynet=0
dailynet=0
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	echo "MondayNet"
	mondaynet=1
	testnetwork=mondaynet
	freq="50 0 * * 1" # Monday at 00:10
=======
# Hardcoded remote test network repository
#
testnetrepos=https://teztnets.xyz
testnetfile=teztnets.json
freq="30 * * * *" # Every hour check for changes

# Test the hostname to determine which network we want to join
#
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	echo "MondayNet"
	testnetwork=mondaynet
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
fi

grep dailynet /etc/hostname
if [ "$?" = "0" ]; then
	echo "DailyNet"
<<<<<<< HEAD
	dailynet=1
	testnetwork=dailynet
	freq="40 0 * * *" # Daily at 00:10
fi

# Experiment	
freq="30 * * * *" # Every hour check

# Setup Cron
=======
	testnetwork=dailynet
fi

# Setup Cronjobs
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
#
crontab -l > /tmp/_cron
grep mondaynet-start.sh /tmp/_cron >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Adding start scripts to crontab"
	echo "@reboot         /bin/bash $starter> $startlog 2>&1" >> /tmp/_cron
	crontab - < /tmp/_cron
fi

crontab -l > /tmp/_cron
grep mondaynet-setup.sh /tmp/_cron >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Adding start scripts to crontab"
	echo "$freq         /bin/bash $me/mondaynet/mondaynet-setup.sh >$HOME/setup-log.txt 2>&1" >> /tmp/_cron
	crontab - < /tmp/_cron
fi

<<<<<<< HEAD
# Setup monday
=======
# Setup the network names for comparison
# On first run this will be empty
#
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
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
<<<<<<< HEAD
=======

# Get the test network repos and determine the correct branch
# and network
#
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
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

<<<<<<< HEAD
# Has Monday changed
=======
# Has the network changed?
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
#
echo $newmonday > $HOME/monday.txt
fullname=$newmonday
echo "$fullname" > $HOME/network.txt

<<<<<<< HEAD
=======
# Regardless, if .cleanup is there zero monday so that we reset
# on next run
#

>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
if [ -f "$HOME/.cleanup" ]; then
	monday=""
fi

if [ "$monday" != "$newmonday" ]; then
<<<<<<< HEAD
	echo "$monday -> $newmonday"
	echo "New Period! Will reset wallet and node on next boot."
	touch "$HOME/.resetwallet"
	touch "$HOME/.resetnode"
	echo "Setting network ID to $newmonday"
=======
	echo "Network ID: $monday -> $newmonday"
	echo "New Period! Will reset wallet and node on next run."
	touch "$HOME/.resetwallet"
	touch "$HOME/.resetnode"
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e

	echo "Terminating node software"
	# Terminate node gracefully
	#
	$killscript $startconf
	
<<<<<<< HEAD
=======
	if [ -f "$HOME/.updatesoftware" ]; then
		echo "Update mondaynet scripts"
		cd $me && git pull
	fi
	
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
	if [ -f "$HOME/.noreboot" ]; then
		# Let's not reboot then
		#
		echo "Restarting (without reboot)"
		/bin/bash $starter > $startlog 2>&1 &
		exit 0
	fi

<<<<<<< HEAD
	# Update OS
	#
	echo "Updating OS in 10 seconds"
	sleep 10
=======
	# Update OS - we sleep because sometimes we need to CTRL-C...
	#
	echo "Updating OS in 5 seconds"
	sleep 5
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get dist-upgrade -y

<<<<<<< HEAD
	echo "Update mondaynet scripts"
	cd $me && git pull
=======
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e

	echo "Rebooting in 15 seconds!"
	sleep 15
	# Reboot
	#
	sudo shutdown -r now "===Restart==="
else
<<<<<<< HEAD
	echo "Network has not changed - .cleanup to reset"
=======
	echo "Network has not changed - touch .cleanup to reset"
>>>>>>> b8445744e152632df8040bbd9152b317bd80729e
fi
