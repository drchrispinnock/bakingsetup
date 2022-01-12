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

# Config
#
if [ -f "$HOME/monday.setup" ]; then
	. $HOME/monday.setup
fi

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
	wget https://raw.githubusercontent.com/zcash/zcash/master/zcutil/fetch-params.sh
	sh ./fetch-params.sh
fi

if [ ! -d $HOME/.cargo ]; then
	rm -f "$HOME/.firstrun"
fi

# Check first run
#
if [ ! -f "$HOME/.firstrun" ]; then
	sudo apt-get update
	sudo apt-get install -y rsync git m4 build-essential patch unzip wget pkg-config libgmp-dev libev-dev libhidapi-dev libffi-dev opam jq zlib1g-dev bc autoconf

	echo "==> Installing rust"
	echo ""
	wget https://sh.rustup.rs/rustup-init.sh
	chmod +x rustup-init.sh
	./rustup-init.sh --profile minimal --default-toolchain 1.52.1 -y
	touch "$HOME/.firstrun"
	sleep 5
fi
. $HOME/.cargo/env

# Update the software to latest master branch of Octez
#
if [ ! -d $builddir ]; then
	rm -f "$HOME/.skipbuild"
	echo "===> Setting up software"
	mkdir -p "$buildroot"
	cd $buildroot
	git clone $gitrepos
	cd tezos
	opam init --bare --yes
fi


if [ ! -f "$HOME/.skipbuild" ]; then 
	eval $(opam env) 

	echo "===> Updating the branch"
	cd $builddir
	git checkout $branch
	git pull
	rm -rf _build _opam

	echo "===> Rebuilding the software"
	make build-deps
	if [ $? != "0" ]; then
		echo "XXX Failed to build dependencies"
		exit 1
	fi
	eval $(opam env) 
	make
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
	echo ""
	rm -rf "$HOME/.tezos-node"
	# XXX also pieces in tezos client
	sleep 5
fi
rm -f "$HOME/.skipreset"

# Start the node
#
echo "===> Starting the nodes and baking daemons"
echo ""

# Start the node
#
$startscript $startconf
