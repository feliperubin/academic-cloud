# Physical Host Setup

## 1. Install Utilities and Dependencies

For Remote Access
```sh
sudo apt-get install virt-manager ssh-askpass-gnome --no-install-recommends
```

(Optional) For monitoring the Host traffic
```sh
sudo apt-get install -y nload
```


For Infrastructure Automation you must install an up to date version of Ansible. The default one in Ubuntu 18 ~ 2.5 will not work.
```sh
# Install Ansible 2.8.3, might work on a lesser version.
# Only certainty is that it must be > 2.5
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
```

Open Ansible's configuration and edit the following parameter, otherwise it might not be able to connect to the Virtual Machines. This is equivalent to you doing `ssh-keygen -R <old-provisioned-server>`.
```sh
vim /etc/ansible/ansible.cfg
# Uncomment/Change to False
# uncomment this to disable SSH key host checking
host_key_checking = False
```


Install OpenStack CLI Python API.
```sh
sudo apt-get install -y python-pip
pip install --upgrade python-mysqlclient
```



## 2. Network Configurations

The host has four network Interfaces: eno1, eno2, eno3, eno4.

Host Network (eno1): First Physical Interface `/etc/netplan/01-netcfg.yaml`. Only used for managing the host.
```sh
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: no
      addresses: [10.32.45.219/24]
      gateway4: 10.32.45.254
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
```



Bridge Network (eno2): Second Physical Interface `/etc/network/interface`. Configured in order to enable the Gateway VM to act as it should.
```sh
source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback


# Public Bridge Network
#
iface eno2 inet manual

auto br0
iface br0 inet static
	hwaddress ether e0:db:55:20:e4:ed # eno2 interface mac
	address 10.32.45.216
	netmask 255.255.255.0
	gateway 10.32.45.254
	bridge_ports eno2
	bridge_stp off
	bridge_fd 0
```

Management Network: Virtual Switch `/etc/network/interface` with the sole purpose of providing a communication channel between the infrastructure virtual machines.
```sh
iface privatebr0 inet static
        address 10.0.0.1
        netmask 255.255.255.0
        pre-up    brctl addbr privatebr0
        post-down brctl delbr privatebr0
```

Notice that the previous interface does not have the `auto private0`, and it shouldn't. Libvirt will be the one managing it. So create the following file and register it with libvirt.
```sh
echo '<network> <name>privatenet</name> <bridge name="privatebr0" /> <ip address="10.0.0.1" netmask="255.255.255.0"> </network>' >> /tmp/net.xml
virsh net-define /tmp/net.xml
virsh net-start privatenet
virsh net-autostart privatenet
```

## 3. Kernel Configuration (Modules and Parameters)

Allow IP Forwarding
```sh
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
```

Load the following kernel module and also set sysctl parameters:
```sh
# https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf
# load the kernel module on boot
echo 'br_netfilter' >> /etc/modules
# Set kernel configurations. Most guides state that for security and performance reasons you should disable them. Performance is obvious, this makes it so that incoming packets at the bridge don't have to pass through iptables (netfilter) filters.
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-arptables = 1' >> /etc/sysctl.conf

# echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf 
# echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf

modprobe -a br_netfilter
sysctl -p
echo "Please reboot the system !"
```

KVM Nested Virtualization is required and should be enabled.
```sh
# https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
cat /sys/module/kvm_intel/parameters/nested
```

If it isn't enabled, you will have to shut down all running vms and unload the kvm_probe module:
```sh
modprobe -r kvm_intel
```

Activate the nesting feature:
```sh
modprobe kvm_intel nested=1
```

Enable it permanently by adding following line to the `/etc/modprobe.d/kvm.conf`
```sh
options kvm_intel nested=1 
# or
#  options kvm_amd nested=1 
```

## 4. Provisioning the Infrastructure.

We provide a simple script that will download the Ubuntu 18 iso and create virtual machines from it along with a keypair for each of them. We use the IP range of the `Management Network` to provision each VM. The next steps all regard this static range, so if you need to change it, you have to adapt them to your own configuration. Not to throw anyone in the jungle, at the end of this steps, there is an extra section describing how manually do the tasks automated by the provided script. All in all, if you have any problem with it, feel free to contact us.

Access the project root directory.
```sh
cd architecture
```

Verify you have enough resources by looking at each VM configuration, commands `virt-install`, defined at the `makevms.sh` script. Change them if you have fewer resources and/or require more. If you just change their RAM, vCPU or Disk sizes, you can still continue following these steps. The only requirement you must be aware is the specification of the Controller VM. It will be running services such as MySQL (mariadb) and others; hence if you lower its resource too much (e.g., 4GB only) the database will crash during the infrastructure configurations due to low memory resources.

To provision the environment, do the following.
```sh
chmod +x makevms.sh
./makevms.sh -a
# Wait for all VMs to Answer
ansible -i experiments/inventory.ini all -m  ping
# Provision the Cloud
ansible-playbook playbook.yml -i experiments/inventory.ini -vvvv
```

To destroy the environment, execute the following.
```sh
./makevms.sh -dd
```


## 5. Accessing VMs

If you have not changed anything, their static IP addresses for the Management Network should be:

- Host: 10.0.0.1
- Gateway: 10.0.0.2
- Storage: 10.0.0.3
- Controller: 10.0.0.4
- KVM1: 10.0.0.5
- KVM2: 10.0.0.6

You may want to connect through the NAT interface, which provides them with an address through DHCP. As a side note, we set their macaddresses to better handle DHCP address allocations when recreating the environment multiple times.

TO see their NAT interface IP
```sh
virsh list --all
virsh domifaddr gateway
```

If they did not receive any ip address for some reason you can edit the VM definition manually This should occur, but if it does, use the following command to open an editor.
```sh
# See more at https://wiki.libvirt.org/page/Networking#virsh_net-update
virsh edit gateway
```




## 6. Configuring the Management Network

Create netlan
```sh
vi /etc/netplan/51-cloud-init.yaml
```

```sh
network:
  version: 2
  renderer: networkd
  ethernets:
    ens4:
      dhcp4: no
      addresses: [10.32.45/24]
      gateway4: 10.0.0.1
```

## 7. Use the Host as a Compute Node (1/2)

Install the following dependencies
*Note* It's extremely important that you properly set your locale configurations. The next steps depend on it and will fail for sure otherwise.
```sh
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
systemctl stop apt-daily.timer
systemctl disable apt-daily.timer
systemctl mask apt-daily.service
systemctl daemon-reload
apt-get -y remove popularity-contest
# Requirements for OpenStack and Networking
yes '' | add-apt-repository cloud-archive:$OPENSTACK_RELEASE
apt-get update
apt-get install -y openssh-server sudo ifupdown tcpdump crudini traceroute tcptraceroute lsof lvm2 open-iscsi --fix-missing
```

(Optional) Install Collectd for Metrics and Promtail for Logs.

Install the Agents
```sh
# Metrics
sudo bash scripts/monitoring/collectd.sh --time "5s" --plugin "virt"
# Monitoring
sudo bash scripts/monitoring/promtail.sh "10.0.0.2"
```

Now ssh into the the Gateway, stop prometheus and then edit its targets; finally, restart the service.
```sh
sudo systemctl stop prometheus
# Edit the file by adding "10.0.0.1:9103", to the targets.
vim /etc/prometheus/prometheus.yaml
# Restart
sudo systemctl restart prometheus
```

Start iscsid and enable it during boot. Cinder provides volumes for compute nodes through iscsi.
```sh
systemctl enable iscsid
systemctl start iscsid
```

Create an L2 TAP Virtual Network Interface at `/etc/network/interfaces`. This interface will be connected to the same bridge the VMs are using. If you are wondering, `$IFACE` is an alias for the interface identifier defined at the line `iface IDENT`.
```sh
auto tap0
iface tap0 inet manual
pre-up ip tuntap add dev tap0 mode tap user root
up ip link set dev $IFACE up
down ip link set dev $IFACE down
post-up ip link set $IFACE promisc on
post-down ip link set $IFACE promisc off
```

Start the tap0 interface
```sh
ifup tap0
```

Install Nova Compute and Neutron Networking Services
```sh
sudo apt-get install -y nova-compute \
    neutron-linuxbridge-agent
```

Configure Nova Compute
```sh
scripts/openstack/service/config.sh \
nova \
--node "compute" \
--password "admin" \
--controller "10.0.0.4" \
--dbuser "nova" \
--dbpass "admin" \
--dbname "nova" \
--apidbname "nova_api" \
--placementpass "admin" \
--neutronpass "admin" \
--neutronsecret "admin" \
--managementip "10.0.0.1" \
--rabbituser "openstack" \
--rabbitpass "admin" \
--cfg "/etc/nova/nova.conf" \
api keystone_authtoken vnc glance \
oslo_concurrency placement neutron
```

Configure Neutron Networking
```sh
scripts/openstack/service/config.sh \
neutron \
--node "compute" \
--password "admin" \
--controller "10.0.0.4" \
--provideriface "tap0" \
--overlayifaceip "10.0.0.1" \
--novapass "admin" \
--dbuser "neutron" \
--dbpass "admin" \
--dbname "neutron" \
--neutronsecret "admin" \
--cfg "/etc/neutron/neutron.conf" \
--rabbituser "openstack" \
--rabbitpass "admin" \
keystone_authtoken oslo_concurrency
```




To finish nova installation, you must a few file permissions.
When loading Nova for the first time, it scans the host for any VM and overall resoueces it has and is using. This has to be done since Nova has to sync the host information with the rest of the Infrastructure. 
In cases where a host fails and recovers after some downtime, it can sync with the current state of the cloud. During this synchronization procedure, the libvirt image directory is scanned and, since we actually had provisioned resources previously (The infrastructure components, the directory as well as its files have the permission of the libvirtgroup and you user (root or not). 

In spite of this, the following will fix the permissions. Just make sure to also restart too.
```sh
chown -R nova:nova /var/lib/libvirt/images
systemctl restart libvirt
```

Then wait a few minutes for the Controller node to discover your new compute node. It will then appear on horizon. This host discovery occurs at a fixed interval, if you modified the scripts you might need to run the `scripts/openstack/
utils/host_discovery.sh` script at the controller node. There is only one last step required, which is described further.

## 8. Use the Host as a Compute Node (2/2)

After provisioning any VM through OpenStack which happens to be hosted on the physical host, the `tap0` interface will be added to a bridge created by `neutron`. The VM will have a vNIC from this bridge attached to it, but it can't contact the DHCP agent, or anything else. The reason is that the tap0 device is virtual, hence it has no physical NIC start with. There are probably better ways of doing this, but next we describe how to create a virtual ethernet cable (`veth`)which will connect the virtual bridge with the physical bridge `br0`, allowing the VM to access the network.

NOTE: This procedure requires the bridge to already exist. It will create a virtual patch cable between the two bridges. The virtual bridge t is created during the first time a guest is hosted on a compute node.

Create the virtual patch (veth) and add patch one side to the Infrastructure bridge (which other compute nodes are connected)
```sh
ip link add veth-br0 type veth peer name veth-tap0
brctl addif br0 veth-br0 
```

For the virtual bridge, you must find out what is the name of the bridge tap0 became a slave of. 
```sh
# Show Information on network device
ip link show dev tap0

# Output below. The name should be "brq-*", next to the keyword 'master'.
67: tap0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc fq_codel master brq2e6fc0c6-b1 state UP mode DEFAULT group default qlen 1000
    link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
```

Patch the other side to the virtual bridge using the name obtained with the previous command.
```sh
brctl addif brq2e6fc0c6-b1 veth-tap0 # In our case, its name is brq2e6fc0c6-b1
```

Start both sides
```sh
ip link set dev veth-br0 up
ip link set dev veth-tap0 up
```

And that's it. If you took too long your VM might have already booted with an address (gave up on the DHCP agent). Either access it through horizon and run `ifup -a` (or similar), or reboot it. Either way, from now on the network will behave as expected.

___

# Manually Creating VMs

## 1. Prepare Virtual Machine Disks

Create two folders:
```sh
mkdir iso
mkdir vms
```

Download and make copies of Ubuntu 18 Cloud Image
```sh
cd iso
wget -Lnc https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img
cd ..
```

Resize the downloaded iso to 10GB
```sh
qemu-img resize ubuntu-18.04-minimal-cloudimg-amd64.img  10G
```

Create copies of the original image for each VM. We are not using Linked Clones.
```sh
mkdir -p vms/gateway
cp iso/ubuntu-18.04-server-cloudimg-amd64.img vms/gateway/ubuntu18.qcow2
```

## 2. Create Cloud-Init Configuration

Create a metadata file
```sh
cat > vms/gateway/meta-data <<EOF
local-hostname: gateway
EOF
```
Create a keypair for SSH
```sh
ssh-keygen -t rsa -b 4096 -f vms/gateway/key
chmod 0600 vms/gateway/key*
```

Create a user-data file and inject the key generated moments ago.
```sh
PUBLIC_KEY=$(cat vms/gateway/key.pub)
cat > vms/gateway/user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $PUBLIC_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
runcmd:
  - echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
  - restart ssh
EOF
```

Merge all of the previous configuration in a single disk
```sh
genisoimage \
-output vms/gateway/gateway-cidata.iso \
-volid cidata \
-joliet \
-rock vms/gateway/user-data \
vms/gateway/meta-data \
vms/gateway/network-config
```

## 3. Provision the virtual Machine

First check if all networks were set up
```sh
virsh net-list --all
```

If the default is missing, create it.
```sh
echo > defaul.xml << EOF
<network>
  <name>default</name>
  <bridge name='virbr0' stp='on' delay='0'/>
  <forward mode="nat"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
    </dhcp>
  </ip>
</network>
EOF
```

Define using the file
```sh
virsh net-define default.xml
```

Start the network
```sh
virsh net-start default
```

Set to automatically start at boot
```sh
virsh net-autostart default 
```

Provision the Guest
```sh
# Tip: Nested Virtualization can be enabled using --accelerate
# Note: Its extremelhy important that you put the default network BEFORE the bridge
virt-install \
--connect qemu:///system \
--virt-type kvm \
--name gateway \
--ram 2048 \
--vcpus=2 \
--os-type linux \
--os-variant ubuntu18.04 \
--disk path=vms/gateway/ubuntu18.qcow2,format=virtio \
--disk vms/gateway/gateway-cidata.iso,format=raw,device=cdrom \
--import \
--network network=default \
--network bridge=br0,model=virtio \
--network network=privatenet \
--noautoconsole
```

Get the ip address
```sh
virsh domifaddr gateway
```

Destroys and Deletes the files from a VM
```sh
virsh destroy gateway && virsh undefine gateway
```




