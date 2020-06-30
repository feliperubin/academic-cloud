#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install and Setup a DNS server using a given zonefile
# Installation
sudo apt-get update
sudo apt-get install -y dnsutils bind9 bind9utils	


FORWARDERS="8.8.8.8; 8.8.4.4;"
MAX_CACHE_SIZE="70" # Maximum Percentage of Memory that can be used for caching

# Zone
zone_file="$1"
reverse_zone_file="$2"

if [ "$zone_file" == "" ] || [ ! -f "$zone_file" ]; then
	zone_file=`find -name "*.db"`
	zone_file="$PWD/$zone_file"
fi

# Zone File Parsing
domaindb=$( basename "$zone_file" )
domain=${domaindb%.*}

# Reverse Zone File Parsing (Optional)
if [ ! -z "$reverse_zone_file" ]; then
	revdomaindb=$( basename "$reverse_zone_file" )
	revdomain=$(echo "$revdomaindb" | cut -d. -f2-)
fi

pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Enable to start at boot if not already
sudo systemctl enable bind9 || sudo service bind9 enable || true

# Stop the service to avoid erros while adding a zone
sudo systemctl stop bind9 || sudo service bind9 stop || true

# Copy the db to that path
sudo cp "$zone_file" "/etc/bind/$domaindb"

# Copy the rev. db to that path (Optional)
if [ ! -z "$reverse_zone_file" ]; then
	sudo cp "$reverse_zone_file" "/etc/bind/$revdomaindb"
fi

# Writes the file /etc/bind/rndc-key
sudo rndc-confgen -a

# Server configuration
sudo mkdir /etc/bind/dynamic

# Simplistic Configurations
sudo cat > /etc/bind/named.conf.options <<EOF
options {
	
	# Working directory
	directory "/var/cache/bind";
	
	# This is the default
	allow-query-cache {any;};
	allow-query { any; }; 

	# Cache size (10m,10kb,10%) defaults to 90% of memory
	max-cache-size $MAX_CACHE_SIZE%;

	# Provide Recursion
	recursion yes; 

	# Forwarding
	forwarders { $FORWARDERS };
	forward only;
	# Conform to RFC1035
	auth-nxdomain no; 
	dnssec-enable yes;
	dnssec-validation yes;

	/* Path to ISC DLV key */
	# bindkeys-file "/etc/named.iscdlv.key";

	managed-keys-directory "/etc/bind/dynamic";
	# listen-on { localhost; 127.0.0.1; My Public IP Address; };
	# listen-on {any;};
	listen-on port 53 {any;};
};

EOF

sudo cat > /etc/bind/named.conf.local << EOF
# 
#controls {
#	inet 127.0.0.1 port 953;
#	allow { 127.0.0.1; } keys { "rndc-key"; };
#};
// named.conf fragment
include "/etc/bind/rndc.key";
acl "rndc-users" {
	127.0.0.1;
	10.0.15.0/24;
	!10.0.16.1/32; // negated
	2001:db8:0:27::/64; // any address in subnet
 };

controls {
	// local host - default key
	inet 127.0.0.1 allow {localhost;};
	inet * port 7766 allow {"rndc-users";} keys {"rndc-key";};
};


# Master Zone File
zone "$domain" {
	type master;
	file "/etc/bind/$domaindb";
};

$( if [ ! -z "$reverse_zone_file" ]; then 
echo "# Master Reverse Zone File
zone "$revdomain.in-addr.arpa" {
  type master;
  file "/etc/bind/$revdomaindb";
};"; fi )

EOF

# Delete cache from first start
sudo rm -rf /var/cache/bind/*

# Fix a few more permissions
sudo chown bind:bind /etc/bind/named.conf.local
sudo chown root:bind /etc/bind/rndc.key

# Start bind9
sudo systemctl start bind9 || sudo service bind9 start || true
popd # Exist path

touch "/.bind.stamp" # Writes stamp
exit 0
