#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# SSH into a host defined in ansible's inventory.
# can be modified to use another inventory (e.g., ansible-inventory -i <inventory name>)
function vssh() {
target=$(ansible-inventory --host $1  -y)
target_ip=$(echo "$target" | grep ansible_host | awk '{print $2}')
ssh-keygen -R $target_ip
target_key=$(echo "$target" | grep ansible_ssh_private_key_file | awk '{print $2}')
target_user=$(echo "$target" | grep ansible_user | awk '{print $2}')
target_port=$(echo "$target" | grep ansible_port | awk '{print $2}')
ssh -i $target_key -p $target_port -oStrictHostKeyChecking=no $target_user@$target_ip
}
vssh $@
