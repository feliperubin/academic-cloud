# Using KVM

### Installing the CLI

To install the cli, execute the following
```sh
pip3 install --upgrade pip setuptools
pip3 install --upgrade python-openstackclient
```

### MacOS Installing virt-manager
```sh
# Install virt-manager for MacOS
brew tap jeffreywildman/homebrew-virt-manager
brew install virt-manager virt-viewer libvirt
# Install another dependency
mkdir /usr/local/Cellar/libosinfo/1.7.1/share/libosinfo
cd /usr/local/Cellar/libosinfo/1.7.1/share/libosinfo
wget -q -O pci.ids http://pciids.sourceforge.net/v2.2/pci.ids
wget -q -O usb.ids http://www.linux-usb.org/usb.ids

# This is how you connect to KVM !
virt-manager -c 'qemu+ssh://vagrant@10.0.0.3/system?socket=/var/run/libvirt/libvirt-sock&keyfile=.vagrant/machines/kvm1/parallels/private_key' --no-fork --debug
```
