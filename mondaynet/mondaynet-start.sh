#!/bin/bash

# Start a Mondaynet node.
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.

# Run me out of cron at @reboot

# Defaults
#
buildroot=$HOME
gitrepos="https://gitlab.com/tezos/tezos.git"
branch=master
startscript=$HOME/startup/start.sh
startconf=$HOME/startup/mondaynet/mondaynet.conf
perlscript=$HOME/startup/mondaynet/last_monday.pl
wallet=$HOME/startup/mondaynet/wallet
buildlogs=$HOME/buildlogs

# Config
#
if [ -f "$HOME/monday.setup" ]; then
	. $HOME/monday.setup
fi
mkdir -p $buildlogs

# Do not change these
#
builddir=$buildroot/tezos

if [ -f "$HOME/.cleanup" ]; then
	echo "===> Cleaning up"
	rm -rf tezos rustup-init.sh monday.txt logs fetch-params.sh \
		.zcash-params .opam .rustup .cargo .cache $HOME/.cleanup \
		$HOME/.firstrun "$HOME/.skipbuild"
fi


# Check dependencies
#
if [ ! -d $HOME/.zcash-params ]; then
	# Fetch Zcash Params
	#
	wget https://raw.githubusercontent.com/zcash/zcash/master/zcutil/fetch-params.sh > $buildlogs/zcash.txt 2>&1
	sh ./fetch-params.sh >> $buildlogs/zcash.txt 2>&1
fi

if [ ! -d $HOME/.cargo ]; then
	rm -f "$HOME/.firstrun"
fi

# Check first run
#
if [ ! -f "$HOME/.firstrun" ]; then
	sudo apt-get update > $buildlogs/apt.txt 2>&1
	sudo apt-get install -y rsync git m4 build-essential patch unzip wget pkg-config libgmp-dev libev-dev libhidapi-dev libffi-dev opam jq zlib1g-dev bc autoconf >> $buildlogs/apt.txt 2>&1

	echo "==> Installing rust"
	wget https://sh.rustup.rs/rustup-init.sh > $buildlogs/rust.txt 2>&1
	chmod +x rustup-init.sh
	./rustup-init.sh --profile minimal --default-toolchain 1.52.1 -y >> $buildlogs/rust.txt 2>&1
	touch "$HOME/.firstrun"
fi
. $HOME/.cargo/env

# Update the software to latest master branch of Octez
#
rm -f $buildlogs/git.txt
if [ ! -d $builddir ]; then
	rm -f "$HOME/.skipbuild"
	echo "===> Setting up software"
	mkdir -p "$buildroot"
	cd $buildroot
	git clone $gitrepos >> $buildlogs/git.txt 2>&1
	cd tezos
	opam init --bare --yes > $buildlogs/opam.txt 2>&1
fi

eval $(opam env) 

if [ ! -f "$HOME/.skipbuild" ]; then 

	echo "===> Updating the branch"
	cd $builddir
	git checkout $branch >> $buildlogs/git.txt 2>&1
	git pull >> $buildlogs/git.txt 2>&1
	rm -rf _build _opam

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
fi
rm -f "$HOME/.skipbuild"

if [ ! -f "$builddir/tezos-node" ]; then
	echo "XXX No node binary!"
	echo "EXITING"
	exit 1
fi

if [ ! -f "$HOME/.skipreset" ]; then
	# Reset baking account
	#
	echo "===> Resetting node and baking"
	rm -rf "$HOME/.tezos-node"

	[ ! -d "$HOME/.tezos-client" ] && touch "$HOME/.resetwallet"

	if [ -f "$HOME/.resetwallet" ]; then
		echo "===> Resetting client folder"
		if [ -d "$wallet" ]; then
			rm -rf "$HOME/.tezos-client"
			cp -pR "$wallet" "$HOME/.tezos-client"
		fi
		rm "$HOME/.resetwallet"
	fi
fi
rm -f "$HOME/.skipreset"

# Start the node
#
echo "===> Starting the nodes and baking daemons"

# Start the node
#
$startscript $startconf
