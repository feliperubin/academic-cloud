#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install RabbitMQ
export DEBIAN_FRONTEND=noninteractive
MQUSER="$1"
MQPASS="$2"
if [ "$MQUSER" == "" ] || [ "$MQPASS" == "" ]; then
	echo -e "RabbitMQ Settup Failed !\n No User/Password was provided"
	exit 1
fi
sudo apt-get install -y rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl restart rabbitmq-server
sudo rabbitmqctl add_user "$MQUSER" "$MQPASS"
sudo rabbitmqctl set_permissions "$MQUSER" ".*" ".*" ".*"
touch /.rabbitmq.stamp
exit 0
