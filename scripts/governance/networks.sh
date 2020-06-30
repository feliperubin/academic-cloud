#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Cloud Governance Network Setup


# Flat All instances reside on the same network, which can also be shared with the hosts. No VLAN tagging or other network segregation takes place.
# VLAN Networking allows users to create multiple provider or project networks using VLAN IDs (802.1Q tagged) that correspond to VLANs present in the physical network. This allows instances to communicate with each other across the environment. They can also communicate with dedicated servers, firewalls, load balancers, and other networking infrastructure on the same layer 2 VLAN.
# GRE and VXLAN VXLAN and GRE are encapsulation protocols that create overlay networks to activate and control communication between compute instances. A Networking router is required to allow traffic to flow outside of the GRE or VXLAN project network. A router is also required to connect directly-connected project networks with external networks, including the Internet. The router provides the ability to connect to instances directly from an external network using floating IP addresses.

# --internal: default configuration, creates a internal network.
# --share: allows all projects to use the virtual network.
# --external: defines the virtual network to be external. 

# --provider-physical-network provider 
# --provider-network-type flat

# connect the flat virtual network to the flat (native/untagged) 
# physical network on the eth1 interface on the host using information from the following files:

# /etc/neutron/plugins/ml2/ml2_conf.ini:
# [ml2_type_flat]
# flat_networks = provider
# # AND
# /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
# [linux_bridge]
# flat_networks = provider:eth1

PROVIDER_START=""
PROVIDER_END=""
PROVIDER_GW=""
PROVIDER=""

if [ -f ~/adminrc ]; then source ~/adminrc; fi

# Create an External Network (Shared with everyone): provider network
openstack network create \
--share \
--external \
--provider-physical-network provider \
--provider-network-type flat provider

# remove --external ?

# Create a subnet of ips that can be allocated
openstack subnet create \
--network provider \
--allocation-pool start=10.0.1.100,end=10.0.1.200 \
--dns-nameserver 8.8.8.8 \
--gateway 10.0.1.1 \
--subnet-range 10.0.1.0/24 provider


# Now create a self-service network
openstack network create selfservice


# Create a subnet for the self-service network
openstack subnet create \
--network selfservice \
--dns-nameserver 8.8.4.4 \
--gateway 172.12.0.1 \
--subnet-range 172.12.0.0/24 selfservice


# Create a new router
openstack router create router

# Add interface to selfserviceneutron router-port-list router
# neutron router-interface-add router selfservice
openstack router add subnet router selfservice

# Set its gateway as the provider network
# neutron router-gateway-set router provider # [DEPRECATED]
openstack router set \
--external-gateway provider \
router 
# [CURRENT]


# Creates floating ip
openstack floating ip create \
--description "Provides Internet Connectivity" \
provider

# Change the default configurations to enable both icmp and ssh
# openstack security group rule create --protocol icmp default
# openstack security group rule create --protocol tcp --dst-port 22:22 default


openstack security group create \
--description "You are the Law." \
wildwest

openstack security group rule create \
--ingress \
--remote-ip "0.0.0.0/0" \
--ethertype "IPv4" \
wildwest

openstack security group rule create \
--ingress \
--remote-ip "::/0" \
--ethertype "IPv6" \
wildwest

# Add default route
openstack router set --route destination=10.0.1.0/24,gateway=10.0.1.1 router
# openstack router unset --route destination=10.0.1.0/24,gateway=10.0.1.0 router

# Test connectivity
# ping -c 4 10.0.1.119
# openstack security group create \
# --description "Shell Access" \
# headless
# openstack router set --route destination=10.0.1.0/24,gateway=10.0.1.0 router

# Print it.
# neutron router-port-list router

# userwan --provider-network-type vxlan

# neutron agent-list
# neutron net-list
# nova service-list

# openstack subnet create subnet1 --network net1 --subnet-range 192.0.2.0/24

# openstack router create router1


# openstack router set ROUTER --external-gateway NETWORK

# openstack router add subnet ROUTER SUBNET

# openstack port create --network net1 --fixed-ip subnet=subnet1,ip-address=192.0.2.40 port1

# openstack port create port2 --network net1

# neutron port-list --fixed-ips ip_address=192.0.2.2 \
#   ip_address=192.0.2.40


touch /.governance.networks.stamp
