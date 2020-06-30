#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Rename Network Interfaces using a prefix
# Note: If a name is defined in netplan, it will override this changes.
# Prefix of the naming scheme, defaults to eth0,eth1,...,eth(n-1)
PREFIX="$1"
if [ "$PREFIX" == "" ]; then
	PREFIX="eth"
fi
# Gather all current physical interface names
ALL_INTERFACES=$(ls -ld /sys/class/net/* | grep -v "/devices/virtual" | grep "\->" | awk '{print $NF}' FS=/)
# Clear any existing configuration from a previous execution
rm -f /etc/udev/rules.d/70-persistent-net.rules
# Interface Index for its name
i=0
# Iterate every interface
for name_i in $ALL_INTERFACES; do
	# Get the interface mac address
	mac_i=$(cat "/sys/class/net/$name_i/address") # Interface mac address
	# Add maping PREFIX:index
	echo "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"$mac_i\", NAME=\"$PREFIX$i\"" >> \
	/etc/udev/rules.d/70-persistent-net.rules
	# Increment for the next name
	i=$((i+1))
done
touch /.prefixnics.stamp
touch /.reboot.required.stamp
