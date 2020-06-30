#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Nested guest support in the KVM kernel module
# To enable nested KVM guests, your compute node must load the kvm_intel or kvm_amd module with nested=1.
# You can enable the nested parameter permanently, by creating a file named /etc/modprobe.d/kvm.conf and populating it with the following content:

# options kvm_intel nested=1
# options kvm_amd nested=1

export DEBIAN_FRONTEND=noninteractive
# Get the name of the first 'physical' interface
FIRST_INTERFACE=$(ls -ld /sys/class/net/* | grep -v "/devices/virtual" | head -n 1 | awk '{print $NF}' FS=/ )

# Get users to add permissions
TARGET_USER=$(ls /home)

sudo apt-get install -y xauth
echo ForwardX11 yes >> /etc/ssh/ssh_config
echo X11Fowarding yes >> /etc/ssh/ssh_config
echo XAuthLocation /usr/X11/bin/xauth >> /etc/ssh/ssh_config
echo 11UseLocalHost no >> /etc/ssh/ssh_config


# Install KVM
sudo apt-get update

if [[ "$OS_VERSION" =~ "16.04" ]]; then 
	# ubuntu 16 
	sudo apt-get install -y \
	qemu-kvm libvirt-bin virtinst bridge-utils 
else
	# ubuntu 18 and 20
	sudo apt-get install -y \
	qemu-kvm qemu libvirt-clients libvirt-bin bridge-utils virt-manager
fi

# virt-manager for gui

# Add Brige
if [ "$1" == "--with-bridge" ]; then
sudo cat > /etc/network/interfaces <<EOF
auto br0
iface lo inet loopback

iface $FIRST_INTERFACE inet manual

iface br0 inet dhcp
    bridge_ports $FIRST_INTERFACE
EOF
fi

# Allow user
chown root:kvm /dev/kvm
if ! [[ "$OS_VERSION" =~ "16.04" ]]; then 
sudo adduser "$TARGET_USER" libvirt
sudo adduser "$TARGET_USER" libvirt-qemu
fi
sudo adduser "$TARGET_USER" kvm
sudo modprobe kvm-intel
#sudo modprobe kvm-amd
#  kvm-intel at boot
echo 'kvm-intel' >> /etc/modules
# 
echo "Please reboot the system !"
touch /.kvm.stamp
touch /.reboot.required.stamp
exit 0
