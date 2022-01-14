#!/bin/sh

network=mondaynet
buildid=`cat branch.txt`

tar zcvf $network-$buildid.tar.gz tezos/tezos-* tezos/active_protocol_versions tezos/active_testing_protocol_versions
