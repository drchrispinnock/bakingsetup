#!/bin/sh

arch=`uname -m`
date=`date +%Y%m%d`
rootname="tezos-12rc1"
[ "$arch" = "x86_64" ] && arch=x86
[ "$arch" = "aarch64" ] && arch=arm64

cd $HOME/tezos
git pull
make DOCKER_IMAGE_NAME=chrispinnock/${rootname}-$arch DOCKER_IMAGE_VERSION=$date docker-image
docker push chrispinnock/${rootname}-$arch:$date
