#!/bin/sh

# Assumes a mondaynet setup

key=`hostname -s`
walletdir="$HOME/wallet-$key"

if [ -f "faucet.json" ]; then
	$HOME/tezos/tezos-client activate account $key with faucet.json
	$HOME/tezos/tezos-client register key $key as delegate

	if [ -f "$walletdir/public_keys" ]; then
		echo "Warning - already keys saved in $walletdir"
		exit 1
	else
		mkdir -p $walletdir
		cp ~/.tezos-client/*key* $walletdir
		mv faucet.json $walletdir
		echo "Please backup $walletdir safely!"
	fi
fi
