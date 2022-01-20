#!/bin/bash

# Start a Mondaynet/Dailynet node.
# Chris Pinnock 2022
# MIT license

# Runs out of cron at boot or from the setup tool

# Defaults
#
buildroot=$HOME
me=$HOME/bakingsetup
gitrepos="https://gitlab.com/tezos/tezos.git"
startscript=$me/start.sh
buildlogs=$HOME/buildlogs

# Set this in localconfig.txt and put the binary tar there
# for download
warezserver=""

# Assume DailyNet unless the hostname contains mondaynet
#
testnet="dailynet"
grep mondaynet /etc/hostname
if [ "$?" = "0" ]; then
	testnet="mondaynet"
fi

# Configs can be overridden
#
if [ -f "$HOME/localconfig.txt" ]; then
	source $HOME/localconfig.txt
fi

# The repos is called mondaynet. The wallet should be backed up at
# delegation time. See delegation.sh
#
startconf=$me/mondaynet/mondaynet-common.conf
wallet=$HOME/wallet-`hostname -s`

mkdir -p $buildlogs

if [ -f "$HOME/branch.txt" ]; then
	branch=`cat $HOME/branch.txt`
else
	echo "XXX Branch not set - please run setup"
	exit 1
fi

warez="tezos-$branch.tar.gz"
warezurl="$warezserver/$warez"

echo "===> Starting setup"
echo "Network:      $testnet"
echo "Branch/tag:   $branch"
echo "Binary URL:   $warezurl"
sleep 2

# Do not change these
#
builddir=$buildroot/tezos

if [ -f "$HOME/.cleanup" ]; then
	echo "===> Cleaning up"
	rm -rf tezos rustup-init.sh logs fetch-params.sh \
		.zcash-params .opam .rustup .cargo .cache $HOME/.cleanup \
		"$HOME/.skipbuild" rustup-init.sh $warez $HOME/.stop
fi

if [ -f "$HOME/.stop" ]; then
	echo "STOP FILE DETECTED $HOME/.stop"
	exit 0
fi

# Check dependencies
#
if [ ! -d $HOME/.zcash-params ]; then
	# Fetch Zcash Params
	#
	wget https://raw.githubusercontent.com/zcash/zcash/master/zcutil/fetch-params.sh > $buildlogs/zcash.txt 2>&1
	sh ./fetch-params.sh >> $buildlogs/zcash.txt 2>&1
fi

# Prerequisites
#
echo "===> Installing prerequisites"
sudo apt-get update > $buildlogs/apt.txt 2>&1
sudo apt-get install -y rsync git m4 build-essential patch unzip wget pkg-config libgmp-dev libev-dev libhidapi-dev libffi-dev opam jq zlib1g-dev bc autoconf libjson-perl >> $buildlogs/apt.txt 2>&1

# Update the software to latest master branch of Octez
#
rm -f $buildlogs/git.txt
if [ ! -d $builddir ]; then
	rm -f "$HOME/.skipbuild"
fi

if [ ! -f "$HOME/.skipbuild" ]; then 
	
	echo "===> Cleaning sources and binaries"
	rm -rf $builddir	

	echo "===> Attempting to get binaries"

	if [ -f $warez ]; then
		echo "$warez found"
	else
		if [ "$warezurl" != "" ]; then
			wget -q $warezurl 
			if [ "$?" != "0" ]; then
				echo "---- fail - will build from scratch"
				touch "$HOME/.build"
			fi
		else
				echo "---- Will build from scratch"
				touch "$HOME/.build"

		fi
	fi
	if [ -f $warez ]; then
		tar zxf $warez
		rm -f "$HOME/.build"
	fi

fi
if [ -f "$HOME/.build" ]; then 
	echo "===> Cleaning sources and binaries"
	rm -rf $builddir	

	echo "===> Installing rust"
	wget https://sh.rustup.rs/rustup-init.sh > $buildlogs/rust.txt 2>&1
	chmod +x rustup-init.sh
	./rustup-init.sh --profile minimal --default-toolchain 1.52.1 -y >> $buildlogs/rust.txt 2>&1
	source $HOME/.cargo/env
	rm -f rustup-init.sh
	rm -f rustup-init.sh.?

	echo "===> Setting up software"
	mkdir -p "$buildroot"
	cd $buildroot
	git clone $gitrepos >> $buildlogs/git.txt 2>&1
	if [ "$?" != 0 ]; then
		echo "CANNOT GET SOURCES"
		exit 1
	fi
	cd tezos
	git checkout $branch >> $buildlogs/git.txt 2>&1
	opam init --bare --yes > $buildlogs/opam.txt 2>&1
	eval $(opam env) 

	echo "===> Rebuilding the software - build-deps"
	make build-deps > $buildlogs/builddeps.txt 2>&1
	if [ $? != "0" ]; then
		echo "XXX Failed to build dependencies"
		exit 1
	fi
	eval $(opam env) 
	echo "===> Rebuilding the software - main build"
	make > $buildlogs/make.txt 2>&1
	if [ $? != "0" ]; then
		echo "XXX Failed to build tezos"
		exit 1
	fi

	# Save the build
	#
	tar zcf tezos-$branch.tar.gz tezos/tezos-* tezos/active_protocol_versions tezos/active_testing_protocol_versions

	rm -f "$HOME/.build"
fi
rm -f "$HOME/.skipbuild"

if [ ! -f "$builddir/tezos-node" ]; then
	echo "XXX No node binary!"
	echo "EXITING"
	exit 1
fi
export PATH=$builddir:$PATH

if [ -f "$HOME/.resetnode" ]; then
	# Reset Node
	#
	echo "===> Resetting node"
	rm -rf "$HOME/.tezos-node"
	rm -f "$HOME/.resetnode"

	echo "===> Rotating logs"
	mv -f "$HOME/logs.1" "$HOME/logs.d"
	mv -f "$HOME/logs" "$HOME/logs.1"
	rm -rf "$HOME/logs.d"
	mkdir -p "$HOME/logs"
fi

# No wallet - attempt to restore it
#	
[ ! -f "$HOME/.tezos-client/public_keys" ] && touch "$HOME/.resetwallet"

if [ -f "$HOME/.resetwallet" ]; then
	echo "===> Resetting client folder"
	if [ -d "$wallet" ]; then
		rm -rf "$HOME/.tezos-client"
		mkdir -p "$HOME/.tezos-client"
		cp -pR $wallet/*key* "$HOME/.tezos-client"
	fi
	rm "$HOME/.resetwallet"
fi

# Start the node
#
echo "===> Starting the nodes and baking daemons"

# Start the node
#
$startscript $startconf
