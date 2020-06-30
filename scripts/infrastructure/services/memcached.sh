#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install memcached
export DEBIAN_FRONTEND=noninteractive

IP="$1"
# Fallback to allowing any if nothing is passed on (be carefull).
if [ "$IP" == "" ]; then
IP="0.0.0.0"
fi

sudo apt-get update
sudo apt-get install -y memcached libmemcached-tools python3 python3-pip
sudo pip3 install python3-memcached
sudo sed -i "s/-l 127.0.0.1/-l $IP/" /etc/memcached.conf
sudo systemctl enable memcached
sudo systemctl restart memcached
touch /.memcached.stamp
exit 0
