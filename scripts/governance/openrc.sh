#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Generates an OpenRC File at ~/openrc
CONTROLLER_FQDN="$1"
OSPROJECT="$2"
OSUSER="$3"
OSPASS="$4"
cat >> ./openrc_generated <<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=$OSPROJECT
export OS_USERNAME=$OSUSER
export OS_PASSWORD=$OSPASS
export OS_AUTH_URL=http://$CONTROLLER_FQDN:5000/v3 
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
echo "openrc created, source it with '. ~/openrc'"
