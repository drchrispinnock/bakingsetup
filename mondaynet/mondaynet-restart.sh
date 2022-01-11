#!/bin/bash

# Restart a Mondaynet node
# Chris Pinnock
#
# Ming Vase license - if you break it, it will probably be expensive
# but you get to keep the pieces.
#
# Run me out of cron on a Monday


killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet/mondaynet.conf

# Terminate node gracefully
#
$killscript $startconf

# Cron will run this on a Monday... erm.
echo `date %Y-%m-%d` > $HOME/monday.txt 

# Update OS
#
sudo apt update
sudo apt upgrade -y

# Reboot
#
sudo shutdown -r now "===MondayNet Restart==="

