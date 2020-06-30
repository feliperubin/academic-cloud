#!/bin/bash -ex
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: OpenStack install Packages



SERVICE="$1"
SERVICE_NODE="$2"

INSTALL="apt-get install -y"

keystone() {
$INSTALL keystone
}

glance() {
$INSTALL glance
}

placement() {
$INSTALL placement-api
}

nova() {
if [ "$SERVICE_NODE" == "controller" ]; then
	$INSTALL nova-api nova-conductor nova-novncproxy nova-scheduler
elif [ "$SERVICE_NODE" == "compute" ]; then
	$INSTALL nova-compute
else
	echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
	exit 1;
fi
}

neutron() {
if [ "$SERVICE_NODE" == "controller" ]; then
	$INSTALL neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent \
	neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent
elif [ "$SERVICE_NODE" == "compute" ]; then
	$INSTALL neutron-linuxbridge-agent
else
	echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
	exit 1;
fi
}

cinder() {
if [ "$SERVICE_NODE" == "controller" ]; then
	$INSTALL cinder-api cinder-scheduler
elif [ "$SERVICE_NODE" == "storage" ]; then
	$INSTALL cinder-volume
	
else
	echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
	exit 1;
fi
}

heat() {
	$INSTALL heat-api  heat-api-cfn  heat-engine
}

murano() {
	DEBIAN_FRONTEND=noninteractive $INSTALL murano-engine murano-api heat-engine
}


case "$SERVICE" in
	keystone) keystone;;
	glance) glance;;
	placement) placement;;
	nova) nova;;
	neutron) neutron;;
	cinder) cinder;;
	heat) heat;;
	murano) murano;;
	*) echo "Error no information about service: $SERVICE"; exit 1;;
esac


if [ ! "$SERVICE_NODE" == "" ]; then
	touch "/.install.$SERVICE.$SERVICE_NODE.stamp"
else
	touch "/.install.$SERVICE.stamp"
fi

echo "Installed $SERVICE $SERVICE_NODE"
