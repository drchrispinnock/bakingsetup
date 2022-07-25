#!/bin/sh

datadir="$HOME/rollup-data"
logdir="$HOME/toru-logs"
rollup="my_rollup"
batch="batch"
final="final"
remove="remove"

mkdir -p $logdir

if [ -f "$HOME/tezos/tx_rollup_protocol_versions" ]; then
	protocols=`cat $HOME/tezos/tx_rollup_protocol_versions`
fi

if [ -f "$HOME/tezos/script-inputs/tx_rollup_protocol_versions" ]; then
	protocols=`cat $HOME/tezos/script-inputs/tx_rollup_protocol_versions`
fi

# Wait for node to come up and bootstrap
#
echo "===> Waiting for node to bootstrap"
while [ 1 == 1 ]; do 
	$HOME/tezos/tezos-client bootstrapped >/dev/null 2>&1
	[ "$?" = "0" ] && break; 
	sleep 30
done


for protocol in $protocols; do
	if [ -x $HOME/tezos/tezos-tx-rollup-node-$protocol ]; then

		echo "===> $protocol"
		mydata="$datadir-$protocol"
		if [ ! -d "$mydata" ]; then
			echo "===> Initialising Toru node $protocol"
			$HOME/tezos/tezos-tx-rollup-node-$protocol \
			init operator config for $rollup \
			--data-dir $mydata  \
			--batch-signer $batch \
			--finalize-commitment-signer $final  \
			--remove-commitment-signer $final \
			--operator $remove \
			--rejection-signer $remove \
			--dispatch-withdrawals-signer $remove
		fi	
		echo "===> Running Toru node $protocol"

		$HOME/tezos/tezos-tx-rollup-node-$protocol \
			run operator for $rollup \
			--data-dir ${mydata} \
			--allow-deposit --rpc-addr 0.0.0.0:9999 \
			> ${logdir}/toru-$protocol.txt 2>&1 &
	fi
done

