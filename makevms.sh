#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br


# date +%s | md5sum | head -c 6 | sed -e 's/\([0-9A-Fa-f]\{2\}\)/\1:/g' -e 's/\(.*\):$/\1/' | sed -e 's/^/52:54:00:/'
# perl -e 'for ($i=0;$i<5;$i++){@m[$i]=int(rand(256));} printf "02:%X:%X:%X:%X:%X\n",@m;'

op="$1"
name="$2"
PUBLIC_ADDRESS="10.32.45.215/24"
PUBLIC_GATEWAY="10.32.45.254"
PUBLIC_DNS="8.8.8.8,8.8.4.4"


create(){

name="$1"
case $name in
  gateway)IP="10.0.0.2";;
  storage)IP="10.0.0.3";;
  controller)IP="10.0.0.4";;
  kvm1)IP="10.0.0.5";;
  kvm2)IP="10.0.0.6";;
esac
if [ ! -d iso ]; then 
  mkdir iso
fi
wget -Lnc https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img -P iso/
# wget -Lnc https://releases.ubuntu.com/18.04/ubuntu-18.04.4-live-server-amd64.iso  -P iso/

if [ ! -d vms/$name ]; then 
  mkdir -p vms/$name; 
fi;

cp iso/ubuntu-18.04-server-cloudimg-amd64.img vms/$name/ubuntu18.qcow2
qemu-img resize vms/$name/ubuntu18.qcow2 32G
ssh-keygen -t rsa -b 4096 -N "" -f "vms/$name/key"


# Cloud-init files can be validated with: 
# cloud-init devel schema --config-file <file.yaml>

# openssl passwd -6 password ubuntu -salt 4096
cat > vms/$name/meta-data <<EOF
local-hostname: $name
EOF

cat > vms/$name/user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $(cat vms/$name/key.pub)
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
    passwd: $(openssl passwd -6 ubuntu)
    lock_passwd: false


write_files:
  - path:  /etc/netplan/02-management.yaml
    permissions: '0644'
    content: |
         network:
           version: 2
           renderer: networkd
           ethernets:
             ens4:
               link-local: []
               dhcp4: no
               addresses: [$IP/24]
               nameservers:
                 addresses: [8.8.8.8, 8.8.4.4]

EOF
if [ "$name" == "gateway" ]; then
cat >> vms/$name/user-data <<EOF               
  - path:  /etc/netplan/03-public-addr.yaml
    permissions: '0644'
    content: |
         network:
           version: 2
           renderer: networkd
           ethernets:
             ens5:
               dhcp4: no
               link-local: []
               addresses: [$PUBLIC_ADDRESS]
               gateway4: $PUBLIC_GATEWAY
               nameservers:
                 addresses: [$PUBLIC_DNS]
EOF
fi


cat >> vms/$name/user-data <<EOF

runcmd:
  - echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
  - sudo systemctl daemon-reload
  - sudo systemctl restart ssh
  - sudo truncate -s 0 /etc/machine-id
  - sudo rm /var/lib/dbus/machine-id
  - sudo ln -s /var/lib/dbus/machine-id /etc/machine-id
  - sudo netplan apply
  - sudo echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  - sudo echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  - sudo echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf  
  - sudo reboot

EOF
# - echo "network: {config: disabled}"  >  /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg  
# - systemd-machine-id-setup

chmod 600 vms/$name/key*

genisoimage \
-output vms/$name/$name-cidata.iso \
-volid cidata \
-joliet \
-rock vms/$name/user-data \
vms/$name/meta-data  
}

destroy() {
name="$1"
virsh destroy $name && virsh undefine $name
rm -rf vms/$name;
case $name in
  gateway)IP="10.0.0.2";;
  storage)IP="10.0.0.3";;
  controller)IP="10.0.0.4";;
  kvm1)IP="10.0.0.5";;
  kvm2)IP="10.0.0.6";;
esac

ssh-keygen -R $IP;
}


# ,mac=00:11
provision() {
name="$1"
if [ "$name" == "gateway" ]; then 
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 2048 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:99:E5:CB:35:F6 \
--network network=privatenet,model=virtio,mac=02:BC:B9:48:1C:DB \
--network bridge=br0,model=virtio,mac=02:EB:B6:5B:E5:3C \
--network bridge=br0,model=virtio,mac=02:6F:D5:DB:C2:1F \
--noautoconsole

elif [ "$name" == "storage" ]; then 
# Storage
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 4096 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--disk=pool=default,size=200,format=qcow2,bus=virtio \
--import \
--network network=default,model=virtio,mac=02:F7:19:76:5F:9C \
--network network=privatenet,model=virtio,mac=02:52:87:1F:6E:CB \
--network bridge=br0,model=virtio,mac=02:4:75:F:A9:D \
--network bridge=br0,model=virtio,mac=02:76:2:5B:CB:CC \
--noautoconsole

elif [ "$name" == "controller" ]; then 
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name $name \
--ram 16384 \
--vcpus=4 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:CE:57:2B:FB:C8 \
--network network=privatenet,model=virtio,mac=02:E5:83:72:DA:43 \
--network bridge=br0,model=virtio,mac=02:2F:4A:AB:29:29 \
--network bridge=br0,model=virtio,mac=02:CE:59:5D:5C:E3 \
--noautoconsole

# qemu -net nic,model=virtio,mac=... -net tap,ifname
elif [ "$name" == "kvm1" ]; then 
# KVM 1
# --enable-kvm \
virt-install \
--connect qemu:///system \
--virt-type kvm \
--accelerate \
--cpu host-passthrough \
--name $name \
--ram 8192 \
--vcpus=4 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:45:22:99:81:3C \
--network network=privatenet,model=virtio,mac=02:65:AC:8B:16:A2 \
--network bridge=br0,model=virtio,mac=02:24:5D:15:B5:ED \
--network bridge=br0,model=virtio,mac=02:50:9E:13:C8:0 \
--noautoconsole

elif [ "$name" == "kvm2" ]; then        
virt-install \
--connect qemu:///system \
--virt-type kvm \
--accelerate \
--cpu host-passthrough \
--name $name \
--ram 8192 \
--vcpus=4 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/$name/ubuntu18.qcow2,format=virtio \
--disk vms/$name/$name-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default,model=virtio,mac=02:DA:C5:C9:EA:90 \
--network network=privatenet,model=virtio,mac=02:6:32:DD:B8:69 \
--network bridge=br0,model=virtio,mac=02:31:F2:C5:F8:86 \
--network bridge=br0,model=virtio,mac=02:66:6B:D6:C1:3C \
--noautoconsole 
fi

echo "virsh domifaddr $name"

# MAX_TRIES=3
# addr=$(virsh domifaddr $name | awk 'NR==3{print $4}' | cut -d '/' -f 1)
# virsh domifaddr $name
# while [ "$addr" == "" ] && [ "$MAX_TRIES" -gt 0 ]; do
#   sleep 1
#   addr=$(virsh domifaddr $name | awk 'NR==3{print $4}' | cut -d '/' -f 1)
#   MAX_TRIES=$(($MAX_TRIES-1))
# done  
}

true_op="$1"
true_name="$2"
if [ "$op" == "-c" ]; then
create $true_name
elif [ "$op" == '-d' ]; then
destroy $true_name
elif [ "$op" == "-p" ]; then
provision $true_name
elif [ "$op" == "-dd" ]; then
set +e
destroy gateway
destroy storage
destroy controller
destroy kvm1
destroy kvm2
rm -rf vms

elif [ "$op" == "-a" ]; then
set +e
destroy gateway
destroy storage
destroy controller
destroy kvm1
destroy kvm2
rm -rf vms
create gateway
create storage
create controller
create kvm1
create kvm2

virsh net-destroy default
virsh net-start default
provision gateway
provision storage
provision controller
provision kvm1
provision kvm2

set -e
elif [ "$op" == "-k" ]; then
set +e
destroy gateway
destroy storage
destroy controller
destroy kvm1
destroy kvm2
rm -rf vms
create gateway
create storage
create controller
create kvm1
create kvm2

provision gateway
provision storage
provision controller
provision kvm1
provision kvm2  

fi
