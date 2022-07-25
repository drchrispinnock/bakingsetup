#!/bin/sh

datadir="$HOME/rollup-data"
logdir="$HOME/toru-logs"
rollup="my_rollup"

mkdir -p $logdir

if [ -f "$HOME/tezos/tx_rollup_protocol_versions" ]; then
	protocols=`cat $HOME/tezos/tx_rollup_protocol_versions`
fi

if [ -f "$HOME/tezos/script-inputs/tx_rollup_protocol_versions" ]; then
	protocols=`cat $HOME/tezos/script-inputs/tx_rollup_protocol_versions`
fi

echo "Protocols: $protocols"

for protocol in $protocols; do
	if [ -x $HOME/tezos/tezos-tx-rollup-node-$protocol ]; then
		mydata="$datadir-$protocol"
		if [ ! -d "$mydata" ]; then
			echo "===> Initialising Toru node $protocol"
			$HOME/tezos/tezos-tx-rollup-node-$protocol \
			init operator config for $rollup \
			--data-dir $mydata  \
			--batch-signer batcher \
			--finalize-commitment-signer final  \
			--remove-commitment-signer final \
			--operator remove \
			--rejection-signer remove \
			--dispatch-withdrawals-signer remove
		fi	
		echo "===> Running Toru node $protocol"

		$HOME/tezos/tezos-tx-rollup-node-$protocol \
			run operator for $rollup \
			--data-dir ${mydata} \
			--allow-deposit --rpc-addr 0.0.0.0:9999 \
			> ${logdir}/toru-$protocol.txt 2>&1 &
	fi
done

