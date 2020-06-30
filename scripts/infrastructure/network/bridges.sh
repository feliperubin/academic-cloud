#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Configures Network Bridge Kernel Module and Filters
# This must be configured on compute and controller nodes.

INTERFACE_NAME="$1" # The device it will be using eth2 for example
### PROVIDER INTERFACE
cat >> /etc/network/interfaces <<EOF
# The provider network interface
auto $INTERFACE_NAME
iface $INTERFACE_NAME inet manual
up ip link set dev \$IFACE up
down ip link set dev \$IFACE down
post-up ip link set \$IFACE promisc on
post-down ip link set \$IFACE promisc off
EOF

# BR Netfilter load at boot but
echo 'br_netfilter' >> /etc/modules
# Also must load them here
modprobe -a br_netfilter

# Do not load it now (doing sysctl -p), otherwise they will fail !
# reason: br_netfilter isn't loaded yet
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf	
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
echo "Please reboot the system !"
touch /.bridges.stamp
touch /.reboot.required.stamp

