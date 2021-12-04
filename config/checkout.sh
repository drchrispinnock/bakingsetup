#!/bin/sh

repos=tezos-updater
prod="mainnet mainnet-snapshot"
for j in fra nrt pdx-ipv6 sin dub dub-ipv6; do
	prod="$prod production-$j"
done

branches="$prod alphanet zeronet master"

for i in $branches; do
	git clone git@github.com:tacoinfra/$repos.git
	mv $repos $i
	cd $i
	git checkout $i
	git pull
	cd ..

done
