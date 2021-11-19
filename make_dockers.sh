#!/bin/sh

# You need:
#
# 1. A copy of the Tezos software in $dir
# 2. Suggest you opam init, make build-deps, etc
# 3. Install docker and docker.io
# 4. Run this on arm64 & x86 for the resultant dockers

dir=$HOME/tezos
dir=$HOME/idiazabalnet
repos=chrispinnock
basename=tezos-idiazabalnet
arch=`uname -m`
date=`date +%Y%m%d`

[ "$arch" = "x86_64" ] && arch=x86
[ "$arch" = "aarch64" ] && arch=arm64

cd $dir
git pull
make DOCKER_IMAGE_NAME=${repos}/${basename}-$arch DOCKER_IMAGE_VERSION=$date docker-image
docker push ${repos}/${basename}-$arch:$date
