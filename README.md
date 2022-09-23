# Baking start and stop scripts

The scripts in these directories can be used to start and stop
tezos nodes and bakers. Use at your own risk.

* start.sh <config> - starts a node/bakers as appropriate
* stop.sh <config>  - stops the node/bakers gracefully
* vacuum.sh <config> <snapshoturl> - stops the node, 
	imports a snapshot & restarts


See configs for example configurations. When setting up a baker,
I would setup a node first (with bake=0 in the configuration), sync
or import snapshots (etc), then delegate before restarting with
bake=1.

You can use cron: e.g.
```
@reboot		/home/me/bakingsetup/start.sh /home/me/bakingsetup/configs/baker.conf
```
or rc of course.

Really this work is published because of...

# Mondaynet, Ghostnet, Dailynet and other test networks setup

mondaynet contains setup and maintenance scripts for bakers running
on the mondaynet and dailynet networks. These were designed for use
on Ubuntu instances on AWS.

