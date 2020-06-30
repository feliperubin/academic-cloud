#!/bin/bash -ex
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Register a new Service based on the passed Parameters
# Availability Zones
RG="RegionOne" # Region
DN="default" # Domain
# Service Configuration
PASS="" # Password
SERVICE="" # Service Name
DESC="" # Description
TYPE="" # Type
# Service Endpoints (http://url:port)
PEND="" # Public
IEND="" # Internal
AEND="" # Admin

NO_SERVICE=""
NO_USER=""
# bash ./register_service.sh "service_name" \
# --region "RegionOne" --domain "default" --password "service_pass" \
# --description "service_description" --type "" --public "ip:port" \
# --internal "ip:port" --admin "ip:port"
usage() {
echo "Usage: ./register_service <service>
	-h|--help # Prints this
	# Availability Zones
		-rg|--region # Region
		-dn|--domain # Domain
	# Service Configuration
		-p|--password # Password
		-ds|--description # Description
		-t|--type # Type
	# Service Endpoints (http://url:port)
		-pe|--public # Public
		-pi|--internal # Internal
		-pa|--admin # Admin
	" 
}
# Set service as the first argument and shift it.
SERVICE="$1"
shift
while [ $# -gt 0 ]; do
	case "$1" in
		--noservice) NO_SERVICE="1"; shift;;
		--nouser) NO_USER="1"; shift;;
		-h|--help) usage;exit 1;;
		-rg|--region) shift; RG="$1"; shift;;
		-dn|--domain) shift; DN="$1"; shift;;
		-p|--password) shift; PASS="$1"; shift;;
		-ds|--description) shift; DESC="$1"; shift; ;;
		-t|--type) shift; TYPE="$1"; shift; ;;
		-pe|--public) shift; PEND="$1"; shift;;
		-ie|--internal) shift; IEND="$1"; shift; ;;
		-ae|--admin) shift; AEND="$1"; shift;;
		*) #Unrecognized Parameters
			echo "Parameter $i not recognized"
			echo "Use --help to know more"
			exit 1
			;;
	esac
done

. ~/adminrc

if [ -z "$NO_USER" ]; then 
openstack user create --domain "$DN" --password "$PASS" "$SERVICE"
openstack role add --project service --user "$SERVICE" admin
fi

if [ -z "$NO_SERVICE" ]; then 
openstack service create --name "$SERVICE" --description "$SERVICE_DESC" "$TYPE"
openstack endpoint create --region "$RG" "$TYPE" public "$PEND"
openstack endpoint create --region "$RG" "$TYPE" internal "$IEND"
openstack endpoint create --region "$RG" "$TYPE" admin "$AEND"
fi
touch "/.register.$SERVICE.stamp"
exit 0







