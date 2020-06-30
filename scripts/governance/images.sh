#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# Add images to Glance
#
#
#
# https://docs.openstack.org/image-guide/obtain-images.html
# https://docs.openstack.org/python-openstackclient/pike/cli/command-objects/image.html
# Adding Images to Glance
# When an image is in status `queued` it doesn't mean the `upload` process is on-going. 
# That is to say that I can easily create an image and upload the data afterwards. For example:
pushd /tmp/
# Download debian image
wget -Lnc http://cdimage.debian.org/cdimage/openstack/current-9/debian-9-openstack-amd64.qcow2
# CirrOS(testing)
wget -Lnc http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
# Ubuntu 18.04 Minimal
# wget -Lnc https://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img
wget -Lnc https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img

# Ubuntu Image Here
# https://docs.openstack.org/image-guide/ubuntu-image.html

# x86_64-softmmu/qemu-system-x86_64 -boot c -drive file=/images/xpbase.qcow2,if=virtio -m 384 -netdev type=tap,script=/etc/kvm/qemu-ifup,id=net0 -device virtio-net-pci,netdev=net0
# container format: The supported options are: ami, ari, aki, bare, docker, ova, ovf
# disk format: ami, ari, aki, vhd, vmdk, raw, qcow2, vhdx, vdi, iso, and ploop

# --min-disk <disk-gb>¶
# Minimum disk size needed to boot image, in gigabytes
# --min-ram <ram-mb>¶
# Minimum RAM size needed to boot image, in megabytes
# --public vs --shared
# ubuntu desktop requires 1024MB RAM at least
#https://releases.ubuntu.com/18.04/ubuntu-18.04.4-live-server-amd64.iso
#https://releases.ubuntu.com/18.04/ubuntu-18.04.4-desktop-amd64.iso

. ~/adminrc
openstack image create "cirros" \
--container-format bare \
--disk-format qcow2 \
--shared \
--min-ram 512 \
--min-disk 5 \
--file cirros-0.5.1-x86_64-disk.img

# Create entry for image on glance
openstack image create "debian9" \
--container-format bare \
--disk-format qcow2 \
--shared \
--min-ram 512 \
--min-disk 10 \
--file debian-9-openstack-amd64.qcow2

openstack image create "ubuntu1804LTS" \
--container-format bare \
--disk-format qcow2 \
--shared \
--min-ram 4096 \
--min-disk 25 \
--file ubuntu-18.04-server-cloudimg-amd64.img

# Add image 'debian9' to project 'demo'
openstack image add project debian9 demo
openstack image add project cirros demo
openstack image add project ubuntu1804LTS demo
# openstack image set --unprotected Ubuntu18
# openstack image delete Ubuntu18


# When you use OpenStack with VMware vCenter Server,
# you need to specify the vmware_disktype and vmware_adaptertype 
# properties with glance image-create. Also, we recommend that you 
# set the hypervisor_type="vmware" property. For more information, 
# see Images with VMware vSphere in the OpenStack Configuration Reference.

# openstack image set \
#     --property hw_disk_bus=scsi \
#     --property hw_cdrom_bus=ide \
#     --property hw_vif_model=e1000 \
#     f16-x86_64-openstack-sda


# The hypervisor type. Note that qemu is used for both QEMU and KVM hypervisor types.	
# It does not accept architecture=x86_x64 ...
# --extra-args 'console=ttyS0,115200n8 serial'
openstack image set \
--property libvirt_type=kvm \
--property hw_disk_bus=scsi \
--property hw_cdrom_bus=ide \
--property hw_vif_model=e1000 \
--property architecture=amd64 \
--property hypervisor_type=qemu \
debian9

openstack image set \
--property libvirt_type=kvm \
--property hw_disk_bus=scsi \
--property hw_cdrom_bus=ide \
--property hw_vif_model=e1000 \
--property architecture=amd64 \
--property hypervisor_type=qemu \
cirros

openstack image set \
--property libvirt_type=kvm \
--property hw_disk_bus=scsi \
--property hw_cdrom_bus=ide \
--property hw_vif_model=e1000 \
--property architecture=amd64 \
--property hypervisor_type=qemu \
ubuntu1804LTS

popd

touch /.governance.images.stamp

