#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install an NTP server
# ./ntp.sh -s <limit_ip> <limit_mask>
# ./ntp.sh -c <server_ip>

# Dependencies
sudo apt-get update
sudo apt-get install -y ntp

if [ "$1" == "-s" ]; then
# Configure NTP Server
cat > /etc/ntp.conf <<EOF
# Clock offset frequency information
driftfile /var/lib/ntp/ntp.drift
# Leap seconds definition provided by tzdata
leapfile /usr/share/zoneinfo/leap-seconds.list
# Store Log file at
logfile /var/log/ntp.log
# Servers to Synchronize from
# prefer (give preference), iburst (send several packets for better sync)
#server 0.ubuntu.pool.ntp.org iburst prefer
#server 1.ubuntu.pool.ntp.org iburst
#server 2.ubuntu.pool.ntp.org iburst
#server 3.ubuntu.pool.ntp.org iburst
# Specify one or more NTP servers.
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst
# Needed for adding pool entries
restrict source notrap nomodify noquery
# Restrict number of external clients
# nomodify, notrap, nopeer, and noquery: prohibit clients modifying the server.
# The kod (kiss of death) prevents too many requests (DDoS)
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
# Provide your current local time as a default should you temporarly lose Internet connectivity
server 127.127.1.0
fudge 127.127.1.0 stratum 10
# Enable LAN machines to sync
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap
#restrict 10.211.55.0 mask 255.255.255.0 nomodify notrap
# Grant localhost unlimited access
restrict 127.0.0.1
restrict -6 ::1
EOF
# Can also set some limitations Some limitatio
if [ ! "$2" == "" ] && [ "$3" == "" ]; then
	restrict "$2 mask $3 nomodify notrap" >> /etc/ntp.conf
fi

# If its a client mode
elif [ "$1" == "-c" ]; then
# Configure NTP Client
cat > /etc/ntp.conf <<EOF
# Grant localhost unlimited access
driftfile /var/lib/ntp/ntp.drift
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
server $2 prefer iburst
EOF
fi
# Disable default system time
timedatectl set-ntp false
systemctl enable ntp
service ntp restart
# Write stamp file
touch /.ntp.stamp
exit 0
