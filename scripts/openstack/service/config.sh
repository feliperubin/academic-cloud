#!/bin/bash -ex
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: OpenStack Main Configuration Tool
#

# Controller IP/FQDN
CONTROLLER="controller"
# OpenStack Working Space
REGION="RegionOne"
PROJECT_DOMAIN="default" # Project domain name
USER_DOMAIN="default" # User domain name
PROJECT_NAME="service"
# Credentials for the Service, SERVICE acts as the username
SERVICE="" # Service name: nova, cinder, etc ...
SERVICE_NODE="" # Only applicable for services with more than on, nova: controller and compute  
SERVICE_PASSWORD=""  # Service Password
# Credentials for database entry of this service
APIDB_NAME=""
DB_USER=""
DB_PASS=""
DB_PROTO="mysql+pymysql"
DB_NAME="$SERVICE"
# INI Configuration file
CFG=""
# Glance
DATADIR=/var/lib/glance/images/


# Related to Nova
MANAGEMENT_IP=""
RABBIT_USER="openstack"
RABBIT_PASS=""
PLACEMENT_USER="placement"
PLACEMENT_PASS=""
NEUTRON_USER="neutron"
NEUTRON_PASS=""
NEUTRON_SECRET=""

# Related to Neutron
PROVIDER_INTERFACE_NAME="" # Provider Interface name (2nd one) without IP added to /etc/network/interfaces.
OVERLAY_INTERFACE_IP_ADDRESS="" # Public IP Address (1st one) of this node.
NOVA_USER="nova"
NOVA_PASS=""

# Related to Heat
HEAT_DOMAIN_PASS=""

# Related to Murano
MURANO_IP=""


# Set Service as the first argument and shift to start from the next
SERVICE="$1"
shift




# [keystone_authtoken] Standard
keystone_authtoken() {
$CFG keystone_authtoken www_authenticate_uri http://$CONTROLLER:5000
$CFG keystone_authtoken auth_url http://$CONTROLLER:5000
$CFG keystone_authtoken memcached_servers $CONTROLLER:11211
$CFG keystone_authtoken auth_type password
$CFG keystone_authtoken project_domain_name $PROJECT_DOMAIN
$CFG keystone_authtoken user_domain_name $USER_DOMAIN
$CFG keystone_authtoken project_name $PROJECT_NAME
$CFG keystone_authtoken username $SERVICE
$CFG keystone_authtoken password $SERVICE_PASSWORD
}

# [placement_database]
placement_database() {
$CFG placement_database connection $DB_PROTO://$DB_USER:$DB_PASS@$CONTROLLER/$DB_NAME
}

# [api_database]
api_database() {
$CFG api_database connection $DB_PROTO://$DB_USER:$DB_PASS@$CONTROLLER/$APIDB_NAME
	
}

# [database]
database() {
$CFG database connection $DB_PROTO://$DB_USER:$DB_PASS@$CONTROLLER/$DB_NAME
}

# [paste_deploy]
paste_deploy() {
$CFG paste_deploy flavor keystone
}

# [glance_store]
glance_store() {
## For store mode
$CFG glance_store stores file,http
$CFG glance_store default_store file
$CFG glance_store filesystem_store_datadir $DATADIR
}

# [token]
token() {
$CFG token provider fernet
}

# [api]
api() {
$CFG api auth_strategy keystone
}
# [glance]

glance() {
$CFG glance api_servers http://$CONTROLLER:9292
}
# [PLACEMENT]
placement() {
$CFG placement region_name $REGION
$CFG placement project_domain_name $PROJECT_DOMAIN
$CFG placement project_name $PROJECT_NAME
$CFG placement auth_type password
$CFG placement user_domain_name $USER_DOMAIN
$CFG placement auth_url http://$CONTROLLER:5000/v3
$CFG placement username $PLACEMENT_USER
$CFG placement password $PLACEMENT_PASS
}
# [neutron]
neutron() {
$CFG neutron auth_url http://$CONTROLLER:5000
$CFG neutron auth_type password
$CFG neutron project_domain_name $PROJECT_DOMAIN
$CFG neutron user_domain_name $USER_DOMAIN
$CFG neutron region_name $REGION
$CFG neutron project_name $PROJECT_NAME
$CFG neutron username $NEUTRON_USER
$CFG neutron password $NEUTRON_PASS
}


# [vnc]
vnc() {
$CFG vnc enabled true
$CFG vnc server_listen $MANAGEMENT_IP
$CFG vnc server_proxyclient_address $MANAGEMENT_IP
}
# [oslo_concurrency]
oslo_concurrency() {
$CFG oslo_concurrency lock_path /var/lib/$SERVICE/tmp
}

# [nova]
nova(){
# Moved NOVA HERE
$CFG nova auth_url http://$CONTROLLER:5000
$CFG nova auth_type password
$CFG nova project_domain_name $PROJECT_DOMAIN
$CFG nova user_domain_name $USER_DOMAIN
$CFG nova region_name $REGION
$CFG nova project_name $PROJECT_NAME
$CFG nova username $NOVA_USER
$CFG nova password $NOVA_PASS	

}


################################################ FINISH SETUPS ################################################  
finish_keystone() {
# Fix permission problems
chown -R keystone:keystone /etc/keystone
# Sync
su -s /bin/sh -c "keystone-manage db_sync" keystone
# Setup additional requirements
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password $DB_PASS \
--bootstrap-admin-url http://$CONTROLLER:5000/v3/ \
--bootstrap-internal-url http://$CONTROLLER:5000/v3/ \
--bootstrap-public-url http://$CONTROLLER:5000/v3/ \
--bootstrap-region-id $REGION

# Add fix for apache complaining about not resolving hostname
sed -i -e "1iServerName $CONTROLLER\\" /etc/apache2/apache2.conf
service apache2 restart

# Remove Standard db
rm -f /var/lib/keystone/keystone.db

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
openstack role create _member_

# Add 'demouser' to the 'demo' project with the role of 'user'.
openstack role add --project demo --user demouser user	

touch /.configure.keystone.stamp
}
finish_placement() {
	su -s /bin/sh -c "placement-manage db sync" placement
	service apache2 restart
touch /.configure.placement.stamp
}

finish_glance() {
# Populate Image Service DB
su -s /bin/sh -c "glance-manage db_sync" glance
# Restart services
service glance-api restart
touch /.configure.glance.stamp
}

finish_nova_compute() {
$CFG vnc server_listen 0.0.0.0
$CFG vnc novncproxy_base_url http://$CONTROLLER:6080/vnc_auto.html

# Test hardware acceleration support
set +e # Ignore any error
hwaccel=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
# Check exit code, 0=support,1=otherwise
if [ $? -ne 0 ]; then 
echo "Hardware acceleration is not supoorted, falling back to qemu."
crudini --set "/etc/nova/nova-compute.conf" libvirt virt_type qemu
fi
set -e # Stop ignoring errors
# Restart services
service nova-compute restart
touch /.configure.nova_compute.stamp
}

finish_nova_controller() {

# Add these two more parameters on the controller node
$CFG neutron service_metadata_proxy true
$CFG neutron metadata_proxy_shared_secret $NEUTRON_SECRET


# protocol//[hosts][/database][?properties]
# Due to a packaging bug, remove the log_dir option from the [DEFAULT] section
# sync with the database

# Discover Nodes every 300s
$CFG scheduler discover_hosts_in_cells_interval 300

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
# Restart services
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
touch /.configure.nova_controller.stamp
}

# CONFIGURED FOR LINUX BRIDGE
# https://docs.openstack.org/neutron/pike/admin/config-ml2.html
finish_neutron_controller(){
# (STEP 1.) Configure Metadata Agent
crudini --set "/etc/neutron/metadata_agent.ini" DEFAULT nova_metadata_host $CONTROLLER
crudini --set "/etc/neutron/metadata_agent.ini" DEFAULT metadata_proxy_shared_secret $NEUTRON_SECRET

# (STEP 2.) Configure the server component

crudini --set "/etc/neutron/neutron.conf" DEFAULT core_plugin ml2
crudini --set "/etc/neutron/neutron.conf" DEFAULT service_plugins router
crudini --set "/etc/neutron/neutron.conf" DEFAULT allow_overlapping_ips true
crudini --set "/etc/neutron/neutron.conf" DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER
crudini --set "/etc/neutron/neutron.conf" DEFAULT auth_strategy keystone
crudini --set "/etc/neutron/neutron.conf" DEFAULT notify_nova_on_port_status_changes true
crudini --set "/etc/neutron/neutron.conf" DEFAULT notify_nova_on_port_data_changes true


# (STEP 3.) Configure the Modular Layer 2 (ML2) plug-in

crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" ml2 type_drivers flat,vlan,vxlan
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" ml2 tenant_network_types vxlan
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" ml2 mechanism_drivers linuxbridge,l2population
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" ml2 extension_drivers port_security
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini"  ml2_type_flat flat_networks provider
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" ml2_type_vxlan vni_ranges 1:1000
crudini --set "/etc/neutron/plugins/ml2/ml2_conf.ini" securitygroup enable_ipset true

# (STEP 4.) Configure the Linux bridge agent

crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" linux_bridge physical_interface_mappings provider:$PROVIDER_INTERFACE_NAME
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan enable_vxlan true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan local_ip $OVERLAY_INTERFACE_IP_ADDRESS
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan l2_population true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" securitygroup enable_security_group true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# (STEP 5.) Configure the layer-3 agent
crudini --set "/etc/neutron/l3_agent.ini" DEFAULT interface_driver linuxbridge

# (STEP 6.) Configure the DHCP agent
crudini --set "/etc/neutron/dhcp_agent.ini" DEFAULT interface_driver linuxbridge
crudini --set "/etc/neutron/dhcp_agent.ini" DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set "/etc/neutron/dhcp_agent.ini" DEFAULT enable_isolated_metadata true




# (STEP 7.) Finalize installation
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# Restart Services
pip3 install msgpack-python
service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart	
touch /.configure.neutron_controller.stamp
}


# /etc/neutron/metadata_agent.ini
# metadata_proxy_shared_secret = True
# 2020-05-29 06:32:07.492 9214 ERROR neutron.plugins.ml2.drivers.linuxbridge.agent.linuxbridge_neutron_agent [-] Interface eth2 for physical network provider does not exist. Agent terminated!


finish_neutron_compute(){

crudini --set "/etc/neutron/neutron.conf" DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER
crudini --set "/etc/neutron/neutron.conf" DEFAULT auth_strategy keystone


crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" linux_bridge physical_interface_mappings provider:$PROVIDER_INTERFACE_NAME
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan enable_vxlan true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan local_ip $OVERLAY_INTERFACE_IP_ADDRESS
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" vxlan l2_population true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" securitygroup enable_security_group true
crudini --set  "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
service nova-compute restart
service neutron-linuxbridge-agent restart
touch /.configure.neutron_compute.stamp
}

finish_nova() {
# Configuration is unique to NOVA
$CFG DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER:5672/
$CFG DEFAULT my_ip $MANAGEMENT_IP
$CFG DEFAULT use_neutron true
$CFG DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver	

	if [ "$SERVICE_NODE" == "controller" ]; then
		finish_nova_controller;
		
	elif [ "$SERVICE_NODE" == "compute" ]; then
		finish_nova_compute;
		
	else
		echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
		exit 1;
	fi
}
finish_neutron() {
	if [ "$SERVICE_NODE" == "controller" ]; then
		finish_neutron_controller;
		
	elif [ "$SERVICE_NODE" == "compute" ]; then
		finish_neutron_compute;
		
	else
		echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
		exit 1;
	fi
}


finish_cinder_controller() {

crudini --set "/etc/nova/nova.conf" cinder os_region_name $REGION
# First Restart to update nova
service nova-api restart
service cinder-scheduler restart
service apache2 restart

# Second Restart
$CFG DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER
$CFG DEFAULT auth_strategy keystone
$CFG DEFAULT my_ip $MANAGEMENT_IP
su -s /bin/sh -c "cinder-manage db sync" cinder
service nova-api restart
service cinder-scheduler restart
service apache2 restart
touch /.configure.cinder_controller.stamp
}

finish_cinder_storage() {

$CFG lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
$CFG lvm volume_group cinder-volumes
$CFG lvm iscsi_protocol iscsi
$CFG lvm iscsi_helper tgtadm

$CFG DEFAULT my_ip $MANAGEMENT_IP
$CFG DEFAULT enabled_backends lvm
$CFG DEFAULT glance_api_servers http://$CONTROLLER:9292
$CFG DEFAULT auth_strategy keystone
$CFG DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER


service tgt restart
sleep 1

# Workaround Cinder Bug, Restarting the Service Again
# cinder-volume.service: Start request repeated too quickly.
# cinder-volume.service: Failed with result 'exit-code'.
# Failed to start OpenStack Cinder Volume.
set +e
MAX_TRIES=3
cinder_rt=$(service cinder-volume restart)
while [ "$?" -ne "0" ] && [ "$MAX_TRIES" -gt 0 ]; do
	echo "Cinder Failed to Restart, retrying..."
	sleep 1
	MAX_TRIES=$(($MAX_TRIES-1))	
	cinder_rt=$(service cinder-volume restart)
done
set -e

touch /.configure.cinder_storage.stamp
}

finish_cinder() {
	if [ "$SERVICE_NODE" == "controller" ]; then
		finish_cinder_controller;
		
	elif [ "$SERVICE_NODE" == "storage" ]; then
		finish_cinder_storage;
		
	else
		echo "Unknown service node: service:$SERVICE node: $SERVICE_NODE";
		exit 1;
	fi

}








finish_heat() {
$CFG trustee auth_type password
$CFG trustee auth_url http://$CONTROLLER:5000
$CFG trustee username $SERVICE
$CFG trustee password $SERVICE_PASS
$CFG trustee user_domain_name $USER_DOMAIN

$CFG clients_keystone auth_uri http://$CONTROLLER:5000

$CFG DEFAULT transport_url rabbit://$RABBIT_USER:$RABBIT_PASS@$CONTROLLER
$CFG DEFAULT heat_metadata_server_url http://$CONTROLLER:8000
$CFG DEFAULT heat_waitcondition_server_url http://$CONTROLLER:8000/v1/waitcondition
$CFG DEFAULT stack_domain_admin heat_domain_admin
$CFG DEFAULT stack_domain_admin_password $HEAT_DOMAIN_PASS
$CFG DEFAULT stack_user_domain_name $SERVICE

# Source openstack cli environment variables
. ~/adminrc

# # Get token
openstack token issue

openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password $HEAT_DOMAIN_PASS heat_domain_admin
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role add --project demo --user demouser heat_stack_owner
openstack role create heat_stack_user

su -s /bin/sh -c "heat-manage db_sync" heat
service heat-api restart
service heat-api-cfn restart
service heat-engine restart

touch /.configure.heat.stamp
}





finish_murano() {

$CFG DEFAULT debug true
$CFG DEFAULT verbose true
$CFG DEFAULT rabbit_host $CONTROLLER
$CFG DEFAULT rabbit_userid $RABBIT_USER
$CFG DEFAULT rabbit_password $RABBIT_PASS
$CFG DEFAULT rabbit_virtual_host "/"
$CFG DEFAULT driver messagingv2


# $CFG keystone auth_url http://$CONTROLLER:5000/v2.0
$CFG keystone auth_url http://$CONTROLLER:5000

# $CFG keystone_authtoken region $REGION
$CFG keystone_authtoken region_name $REGION

# $CFG keystone_authtoken www_authenticate_uri http://$CONTROLLER:5000/v3
# $CFG keystone_authtoken auth_host $CONTROLLER
# $CFG keystone_authtoken auth_port 5000
# $CFG keystone_authtoken auth_protocol http
# $CFG keystone_authtoken admin_tenant_name $SERVICE
# $CFG keystone_authtoken admin_user admin
# $CFG keystone_authtoken admin_password $SERVICE_PASS

$CFG murano url http://$MURANO_IP:8082

$CFG rabbitmq host $CONTROLLER
$CFG rabbitmq login $RABBIT_USER
$CFG rabbitmq password $RABBIT_PASS
$CFG rabbitmq virtual_host "/"


# In case openstack neutron
# has no default DNS configured
$CFG networking default_dns 8.8.8.8 
                      
su -s /bin/sh -c "murano-db-manage upgrade" murano
service murano-api restart
service murano-engine restart
touch /.configure.murano.stamp
}

while [ $# -gt 0 ]; do
	case "$1" in
		--node) shift; SERVICE_NODE="$1"; shift;;
		--managementip) shift; MANAGEMENT_IP="$1"; shift;;
		--rabbituser) shift; RABBIT_USER="$1"; shift;;
		--rabbitpass) shift; RABBIT_PASS="$1"; shift;;
		--placementuser) shift; PLACEMENT_USER="$1"; shift;;
		--placementpass) shift; PLACEMENT_PASS="$1"; shift;;
		--neutronuser) shift; NEUTRON_USER="$1"; shift;;
		--neutronpass) shift; NEUTRON_PASS="$1"; shift;;
		--neutronsecret) shift; NEUTRON_SECRET="$1"; shift;;
		--heatadminpass) shift; HEAT_DOMAIN_PASS="$1"; shift;;
		--muranoip) shift; MURANO_IP="$1"; shift;;
		--novauser) shift; NOVA_USER="$1"; shift;;
		--novapass) shift; NOVA_PASS="$1"; shift;;
		--provideriface) shift; PROVIDER_INTERFACE_NAME="$1"; shift;;
		--overlayifaceip) shift; OVERLAY_INTERFACE_IP_ADDRESS="$1"; shift;;
		--apidbname) shift; APIDB_NAME="$1"; shift;;
		--controller) shift; CONTROLLER="$1"; shift;;
		--projectdomain) shift; PROJECT_DOMAIN="$1"; shift;;
		--projectname) shift; PROJECT_NAME="$1"; shift;;
		--userdomain) shift; USER_DOMAIN="$1"; shift;;
		--password) shift; SERVICE_PASSWORD="$1"; shift;;
		--cfg) shift; CFG="crudini --set $1"; shift;;
		--dbuser) shift; DB_USER="$1"; shift;;
		--dbpass) shift; DB_PASS="$1"; shift;;
		--dbname) shift; DB_NAME="$1"; shift;;
		--dbproto) shift; DB_PROTO="$1"; shift;;
		--datadir) shift; DATADIR="$1"; shift;;
		--region) shift; REGION="$1"; shift;;
		*)
			case "$1" in
				database) database ;;
				keystone_authtoken) keystone_authtoken ;;
				token) token;;
				paste_deploy) paste_deploy;;
				glance_store) glance_store;;
				placement_database) placement_database;;
				api) api;;
				api_database) api_database;;
				glance) glance;;
				neutron) neutron;;
				placement) placement;;
				oslo_concurrency) oslo_concurrency;;
				vnc) vnc;;
				nova) nova;;
				*) echo "Section [$1]"; exit 1;;
			esac
			shift
			;;
	esac
done

# Finish any remaining specific configuration for this service
case "$SERVICE" in
	keystone) finish_keystone;;
	glance) finish_glance;;
	placement) finish_placement;;
	nova) finish_nova;;
	neutron) finish_neutron;;
	cinder) finish_cinder;;
	heat) finish_heat;;
	murano) finish_murano;;
	*) echo "Error no information about service: $SERVICE"; exit 1;;
esac




# ./config_service "service_name" --password "service_pass"
# --controller "{{ hostvars[inventory_hostname].ansible_host }}"
# --dbuser "DB_user" --dbpass "DB_pass"
# --cfg "/etc/glance/glance-registry.conf" keystone_authtoken database paste_deploy
# --cfg "/etc/glance/glance-api.conf" keystone_authtoken database paste_deploy glance_store
















