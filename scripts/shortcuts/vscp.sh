#!/bin/bash
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# Copies a file/folde recursively into a vm ./vscp.sh <file or folder> <target name>
function vscp() {

target=$(ansible-inventory --host $2  -y);
target_ip=$(echo "$target" | grep ansible_host | awk '{print $2}') ;
ssh-keygen -R $target_ip;
target_key=$(echo "$target" | grep ansible_ssh_private_key_file | awk '{print $2}') ;
target_user=$(echo "$target" | grep ansible_user | awk '{print $2}') ;
target_port=$(echo "$target" | grep ansible_port | awk '{print $2}') ;
scp -i $target_key -P $target_port -oStrictHostKeyChecking=no -r $1 $target_user@$target_ip:/home/$target_user ;
}
vscp $@

# function vagrantcp() { 
# 	scp -i .vagrant/machines/$2/*/private_key -oStrictHostKeyChecking=no -r $1 vagrant@$2:/home/vagrant ;  
# }

# vagrantcp $@