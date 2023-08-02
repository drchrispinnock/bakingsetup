# Introduction

These scripts setup a rolling baker suitable for use on the Ghostnet, 
Mondaynet, Dailynet and other test networks.

# How to use this fine work

1. AWS: Setup an Ubuntu AWS host - t3.xlarge, 60GB SSD 
   GCP: Setup an equivalent GCP host from Debian 11/12

Although the scripts will attempt to update software, it is a good
idea to apt update && apt upgrade -y && apt dist-upgrade -y

Login to your host (e.g. ubuntu on AWS, you on GCP). On GCP create
a dedicated account e.g. ubuntu  as your personal account won't work 
properly with cron. This account needs root.

sudo su - ubuntu


2. Checkout the startup software in $HOME

```
sudo apt install git
git clone https://github.com/drchrispinnock/bakingsetup.git
```

3. Set your hostname to something suitable like mondaynet-oregon

edit /etc/hostname

The hostname needs to include the network name at the beginning.

Examples:

```
mondaynet
ghostnet-123
mondaynet-lon
dailynet-001
ithacanet-lon
kathmandunet-lon
```

4. Run mondaynet-setup.sh
```
bash ./bakingsetup/mondaynet/mondaynet-setup.sh
```
5. Wait. You can log back in on the reboot and look at start-log.txt
tail -f start-log.txt (usually complete in under 30 minutes)
tail -f logs/logfile

6. When the node is synced (this can take some time), generate a wallet.

Fund the wallet by going to https://teztnets.xyz/, using the appropriate
faucet and entering your address.

Then self-delegate. The account should be called the same as the hostname. 
We will use mondaynet-lon2 here. Use the HOSTNAME.

You can use the delegate.sh script in the repository for this step 
provided you have a faucet file in faucet.json. 

Or do it by hand:

```
./tezos/octez-client gen keys `hostname -s`
./tezos/octez-client list known addresses
mkdir ~/wallet-`hostname -s`
cp ~/.tezos-client/*key* ~/wallet-`hostname -s`
```

Go to the Faucet... then:

```
./tezos/octez-client register key `hostname -s` as delegate
```

7. Back the wallet directory up.

8. Restart

```
touch ~/.skipbuild
sudo shutdown -r now
```

9. The system will check testnets for an updated repository. If the
network changes, the system will reset.

Files in $HOME:

localconfig.txt - overrides for variables in the start scripts

.cleanup - if this exists cleanup all sources, rust and so on, and start
	from scratch. This does not clean tezos-node or client dirs though.

.reallycleanup - if this clean source tar balls and touch .cleanup

.skipbuild - if this exists, do not attempt to get the tezos software

.resetnode - if this exists, reset the node directory

.resetwallet - if this exists, attempt to move keys from this repos to
	the client wallet.

.noreboot  - do not reboot, just restart when the time is right

.updatesoftware - if it exists, attempt a git pull when updating

wallet-**hostname**     - the initial secret and public keys. These will
	be used to restore the wallet after a network reset.
