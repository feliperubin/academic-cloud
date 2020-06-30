#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Discover new Nova Compute Nodes
. ~/adminrc
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
touch /.host_discovery.stamp
