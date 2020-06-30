#!/bin/bash -ex
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br

# Install IPTables Firwall
install_iptables() {
# Install IPTables
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
sudo apt-get install -y iptables iptables-persistent	
}

# Enables IPv4 Forwarding at the Kernel
enable_ip_forwarding() {
# Allow IPv4 Forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.autoconf = 0' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
# Send ICMP redirects (we ARE a router)
echo 'net.ipv4.conf.all.send_redirects = 1' >> /etc/sysctl.conf
# DO Accept IP source route packets (we ARE a router)
echo 'net.ipv4.conf.all.accept_source_route = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.accept_source_route = 1' >> /etc/sysctl.conf
sysctl -p
systemctl daemon-reload	
}


configure_nat() {
# NAT OUTGOING IP Addresses LAN -> Router -> WAN
iptables -t nat -A POSTROUTING -o $IWAN -j MASQUERADE
# Allow Forwarding LAN -> WAN
iptables -A FORWARD -i $ILAN -o $IWAN -j ACCEPT
#  Track connections from LAN <- Router <- WAN
iptables -A FORWARD -i $IWAN -o $ILAN -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -t nat -I POSTROUTING -s $IP/$MASK -j MASQUERADE
iptables-save > /etc/iptables/rules.v4 
}

KIND="$1" # Either 'router' or ''
shift

while [ $# -gt 0 ]; do
	case "$1" in
		--ip) shift; IP="$1"; shift;;
		--mask) shift; MASK="$1";shift;;
		--gateway) shift; GATEWAY="$1";shift;;
		--ilan) shift; ILAN="$1";shift;;
		--iwan) shift; IWAN="$1";shift;;
		*) echo "Unknown Parameter $1, exiting.."; exit 1;;
	esac
done

# Install IPTables Before making changes to the network
if [ "$KIND" == "router" ]; then
	install_iptables
fi

#Configure Interface
cat >> /etc/network/interfaces << EOF
auto $ILAN
iface $ILAN inet static
address $IP
netmask $MASK
$( if [ $KIND == host ]; then echo "post-up \
ip route replace default via $GATEWAY dev \
$ILAN metric 99"; \
else if [ ! $IWAN == '' ]; then \
	echo "post-up ip route add default dev $IWAN via $GATEWAY metric 99"; \
fi; fi )
EOF

ifdown "$ILAN" 2>&1 || true # Since the network interface might not be up
ip link set dev "$ILAN" down ; # Shut down 
ip addr flush "$ILAN"; # Flush its IP Address if any
ip link set dev "$ILAN" up; # Wake it up
ifup "$ILAN" # Load configuration

# If its a router, enable forwarding and configure NAT
if [ "$KIND" == "router" ]; then
	enable_ip_forwarding
	# it may not be needed to configure NAT, so don't.
	if [ ! "$IWAN" == "" ]; then
		configure_nat 
	fi
fi
# Which route will be taken to this address
# ip route get <address>
touch "/.routing.$ILAN.stamp";








