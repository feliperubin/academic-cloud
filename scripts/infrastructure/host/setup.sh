#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Setup a bit more exclusive than general.sh,
# only for the underlying infrastructure.

export DEBIAN_FRONTEND=noninteractive

apt-get install -y bridge-utils debootstrap \
ifenslave ifenslave-2.6 vlan python3

apt-get install -y python3-pip
pip3 install --upgrade pip setuptools
pip3 install --upgrade python-openstackclient

# Fixes neutron bridge error
pip3 install --upgrade msgpack-python

# apt-get install -y linux-modules-extra-$(uname -r) # Old  one
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-modules-extra-$(uname -r)
# DEBIAN_FRONTEND=noninteractive apt-get install -y linux-modules-extra-$(uname -r) && apt-get -y upgrade

echo 'bonding' >> /etc/modules
echo '8021q' >> /etc/modules



# Your interface is not in promiscous mode. Use:

# ip link set eth1 promisc on
# The flag will be updated to BMPRU. Flag details are as follows:

# B flag is for broadcast
# M flag is for multicast
# P flag is for promisc mode
# R is for running
# U is for up


# it is important to enable Promiscuous mode on eth1, the data traffic interfaces on both compute and controller node. Without this setting packets will not reach from OpenStack tenant VMs (that will be started inside the compute node), to the OpenStack controller.


touch /.host.setup.stamp
touch /.reboot.required.stamp
