#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Cloud Governance Network Setup

# openstack keypair create -f value mykeypair #
# ssh-keygen -t rsa -b 4096 -f computekeys
# openstack keypair create --public-key computekeys.pub computekeys

KEYPATH="$1" # The path, including the key name.
# These information defaults to credentials/sshkey
if [ "$KEYPATH" == "" ];then KEYNAME="../../credentials/id_rsa"; fi
KEYNAME=$(basename "$KEYPATH")

# Ensure that we won't override another existing key
if [ -f "$KEYPATH" ]; then 
	echo "Key $KEYNAME already exists."
	# Check if key has already been registered
	# $(openstack keypair show instancekeya > /dev/null 2>&1 ); 
	# ; echo "$?"
	exit 1;
fi
openstack keypair create -f shell $KEYNAME >> $KEYPATH
# Set permissions
chmod 600 $KEYPATH
exit 0
