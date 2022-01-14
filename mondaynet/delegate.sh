key=`hostname -s`

if [ -f "faucet.json" ]; then
	./tezos/tezos-client activate account $key with faucet.json
	./tezos/tezos-client register key $key as delegate

	if [ -f "startup/mondaynet/wallet-$key/public_keys" ]; then
		echo "Warning - already keys in the repo"
	else
		cp ~/.tezos-client/*key* startup/mondaynet/wallet-$key
		mv faucet.json startup/mondaynet/wallet-$key
		cd startup/mondaynet/wallet-$key
		git add .
	fi
fi
