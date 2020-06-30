#cloud-config
users:
  - name: ubuntu
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
    passwd: $(openssl passwd -6 ubuntu)
    lock_passwd: false
runcmd:
  - echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
