
FreeBSD 13.1 - Tezos Howto
--------------------------

The below worked on 13.1p1 however I've had problems on 13.1p2 during gmake.
If you want to live on a fair planet, don't choose this one.

# Binaries 

* http://downloads.chrispinnock.com/tezos/tezos-freebsd-13.tar.gz
* Please see step 7 below.

# Source

1. As root, install prerequise packages:
pkg install rsync m4 patch unzip wget gmp libev ocaml-opam gcc jq autoconf git gmake bash hidapi pkgconf

2. Run bash as a regular user

3. Install Rust

wget https://sh.rustup.rs/rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh --profile minimal --default-toolchain 1.60.0 -y
. $HOME/.cargo/env

4. get sources
git clone https://gitlab.com/tezos/tezos.git
cd tezos
git checkout latest-release

5. build the dependencies - use GNU make, not BSD make

Remove all --check from scripts/install_sapling_parameters.sh after sha256

opam init --bare
gmake build-deps

6. Build the binaries 
eval $(opam env)
gmake

7. To run:
sysctl -w net.inet6.ip6.v6only=0
Run the node as root. It does not connect to the network correctly
s a normal user as is. Configure as normal.
sudo ./tezos/tezos-node config init ....
sudo ./tezos/tezos-node run

Thanks to Roland for ktrace wizardry and socket guru-ness.
