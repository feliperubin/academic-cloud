#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Setup a clean Ubuntu with the minimum configuration required.

OPENSTACK_RELEASE="train"
export DEBIAN_FRONTEND=noninteractive
sudo locale-gen "en_US.UTF-8"
cat > /etc/default/locale << EOF
LANGUAGE=en_US.UTF-8
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LC_CTYPE=en_US.UTF-8
EOF
apt-get update
apt-get upgrade -y

# systemctlmask  apt-daily.service apt-daily-upgrade.service
# systemctl disable apt-daily.service apt-daily-upgrade.service
# systemctl disable apt-daily.timer apt-daily-upgrade.timer

systemctl stop apt-daily.timer
systemctl disable apt-daily.timer
systemctl mask apt-daily.service
systemctl daemon-reload
apt-get -y remove popularity-contest
# Requirements for OpenStack and Networking
yes '' | add-apt-repository cloud-archive:$OPENSTACK_RELEASE
apt-get update
apt-get install -y openssh-server sudo ifupdown tcpdump crudini traceroute tcptraceroute lsof lvm2 open-iscsi --fix-missing


# Required (Cloudinit image does not have do this automatically)
systemctl enable iscsid
systemctl start iscsid


# Additionally, the internal network interface must be in promiscuous mode, 
# so that it can receive packets whose target MAC address is the guest VM, not the host.

# Disable IPv6, otherwise an error occurs while creating a VM: 
#pyroute2.netlink.exceptions.NetlinkError: (13, 'Permission denied')
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf

# stop low-level messages on console
echo "kernel.printk = 4 1 7 4" >> /etc/sysctl.conf
# Allow ip forwarding. Should this be general ?
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf	
sysctl -p

touch /.host.general.stamp
touch /.reboot.required.stamp

