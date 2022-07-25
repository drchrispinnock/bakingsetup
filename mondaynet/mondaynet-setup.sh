#!/bin/bash

# Setup or reset a Mondaynet/Dailynet node
# Chris Pinnock 2022
# MIT license

# Dependencies
#
sudo apt-get install -y libjson-perl wget cargo

me=$HOME/bakingsetup
killscript=$me/kill.sh
startconf=$me/mondaynet/mondaynet-common.conf
starter=$me/mondaynet/mondaynet-start.sh
startlog=$HOME/start-log.txt
parsejson=$me/mondaynet/parse_testnet_json.pl
cronsetup=1

[ "$1" = "once" ] && cronsetup=0

# Hardcoded remote test network repository
#
testnetrepos=https://teztnets.xyz
testnetfile=teztnets.json
freq="30 * * * *" # Every hour check for changes

# Test the hostname to determine which network we want to join
# Hostnames should be
# Networkname-something else
#
# e.g. mondaynet-lon
testnetwork=`cat /etc/hostname | sed -e 's/\-.*//g'`
echo "Setting up for $testnetwork"

# Setup Cronjobs
#
crontab -l > /tmp/_cron
grep mondaynet-start.sh /tmp/_cron >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Adding start scripts to crontab"
	echo "@reboot         /bin/bash $starter> $startlog 2>&1" >> /tmp/_cron
	crontab - < /tmp/_cron
fi

if [ "$cronsetup" = "1" ]; then

	crontab -l > /tmp/_cron
	grep mondaynet-setup.sh /tmp/_cron >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo "Adding start scripts to crontab"
		echo "$freq         /bin/bash $me/mondaynet/mondaynet-setup.sh >$HOME/setup-log.txt 2>&1" >> /tmp/_cron
		crontab - < /tmp/_cron
	fi
fi

# Setup the network names for comparison
# On first run this will be empty
#
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

# Get the test network repos and determine the correct branch
# and network
#
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
		network=`echo $new | awk -F' ' '{print $3}'`
	fi
	rm -f $testnetfile
fi
echo $newbranch > "$HOME/branch.txt"

if [ "$branch" != "$newbranch" ]; then
	echo "Setting software branch old: $branch -> $newbranch"
	rm -f $HOME/tezos-$branch.tar.gz
fi


# Regardless, if .cleanup is there zero monday so that we reset
# on next run
#

if [ -f "$HOME/.cleanup" ]; then
	monday=""
fi

# Has the network changed?
#
echo $newmonday > $HOME/monday.txt
echo "$network" > $HOME/network.txt

if [ "$monday" != "$newmonday" ]; then
	echo "Network ID: $monday -> $newmonday"
	echo "New Period! Will reset wallet and node on next run."
	touch "$HOME/.resetwallet"
	touch "$HOME/.resetnode"

	echo "Terminating node software"
	# Terminate node gracefully
	#
	$killscript $startconf
	
	if [ -f "$HOME/.updatesoftware" ]; then
		echo "Update Baking Setup software"
		cd $me && git pull
	fi
	
	if [ -f "$HOME/.noreboot" ]; then
		# Let's not reboot then
		#
		echo "Restarting (without reboot)"
		/bin/bash $starter > $startlog 2>&1 &
		exit 0
	fi

	# Update OS - we sleep because sometimes we need to CTRL-C...
	#
	echo "Updating OS in 5 seconds"
	sleep 5
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get dist-upgrade -y

	echo "Rebooting in 15 seconds!"
	sleep 15
	# Reboot
	#
	sudo shutdown -r now "===Restart==="
else
	echo "Network has not changed - touch .cleanup to reset"
fi
