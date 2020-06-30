#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# https://docs.openstack.org/nova/latest/user/flavors.htm

ADMINRC="$1"
if [ ADMINRC == "" ]; then ADMINRC="~/adminrc"

# Create admin environment file
cat > ~/adminrc <<EOF
export OS_USERNAME=admin
export OS_PASSWORD=$DB_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$CONTROLLER:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
# Add environment file to bashrc
echo ". ~/adminrc" >> ~/.bashrc

# Source openstack cli environment variables
. ~/adminrc

# # Get token
openstack token issue

# Creates a new Domain 'default', with a description
# openstack domain create --description "Default Domain" default


# Create the Services projects
openstack project create --domain default --description "Service Project" service


# Create a demo/example Project
openstack project create --domain default --description "Demo Project" demo
# Create a new user called 'demo' at the domain 'default'
openstack user create --domain default --password password demouser

# Create the global role of 'user'
openstack role create user

# Add 'demouser' to the 'demo' project with the role of 'user'.
openstack role add --project demo --user demouser user	
