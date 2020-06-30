#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br

# IF LINUX THEN CHECK IF KVM, IF KVM, CHECK NESTED VIRT IS CONFIGURED

# Path to the root directory of this project
PROJECTPWD="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"

# Path to credentials
validate_environment() {
VAGRANT_TEST=$( vagrant validate > /dev/null 2>&1)
if [ "$?" -ne "0" ]; then
	echo "Vagrant [FAILED]"
	echo "Vagrant Failed, for more use: vagrant validate"
	exit 1
else
	echo "Vagrant [OK]"
fi
ANSIBLE_TEST=$( ansible-playbook playbook.yml --syntax-check )
if [ "$?" -ne "0" ]; then
	echo "Ansible Syntax Failed for more use: ansible-playbook playbook.yml --syntax-check"
	exit 1
else
	echo "Ansible [OK]"
fi
echo "Environment Validated."
}

elapsed_time () {
	aux=$(($1 - $2))
	echo "$(($aux / 3600)):$(((($aux / 60)) % 60)):$(($aux % 60))"	
}


cleanup() {
	# Destroy Any remaining Old Environment
	echo "Cleaning Up Old Provisionings..."
	vagrant destroy -f || true;
	pushd credentials > /dev/null
	find . ! -name 'README.md' -type f -exec rm -f {} +
	popd > /dev/null
}


# provision_kvm() {
# # Create Download Folder
# mkdir -p "$PROJECTPWD/.kvm"
# pushd "$PROJECTPWD"
# # Download Ubuntu 18.04
# wget -Lnc \
# "https://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img" \
# -o .kvm/ubuntu1804.img

# # To configure a NAT network, use --network default
# virt-install \
# --name ubuntu1804 \
# --ram 4096 \
# --disk path=.kvm/ubuntu1804.img,size=30 \
# --vcpus 2 \
# --os-type linux \
# --os-variant ubuntu18.04 \
# --network default \
# --network bridge=br0 \
# --graphics none \
# --console pty,target_type=serial \
# --location 'http://jp.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
# --extra-args 'console=ttyS0,115200n8 serial'
# # --initrd-inject /path/to/ks.cfg \
# # --extra-args="ks=file:/ks.cfg console=tty0 console=ttyS0,115200n8" 

# # sudo virt-install  \
# # -n DB-Server  \
# # --description "Test VM for Database" \
# # --os-type=Linux \
# # --os-variant=rhel7 \
# # --ram=1096 \
# # --vcpus=1 \
# # --disk path=/var/lib/libvirt/images/dbserver.img,bus=virtio,size=10 \
# # --network bridge:br0 \
# # --graphics none \
# # --location /home/linuxtechi/rhel-server-7.3-x86_64-dvd.iso \
# # --extra-args console=ttyS0
# }


scenario_jupyter_notebook() {
pushd "$PROJECTPWD"
source "credentials/adminrc"
openstack token issue
scripts/governance/keypairs.sh "credentials/instancekey"
# Creates a server running jupyter-notebook.sh installer as bootstrap.
openstack server create \
--image "debian9" \
--network "provider" \
--security-group "wildwest" \
--flavor "m1.small" \
--key-name "instancekey" \
--min "1" \
--max "1" \
--user-data "scripts/templates/jupyter-notebook.sh" \
"Jupyter Notebook"

# Creates the variable provider=<ip_address>
# Should not be used in production
# eval without countermeasures is not safe.
echo "Source your credentials with: source credentials/adminrc"
echo "Check your servers with openstack server list" 
echo "Further one Use:"
echo "ssh -i credentials/instancekey debian@$<addresses>"
echo "http://<addresses>"
popd
}


provision_scenarios(){
echo "Provisioning Scenario: Jupyter Notebook"
scenario_jupyter_notebook
}




help() {
echo '
Academic Cloud Provisioning Tool
Usage: bash ./provision.sh [Args]
  Args
  --verbose # Execute Ansible Verbose
  --clean # Clean Previous Run and Provision
  --clean-only # Clean and exit
  --help # Displays this message'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE="$1"; shift;;
    --clean) CLEAN="1"; shift;;
    --clean-only) CLEAN_ONLY="1"; CLEAN="1"; shift;;
	--with-scenarios) WITH_SCENARIOS="1"; shift;;
	--help) help; exit 0;;
    --provider) shift; export "VAGRANT_DEFAULT_PROVIDER=$1";shift;;
    --validate) validate_environment; exit 0;;
    *) echo -e "Unknown Parameter $1.\nRun with --help for more."; exit 1;;
  esac
done

echo '
##################################################
#########        Academic Cloud          #########
######## Author: Felipe Pfeifer Rubin     ########
###### Contact: felipe.rubin@edu.pucrs.br  #######
##################################################'

total_start_time=$SECONDS
start_time=$SECONDS

if [ "$CLEAN" == "1" ]; then 
	cleanup ;
	if [ "$CLEAN_ONLY" == "1" ]; then
		exit 0
	fi
fi

# Provision Environment
echo "Stage 0: Provisioning Virtual Machines..."

# vagrant up "/kvm/" control1 gateway
vagrant up

sleep 5;
validate_environment
end_time=$SECONDS
t0=$(elapsed_time $end_time $start_time)
echo "Stages 1-5: Deploying Academic Cloud..."
start_time=$SECONDS
if [ "$VERBOSE" == "1" ]; then
	ansible-playbook playbook.yml -vvv
else
	ansible-playbook playbook.yml	
fi
end_time=$SECONDS
t1=$(elapsed_time $end_time $start_time)


total_end_time="$SECONDS"
if [ "$WITH_SCENARIOS" == "1" ]; then
	start_time="$SECONDS"
	provision_scenarios
	end_time="$SECONDS"
	t2=$(elapsed_time $end_time $start_time)
	total_end_time=$SECONDS
fi
total_time=$(elapsed_time $total_end_time $total_start_time)

echo "Provisioning Complete."
echo ""
echo "######## Statistics ##########"
echo -e "Elapsed Time:\t$total_time"
echo -e "Underlying Resources:\t$t0"
echo -e "Academic Cloud:\t$t1"
if [ "$WITH_SCENARIOS" == "1" ]; then
echo -e "Provisioned Scenarios:\t$t2"
fi
exit 0
