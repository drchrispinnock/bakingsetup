#!/bin/bash

# Defaults
#
buildroot=$HOME
gitrepos="https://gitlab.com/tezos/tezos.git"
branch=master
startscript=$HOME/startup/start.sh
startconf=$HOME/startup/mondaynet.conf

# Config
#
if [ -f "$HOME/monday.setup" ]; then
	. $HOME/monday.setup
fi

# Do not change these
#
builddir=$buildroot/tezos

# Check dependencies
#
if [ ! -d $HOME/.zcash-params ]; then
	# Fetch Zcash Params
	#
	wget https://raw.githubusercontent.com/zcash/zcash/master/zcutil/fetch-params.sh
	sh ./fetch-params.sh
fi

# Check first run
#
if [ ! -f "$HOME/.firstrun" ]; then
	sudo apt update
	sudo apt install -y rsync git m4 build-essential patch unzip wget pkg-config libgmp-dev libev-dev libhidapi-dev libffi-dev opam jq zlib1g-dev bc autoconf

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
	echo "===> Setting up software"
	mkdir -p "$buildroot"
	cd $buildroot
	git clone $gitrepos
	cd tezos
	opam init --bare --yes
fi

eval $(opam env) 

echo "===> Updating the branch"
cd $builddir
git checkout $branch
git pull
rm -rf _build _opam

echo "===> Rebuilding the software"
make build-deps && make

if [ ! -f tezos-node ]; then
	echo "XXX Build unsuccessful!"
	echo "EXITING"
	exit 1
fi

# Reset baking account
#
echo "===> Resetting baking accounts"
echo ""

sleep 5

# Start the node
#
echo "===> Starting the nodes and baking daemons"
echo ""

# Start the node
#
$startscript $startconf
