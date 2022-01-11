#!/bin/sh

killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet.conf

# Terminate node gracefully
#
$killscript $startconf

# Update OS
#
sudo apt update
sudo apt upgrade -y

# Reboot
#
sudo shutdown -r now "===MondayNet Restart==="

