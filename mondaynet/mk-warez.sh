#!/bin/sh

buildid=`cat branch.txt`

tar zcvf tezos-$buildid.tar.gz tezos/tezos-* tezos/active_protocol_versions tezos/active_testing_protocol_versions
