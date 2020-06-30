#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Enables Zeroconf services

# The main purpose for installing this
# is for acessing the gateway machine
# which obtains (using a vagrantfile deployment)
# a DHCP Public (in the sense of bridge) network.
# Instead of using the everchanging DHCP IP Address
# You may access it through <Machine Name>.local
# This is possinle through Apple's Binjour and
# the avahi implementation of mDNS.

sudo apt-get update
sudo apt-get install -y avahi-daemon
sudo systemctl enable avahi-daemon
touch /.avahi.stamp
