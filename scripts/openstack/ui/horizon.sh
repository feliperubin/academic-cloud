#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install Horizon Dashboard

sudo apt-get install -y apache2 libapache2-mod-wsgi
HORIZON_IP="$1"
CONTROLLER="$2"
sudo apt install openstack-dashboard -y
sed -i 's/ubuntu/default/' /etc/openstack-dashboard/local_settings.py 
sed -i 's/v2.0/v3/' /etc/openstack-dashboard/local_settings.py
sed -i "s/127.0.0.1/$CONTROLLER/" /etc/openstack-dashboard/local_settings.py

cat >> /etc/openstack-dashboard/local_settings.py <<EOF 
SESSION_ENGINE = 'django.contrib.sessions.backends.cache' 
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_API_VERSIONS = {
       "identity": 3,
       "image": 2, }
EOF

# Add fix for apache complaining about not resolving hostname

sed -i -e "1iServerName $HORIZON_IP\\" /etc/apache2/apache2.conf
systemctl enable apache2
systemctl restart apache2

# Link it
# pushd /etc/apache2/conf-enabled
# ln -s ../conf-available/openstack-dashboard.conf openstack-dashboard.conf
# popd
# Delete old version and install newer
# sudo apt-get remove libapache2-mod-python libapache2-mod-wsgi
# sudo apt-get install libapache2-mod-wsgi-py3
touch /.horizon.stamp
