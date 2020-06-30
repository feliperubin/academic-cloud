#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Installs and configures lvm (used by Cinder)

DEVICE="$1"
# Install LVM Requirements
sudo apt-get update && 
sudo apt-get install -y lvm2 thin-provisioning-tools

# Create the LVM physical volume /dev/sdb:
pvcreate "/dev/$DEVICE"
vgcreate cinder-volumes "/dev/$DEVICE"

# Edit the /etc/lvm/lvm.conf
FILTER="filter = [ \"a/$DEVICE/\", \"r/.*/\"]"
sed -i "/^devices {/a $FILTER" /etc/lvm/lvm.conf
touch "/.$DEVICE.lvm.stamp"
