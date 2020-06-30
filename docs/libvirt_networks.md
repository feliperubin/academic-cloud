# Libvirt Networks


The following example creates a NAT network using the bridge br0.

1. Create a configuration File

```sh
cat <<EOF > custom_nat.xml
<network>
  <name>natnet</name>
  <forward mode='nat' dev='br0'/>
  <bridge name='natnet' stp='on' delay='2'/>
  <ip address='192.168.150.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.50.2' end='192.168.223.254'/>
      <host name='myclone3' ip='192.168.223.143'/>
    </dhcp>
  </ip>
</network>
EOF
```

2. Load the configuration file

```sh
virsh net-define custom_nat.xml
```

3. Start the network

```sh
virsh net-start natnet # After loading the file, the name inside it is used.
```

4. Set it to start at boot

```sh
virsh net-autostart natnet
```

5. Verify its functionality active, autostart, and persistent

```sh
virsh net-list --all
```



















