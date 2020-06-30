#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Installs and Configures collectd

VIRT=""

enable_plugin() {
  case "$1" in
    virt) VIRT="1"; shift;;
    *) echo "Unknown plugin $1"; exit 1;
  esac
}

COLLECTD_TIME="60s"
while [ $# -gt 0 ]; do
  case "$1" in
    --time) shift; COLLECTD_TIME="$1"; shift;;
    --plugin) shift; enable_plugin "$1"; shift;;
    *) echo "Unknown parameter $1"; exit 1;
  esac
done


sudo apt-get update
sudo apt-get install -y collectd
HNAME="$(echo $HOSTNAME)"
cat > /etc/collectd/collectd.conf << EOF
Hostname    "$HNAME"
FQDNLookup   false

LoadPlugin write_prometheus
LoadPlugin cpu
LoadPlugin load
LoadPlugin disk
LoadPlugin memory
LoadPlugin processes
Interval $COLLECTD_TIME

<Plugin "disk">
  Disk "/^sd/"
  Disk "/^vd/"
  Disk "/^disk/"
  Disk "/^mm/"
  Disk "/^hd/"
  IgnoreSelected false
</Plugin>

<Plugin "write_prometheus">
  Port "9103"
</Plugin>

EOF

if [ ! -z "$VIRT" ]; then
cat >> /etc/collectd/collectd.conf << EOF 

LoadPlugin virt
<Plugin "virt">
   Connection "qemu:///system"
   BlockDeviceFormat "target"
   HostnameFormat "name:uuid"
   InterfaceFormat "address"
   PluginInstanceFormat name
   ExtraStats "cpu_util disk_err domain_state job_stats_background perf vcpupin"
   RefreshInterval $COLLECTD_TIME
</Plugin>

LoadPlugin interface
<Plugin interface>
    Interface "lo"
    IgnoreSelected true
</Plugin>

EOF
fi
sudo systemctl enable collectd
sudo service collectd restart
touch /.collectd.stamp

