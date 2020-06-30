#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install and Configure etcd
# IP address of management network interface of the controller node
IP="$1"
NAME="$2"

# if no name was passed, fallback to hostname.
if [ "$NAME" == "" ]; then 
NAME="$(hostname)"; 
fi

# Install etcd
sudo apt-get update
sudo apt-get install -y

# Write configurations
cat > /etc/default/etcd << EOF
ETCD_NAME="$NAME"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="$NAME=http://$IP:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$IP:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$IP:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://$IP:2379"
EOF
sudo systemctl enable etcd
sudo systemctl restart etcd
touch /.etcd.stamp
exit 0
