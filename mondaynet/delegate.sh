#!/bin/sh

# Assumes a mondaynet setup. Delegate from a faucet file and then
# save the keys in the right place for wallet resets.

key=`hostname -s`
walletdir="$HOME/wallet-$key"

if [ -f "$walletdir/public_keys" ]; then
	echo "Warning - already keys saved in $walletdir"
	exit 1
fi

if [ -f "faucet.json" ]; then
	$HOME/tezos/octez-client activate account $key with faucet.json
else
	# Generating Key
	$HOME/tezos/octez-client gen keys $key

	#
	$HOME/tezos/octez-client list known addresses

	echo "Please go to the faucet and get 6001tz"
	echo "Press ENTER when done"
	read STDIN
fi

mkdir -p $walletdir
cp ~/.tezos-client/*key* $walletdir
mv -f faucet.json $walletdir
echo "Please backup $walletdir safely!"

echo "Sleeping for 120 seconds"
sleep 120
# Self-delegating
echo "Self-delegating..."
$HOME/tezos/octez-client register key $key as delegate

