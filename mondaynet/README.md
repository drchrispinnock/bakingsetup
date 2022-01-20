# Introduction

These scripts setup a rolling baker suitable for use on the Mondaynet
and Dailynet test networks.

# How to use this fine work

1. Setup an Ubuntu AWS host - t3.xlarge, 60GB SSD
Although the scripts will attempt to update software, it is a good
idea to apt update, apt upgrade -y && apt dist-upgrade -y

2. Checkout the startup software in $HOME

git clone https://github.com/drchrispinnock/bakingsetup.git

3. Set your hostname to something suitable like mondaynet-oregon

edit /etc/hostname

The hostname needs to include mondaynet or dailynet.

4. Run mondaynet-setup.sh <branch>
e.g. bash ./bakingsetup/mondaynet/mondaynet-setup.sh
e.g. bash ./bakingsetup/mondaynet/mondaynet-setup.sh d0bf56ce

5. Wait. You can log back in on the reboot and look at start-log.txt
tail -f start-log.txt (usually complete in under 30 minutes)
tail -f logs/logfile

6. When the node is synced (this can take some time) get a account from 
the faucet and self-delegate. The account should be called the same 
as the hostname. We will use mondaynet-lon2 here. Use the HOSTNAME.

Go to https://teztnets.xyz/ and go to the latest faucet for mondaynet
Download a json file. Save it as faucet.json on the server.

You can use the delegate.sh script in the repository for this step 
provided you have a faucet file in faucet.json. Or do it by hand:

./tezos/tezos-client activate account mondaynet-lon2 with faucet.json
./tezos/tezos-client register key mondaynet-lon2 as delegate

mkdir ~/wallet-mondaynet-lon2
cp ~/.tezos-client/*key* ~/wallet-mondaynet-lon2
cp ~/faucet.json ~/wallet-mondaynet-lon2

Back this directory up.

7. Restart
touch ~/.skipbuild
sudo shutdown -r now

8. The system will check testnets for an updated repository. If the
network changes, the system will reset.

Files:
mondaynet-common.conf - a common configuration file that should work
	for all instances, based on hostnames. The key should be called
	the same as the hostname.

~/wallet-<hostname>     - the initial secret and public keys. These will
	be used to restore the wallet after a network reset.


$HOME files
===========

monday.setup - overrides for variables in the start scripts

.cleanup - if this exists cleanup all sources, rust and so on, and start
	from scratch. This does not clean tezos-node or client dirs though.

.skipbuild - if this exists, do not attempt to get the tezos software

.resetnode - if this exists, skip resetting the node directory

.resetwallet - if this exists, attempt to move keys from this repos to
	the client wallet.
.noreboot  - do not reboot, just restart when the time is right

