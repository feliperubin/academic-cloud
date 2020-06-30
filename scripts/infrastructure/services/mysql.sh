#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Install and Configure MySQL
export DEBIAN_FRONTEND=noninteractive
PASSWORD="$1"
LIMITACCESS="$2"

# Fallback to binding to all
if [ "$LIMITACCESS" == "" ]; then
	LIMITACCESS="0.0.0.0"
fi


# Install Dependencies
sudo apt-get install -y software-properties-common
sudo apt-get update;
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/10.3/ubuntu $(lsb_release -cs) main"
#sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
sudo apt-get update

debconf-set-selections <<< 'mariadb-server mysql-server/root_password password  '
debconf-set-selections <<< 'mariadb-server mysql-server/root_password_again password  '

# Install Mariadb (It might return an error even if correctly installed. )
set +e
sudo apt-get install -y mariadb-server
sudo apt-get install -y python-pymysql
set -e

# Setup OpenStack Configurations
cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf <<EOF
[mysqld]
bind-address = $LIMITACCESS
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci 
character-set-server = utf8
skip-name-resolve
EOF

sudo systemctl stop mariadb

sudo mysqld_safe --skip-grant-tables --skip-networking & # Start in the background
sleep 3; # Wait a bit for the service to fully start

# This is the same as executing 'mysql_secure_installation'
# 1. Set a new root password saving it as a hash for security purposes
# 2. Delete anonymous 
# 3. Disable root login remote access
# 4. Remove test database, usually present after an installation
# 6. Flush privileges table to commit changes
echo " \
UPDATE mysql.user SET Password=PASSWORD('$PASSWORD') WHERE User='root'; \
DELETE FROM mysql.user WHERE User=''; \
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); \
DROP DATABASE IF EXISTS test; \
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES; \
"|mysql

# Kill the background process
sudo killall mysqld

# Restart MySQL, note that its mariadb and NOT mysql
sudo systemctl enable mariadb.service
sudo systemctl restart mariadb.service

# Write stamp file
touch /.mysql.stamp

exit 0
