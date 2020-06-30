#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Set the configurations for a network interface.
IFACE="" # The interface name
DHCP="" # Use DHCP
IPV4="" # Set an IPv4 Address for the interface
MASK="" # Network mask, in the dotted form of 
GW="" # Gateway
DNS="" # A Domain Server or a list of domain servers
LOOPBACK="" # Loopback interface, for first time configuration.
SEARCH=""
# Mode:
# loopback - for first time configuration
# netplan - to use netplan yml files
# interfaces - to use ini/cfg files

mask2cidr() {
# Conversion from dotted a.b.c.d (used in interfaces) to /CIDR (used by netplan)
b1=$(echo "ibase=10;obase=2; $(echo "$MASK" | awk -F\. '{print $1}')" \
| bc | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')
b2=$(echo "ibase=10;obase=2; $(echo "$MASK" | awk -F\. '{print $2}')" \
| bc | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')
b3=$(echo "ibase=10;obase=2; $(echo "$MASK" | awk -F\. '{print $3}')" \
| bc | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')
b4=$(echo "ibase=10;obase=2; $(echo "$MASK" | awk -F\. '{print $4}')" \
| bc | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')
MASK=$(printf "${b1}${b2}${b3}${b4}" | awk '{sub("0.*","",$0);printf $0}' | wc -c)
}

MODE="$1"
shift
# Parse Input
while [ $# -gt 0 ]; do
   case "$1" in
      --ip) shift; IPV4="$1";shift;;
      --mask) shift; MASK="$1";shift;;
      --iface) shift; IFACE="$1";shift;;
      --dhcp) shift; DHCP="1"; shift;;
      --gw) shift; GW="$1"; shift;;
      --dns) shift; DNS="$1"; shift;;
      --search) shift; SEARCH="$1";shift;;
      *) echo "Argument $1 not recognized, skipped";shift;;
   esac
done


######################## SETUP USING INTERFACES ########################

if [ "$MODE" == "/etc/network/interfaces" ]; then

cat >> /etc/network/interfaces << EOF
auto $IFACE
iface $IFACE inet $(if [ "$DHCP" = "1" ]; then
   echo "dhcp"; 
else 
echo "static
   address $IPV4
   netmask $MASK
$( if [ ! -z "$IPV4" ]; then echo "   gateway $GW"; fi )
$( if [ ! -z "$DNS" ]; then echo "   dns-nameservers $DNS"; fi )
$( if [ ! -z "$SEARCH" ]; then echo "   dns-search $SEARCH"; fi )"
fi)
EOF

# Restart network interface
ip link set dev "$IFACE" down ; ip addr flush "$IFACE" ; ip link set dev "$IFACE" up

else

# Create Interface in netplan
mask2cidr
cat > $MODE << EOF
---
network:
   version: 2
   renderer: networkd
   ethernets:
      $IFACE:$(if [ "$DHCP" == "1" ]; then echo "dhcp4: true"; else echo "";fi)
         addresses: [$IPV4/$MASK]$(if [ ! "$GW" == "" ];then echo -e "\n         gateway4: $GW";fi)
         $(if [ ! "$SEARCH" == "" ] || [ ! "$DNS" == "" ]; then echo "nameservers:"; fi)
            $(if [ ! "$SEARCH" == "" ]; then echo "search: [$SEARCH]"; fi)
            $(if [ ! "$DNS" == "" ]; then echo "addresses: [$DNS]"; fi)
EOF
sudo netplan apply

fi

echo "/.dns.$IFACE.stamp"
