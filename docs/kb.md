# Project Knowledge Base (KB)


## Netplan Disrespects Sysctl Disabling IPv6 

**Problem**

Even after disabling ipv6 with sysctl, netplan interfaces still try to use it.

**Cause**

Netplan ignores sysctl configurations.


**Solution**

Netplan is the root cause of all major networking problems for advanced configurations. Although over the years they are implementing new features such as support for bridges and more recently scripts (e.g, post-up/pre-up) , even if it is described as the "future" of linux networking it is undoubtely an immature network manager. Hence you have to explicitly disable its control over link-local.

Add the empty `link-local: []` to your configurations.
```sh
network:
    ethernets:
        ens3:
            dhcp4: true
            link-local: [] # HERE
            match:
                macaddress: 52:54:00:d6:b4:18
            set-name: ens3
    version: 2
```


## No DNS after upgrading Ubuntu

**Problem**

After a major relase upgrade (e.g., 16 to 18) there is name resolution.

**Cause**
There is a bug caused probably by a conflict of dependencies while installing the upgrade.

**Solution**

From [Linode Forums](https://www.linode.com/community/questions/17081/dns-stops-resolving-on-ubuntu-1804)
From [Askubuntu](https://askubuntu.com/questions/966870/dns-not-working-after-upgrade-17-04-to-17-10)

Do the following:
```sh
sudo rm /etc/resolv.conf
sudo ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
systemctl restart resolvconf
```


## Vagrant Problem - vboxnetX private IP

**Problem**
Vagrant complains about existing interface having an IP conflict with hostonly to public/private.

**Cause**

Priviously, an interface was created either with Vagrant, or manually.

**Solution**

Delete the Interface
```sh
VBoxManage hostonlyif remove vboxnetX
```

## KVM Nested Virtualization

**Problem**

No network connection and/or extremely slow KVM virtual machines.

**Cause**

Nested Virtualization support is expected.

**Solution**

Enable KVM Nested Virtualization [Guide](https://wiki.archlinux.org/index.php/KVM).

## Vagrant Provisioning With Parallels [issue](https://github.com/Parallels/vagrant-parallels/issues/357)

**Problem**

If running vagrant provisioning with the Paralllels Desktop Hypervisor, do not run it in parallel.

**Cause**

Unknown at the moment of this writing, an issue ticket has been created at Parallels official github repository.

**Solution**

If not running the provider Vagrantfile and instead using a custom one, you must use the `--no-parallel` flag.

##  Neutron Issue with MariaDB [issue](https://bugs.launchpad.net/neutron/+bug/1855912)

**Problem**

Neutron Installation Fails with
```bash
oslo_db.exception.DBError: (pymysql.err.InternalError) (1832, \"Cannot change column 'network_id': used in a foreign key constraint 'subnets_ibfk_1'\") [SQL: 'ALTER TABLE subnets MODIFY network_id VARCHAR(36) NOT NULL'] 
```

**Cause**

Ubuntu 18.04LTS ships with MariaDB 10.1 as the default apt package. 
This version has a bug which has been fixed in 10.4.

**Solution**

WARNING this will purge all the data residing on any mariadb installation.

If you installed mariadb before, remove it. 
```sh
apt-get remove mariadb-server
apt purge mariadb-common
```
Add the repository and install the newer version of MariaDB >= 10.4
```sh
sudo apt-get install -y software-properties-common
sudo apt update;
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
apt-get update;
```

## There was a crudini command which didn't have all parameters.

**Problem**

```sh
fatal: [control1]: FAILED! => {"changed": true, "failed_when_result": true, "msg": "non-zero return code", "rc": 1, "stderr": "Shared connection to 10.0.0.7 closed.\r\n", "stderr_lines": ["Shared connection to 10.0.0.7 closed."], "stdout": "A utility for manipulating ini files\r\n\r\nUsage: crudini --set [OPTION]...   config_file section   [param] [value]\r\n  or:  crudini --get [OPTION]...   config_file [section] [param]\r\n  or:  crudini --del [OPTION]...   config_file section   [param] [list value]\r\n  or:  crudini --merge [OPTION]... config_file [section]\r\n\r\nOptions:\r\n\r\n  --existing[=WHAT]  For --set, --del and --merge, fail if item is missing,\r\n                       where WHAT is 'file', 'section', or 'param', or if\r\n                       not specified; all specified items.\r\n  --format=FMT       For --get, select the output FMT.\r\n                       Formats are sh,ini,lines\r\n  --inplace          Lock and write files in place.\r\n                       This is not atomic but has less restrictions\r\n                       than the default replacement method.\r\n  --list             For --set and --del, update a list (set) of values\r\n  --list-sep=STR     Delimit list values with \"STR\" instead of \" ,\"\r\n  --output=FILE      Write output to FILE instead. '-' means stdout\r\n  --verbose          Indicate on stderr if changes were made\r\n", "stdout_lines": ["A utility for manipulating ini files", "", "Usage: crudini --set [OPTION]...   config_file section   [param] [value]", "  or:  crudini --get [OPTION]...   config_file [section] [param]", "  or:  crudini --del [OPTION]...   config_file section   [param] [list value]", "  or:  crudini --merge [OPTION]... config_file [section]", "", "Options:", "", "  --existing[=WHAT]  For --set, --del and --merge, fail if item is missing,", "                       where WHAT is 'file', 'section', or 'param', or if", "                       not specified; all specified items.", "  --format=FMT       For --get, select the output FMT.", "                       Formats are sh,ini,lines", "  --inplace          Lock and write files in place.", "                       This is not atomic but has less restrictions", "                       than the default replacement method.", "  --list             For --set and --del, update a list (set) of values", "  --list-sep=STR     Delimit list values with \"STR\" instead of \" ,\"", "  --output=FILE      Write output to FILE instead. '-' means stdout", "  --verbose          Indicate on stderr if changes were made"]}

```
**Cause**

Missing Crudini Arguments

**Solution**

Fix the parameter: 
```sh
crudini --set "<file>" <section> <key> <value>
```

## Access Denied for OpenStack Service on Database

**Problem**

Access Denied for MariaDB 
```sh
pymysql.err.OperationalError) (1045, \"Access denied for user 'neutron'@'10.0.0.7' (using password: YES)\")
```
**Cause**

You may have passed on the wrong password.

**Solution**

Ensure that all credentials are correct. 
A tip is to `set -x` on the shell/bash script so that you know which values each variable hold.

## Keystone Installation Fails at keystone-manage ( NO SOLUTION ATM )

**Problem**

The keystone-manage db synchronization command fails.
```sh
su -s /bin/sh -c 'keystone-manage db_sync' keystone"
```

**Cause**

MariadB 10.4 is not supported.
Lost connection to MySQL server during query
/etc/keystone/keystone-manage.log
```sh
oslo_db.exception.DBConnectionError: (pymysql.err.OperationalError) (2013, 'Lost connection to MySQL server during query') [SQL: 'ALTER TABLE user ADD CONSTRAINT ixu_user_name_domain_id UNIQUE (domain_id, name)'] (Background on this error at: http://sqlalche.me/e/e3q8)
```

**Solution**

### ALternative 1

Add/Edit the following to your `[mysqld]` configuration either at  `/etc/mysql/my.cnf` or on a file it imports, for example /etc/mysql/mariadb.conf.d/<your_config_name>.cnf

```sh
# SAFETY #
max-allowed-packet = 32M
net-read-timeout = 60
```

https://bugs.launchpad.net/openstack-ansible/+bug/1719791
https://review.opendev.org/#/c/507789/4/templates/my.cnf.j2

### Alternative 2

Try to resynchronize
```sh
su -s /bin/bash -c "keystone-manage db_sync" keystone
```

### Alternative 3

Increase max packet size
```sh
max_allowed_packet=64M
```

## Neutron Linuxbridge encoding Fail

**Problem**

Debugging cat /var/log/syslog provides the following error
```sh
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 CRITICAL privsep [-] Unhandled error: TypeError: __init__() got an unexpected keyword argument 'encoding'
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep Traceback (most recent call last):
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep   File "/usr/bin/privsep-helper", line 10, in <module>
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep     sys.exit(helper_main())
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep   File "/usr/lib/python3/dist-packages/oslo_privsep/daemon.py", line 538, in helper_main
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep     channel = comm.ServerChannel(sock)
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep   File "/usr/lib/python3/dist-packages/oslo_privsep/comm.py", line 189, in __init__
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep     self.reader_iter = iter(Deserializer(sock))
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep   File "/usr/lib/python3/dist-packages/oslo_privsep/comm.py", line 69, in __init__
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep     unicode_errors='surrogateescape')
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep   File "msgpack/_unpacker.pyx", line 317, in msgpack._cmsgpack.Unpacker.__init__
May 29 13:36:04 kvm1 neutron-linuxbridge-agent[2041]: 2020-05-29 13:36:04.776 2077 ERROR privsep TypeError: __init__() got an unexpected keyword argument 'encoding'
```

**Cause**

Previous package named msgpack has been replaced with another [yahoo engineering mail-archive](https://www.mail-archive.com/yahoo-eng-team@lists.launchpad.net/msg80090.html).

This is because in 16.0.0 the deprecated list_extensions code was removed [breaking changes](https://docs.openstack.org/releasenotes/python-novaclient/unreleased.html#upgrade-notes).

To manage notifications about this bug subscribe [horizon launchpad](https://bugs.launchpad.net/horizon/+bug/1849351/+subscriptions).

**Solution**

Install missing dependency:

```sh
pip3 install msgpack-python
```

## Failed to Allocate the Network(s), not rescheduling.

**Problem**

```sh
Build of instance fc5821d7-a193-4912-a02b-8b6be9cffda9 aborted: Failed to allocate the network(s), not rescheduling.
Code
500
Details
Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/virt/libvirt/driver.py", line 6233, in _create_domain_and_network network_info) File "/usr/lib/python3.6/contextlib.py", line 88, in __exit__ next(self.gen) File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 478, in wait_for_instance_event actual_event = event.wait() File "/usr/lib/python3/dist-packages/eventlet/event.py", line 125, in wait result = hub.switch() File "/usr/lib/python3/dist-packages/eventlet/hubs/hub.py", line 298, in switch return self.greenlet.switch() eventlet.timeout.Timeout: 300 seconds During handling of the above exception, another exception occurred: Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2419, in _build_and_run_instance block_device_info=block_device_info) File "/usr/lib/python3/dist-packages/nova/virt/libvirt/driver.py", line 3474, in spawn power_on=power_on) File "/usr/lib/python3/dist-packages/nova/virt/libvirt/driver.py", line 6254, in _create_domain_and_network raise exception.VirtualInterfaceCreateException() nova.exception.VirtualInterfaceCreateException: Virtual Interface creation failed During handling of the above exception, another exception occurred: Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2143, in _do_build_and_run_instance filter_properties, request_spec) File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2485, in _build_and_run_instance reason=msg) nova.exception.BuildAbortException: Build of instance fc5821d7-a193-4912-a02b-8b6be9cffda9 aborted: Failed to allocate the network(s), not rescheduling.
Created
June 3, 2020, 5:59 a.m.
```

**Cause**

IPv6 is Enabled, it should be. If you are using linux bridges, the package turns it off during installation, but you may have accidentally turned it on. 

**Solution**

```sh
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p
```


## DN Resolution Stops working on Ubuntu 16.04.6 LTS

**Problem**

You are configuring your own interfaces at `/etc/network/interfaces` but your domain name resolver randomly stops working.

**Cause**

Another ocnfiguration on Network Manager may be the culprit.

**Solution**

Uninstall network manager and use only ifconfig scripts.

```sh
sudo apt-get remove --purge network-manager-gnome network-manager -y
sudo /etc/init.d/networking restart
```


## Instance Creation Failed to Create Cinder Volume

**Problem**

Erro Creating Volume with a message similar to:

	> Error: Failed to perform requested operation on instance "Jupyter-CS101-1", the instance has an error status: Please try again later [Error: Build of instance dcc47096-6cff-4f03-bbae-404468d6dac5 aborted: Invalid input received: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-4fc2162c-b19e-49a5-9055-dfe240cf7b9a)].

	>  Build of instance 818b90e4-8803-46be-a21b-4694d8162cd4 aborted: Invalid input received: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-e4f5ddd4-2418-4e4c-9a59-566620d65d3c) Code 500 Details Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 397, in wrapper res = method(self, ctx, *args, **kwargs) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 433, in wrapper res = method(self, ctx, volume_id, *args, **kwargs) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 629, in initialize_connection exc.code if hasattr(exc, 'code') else None)}) File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 220, in __exit__ self.force_reraise() File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 196, in force_reraise six.reraise(self.type_, self.value, self.tb) File "/usr/lib/python3/dist-packages/six.py", line 693, in reraise raise value File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 603, in initialize_connection context).volumes.initialize_connection(volume_id, connector) File "/usr/local/lib/python3.6/dist-packages/cinderclient/v2/volumes.py", line 406, in initialize_connection {'connector': connector}) File "/usr/local/lib/python3.6/dist-packages/cinderclient/v2/volumes.py", line 336, in _action resp, body = self.api.client.post(url, body=body) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 215, in post return self._cs_request(url, 'POST', **kwargs) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 203, in _cs_request return self.request(url, method, **kwargs) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 189, in request raise exceptions.from_response(resp, body) cinderclient.exceptions.BadRequest: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-e4f5ddd4-2418-4e4c-9a59-566620d65d3c) During handling of the above exception, another exception occurred: Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 1905, in _prep_block_device wait_func=self._await_block_device_map_created) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 882, in attach_block_devices _log_and_attach(device) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 879, in _log_and_attach bdm.attach(*attach_args, **attach_kwargs) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 777, in attach context, instance, volume_api, virt_driver) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 46, in wrapped ret_val = method(obj, context, *args, **kwargs) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 666, in attach virt_driver, do_driver_attach) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 639, in _do_attach do_driver_attach) File "/usr/lib/python3/dist-packages/nova/virt/block_device.py", line 470, in _legacy_volume_attach connector) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 405, in wrapper _reraise(exception.InvalidInput(reason=err_msg)) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 483, in _reraise six.reraise(type(desired_exc), desired_exc, sys.exc_info()[2]) File "/usr/lib/python3/dist-packages/six.py", line 692, in reraise raise value.with_traceback(tb) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 397, in wrapper res = method(self, ctx, *args, **kwargs) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 433, in wrapper res = method(self, ctx, volume_id, *args, **kwargs) File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 629, in initialize_connection exc.code if hasattr(exc, 'code') else None)}) File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 220, in __exit__ self.force_reraise() File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 196, in force_reraise six.reraise(self.type_, self.value, self.tb) File "/usr/lib/python3/dist-packages/six.py", line 693, in reraise raise value File "/usr/lib/python3/dist-packages/nova/volume/cinder.py", line 603, in initialize_connection context).volumes.initialize_connection(volume_id, connector) File "/usr/local/lib/python3.6/dist-packages/cinderclient/v2/volumes.py", line 406, in initialize_connection {'connector': connector}) File "/usr/local/lib/python3.6/dist-packages/cinderclient/v2/volumes.py", line 336, in _action resp, body = self.api.client.post(url, body=body) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 215, in post return self._cs_request(url, 'POST', **kwargs) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 203, in _cs_request return self.request(url, method, **kwargs) File "/usr/local/lib/python3.6/dist-packages/cinderclient/client.py", line 189, in request raise exceptions.from_response(resp, body) nova.exception.InvalidInput: Invalid input received: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-e4f5ddd4-2418-4e4c-9a59-566620d65d3c) During handling of the above exception, another exception occurred: Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2630, in _build_resources block_device_mapping) File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 1923, in _prep_block_device raise exception.InvalidBDM(six.text_type(ex)) nova.exception.InvalidBDM: Invalid input received: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-e4f5ddd4-2418-4e4c-9a59-566620d65d3c) During handling of the above exception, another exception occurred: Traceback (most recent call last): File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2161, in _do_build_and_run_instance filter_properties, request_spec) File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2471, in _build_and_run_instance bdms=block_device_mapping, tb=tb) File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 220, in __exit__ self.force_reraise() File "/usr/local/lib/python3.6/dist-packages/oslo_utils/excutils.py", line 196, in force_reraise six.reraise(self.type_, self.value, self.tb) File "/usr/lib/python3/dist-packages/six.py", line 693, in reraise raise value File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2421, in _build_and_run_instance request_group_resource_providers_mapping) as resources: File "/usr/lib/python3.6/contextlib.py", line 81, in __enter__ return next(self.gen) File "/usr/lib/python3/dist-packages/nova/compute/manager.py", line 2649, in _build_resources reason=e.format_message()) nova.exception.BuildAbortException: Build of instance 818b90e4-8803-46be-a21b-4694d8162cd4 aborted: Invalid input received: Invalid input received: Connector doesn't have required information: initiator (HTTP 400) (Request-ID: req-e4f5ddd4-2418-4e4c-9a59-566620d65d3c)


**Cause**

ISCSI Service is not running on Compute Nodes and/or Storage Node.

**Solution**

Nova uses iscsi to connect to Cinder volumes, hence you need to have it installed and its service running.
```sh
sudo apt-get install -y open-iscsi
sudo systemctl enable iscsid
sudo systemctl start iscsid
```

If, by change any future problems occur due to non unique ISCSI initiator names,
What should have happen right after you install is the generation of a file `/etc/iscsi/initiatorname.iscsi` with the following content:

```sh
GenerateName=yes
```

Then, when you start the service, the contents should be replaced to something of

```sh
## DO NOT EDIT OR REMOVE THIS FILE!
## If you remove this file, the iSCSI daemon will not start.
## If you change the InitiatorName, existing access control lists
## may reject this initiator.  The InitiatorName must be unique
## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
InitiatorName=iqn.1993-08.org.debian:01:a430ba649126
```

## Generic Networking Problems:

Provision a VM eith external network
Gateway can ping the VM
The VM cant ping the gateway (or do it seems)
KVM can't ping the VM, probably because it tries to route it through eth0 From parallels, which sends the traffic to the Host OS with NAT.

Another important discovery is regarding Promiscuous Mode:

The ethernet NIC usually drops packrts that do not have its mac addr as dst. With nested virtualization;, this is undesirable, because we want thr vNic to decide if the packet should be directed to a nested VM vNIC or dripped. Hence, enabling promiscuous mode ensures that all packets won't be dropped by the host OS. Therefore we added to the Linux Beidge ifconfig script a post up/down rules that accordingly turn promiscuous mode on and off.

did was enabling all nics with promiscuous modec, which I do not think is necessary. 


Print the configurations of neutron (or any service):
```sh
grep -o '^[^#]*' /etc/neutron/neutron.conf
```

Get MySQL Users
```sh
mysql -u root -p"$PASSWORD" -e "SELECT User FROM mysql.user"
```

Virt Manager
```sh
virt-manager -c 'qemu+ssh://root@$DOMAIN/system?socket=/var/run/libvirt/libvirt-sock' --no-fork --debug
```


## Generic Overall Problems

**Problem**
You have a generic problem and don't know how to debug

**Cause**

There are many.

**Solution**

1. Check if each component configuration is correct:
```sh
# Example with nova
grep ^[^#] /etc/nova/nova.conf
```
2. Check the ports used by each service
```sh
sudo lsof -iTCP -sTCP:LISTEN -P
```

3. Verify OpenStack Service Installation [openstack.org](https://docs.openstack.org/nova/latest/install/verify.html)

Check if a service was correctly registered in Keystone DB
```sh
openstack compute service list
openstack catalog list
```

Check Available Images
```sh
openstack image list
```

Check available Compute Nodes
```sh
nova-status upgrade check
```

List all services running
```sh
systemctl list-units --all | grep -i openstack
service --status-all
```

___

## ISSUE
**Problem**
**Cause**
**Solution**
