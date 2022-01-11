#!/bin/sh

killscript=$HOME/startup/kill.sh
startconf=$HOME/startup/mondaynet.conf

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

