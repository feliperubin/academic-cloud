#!/bin/bash -e
# Author: Felipe Pfeifer Rubin
# Contact: felipe.rubin@edu.pucrs.br
# About: Creates one or more databases for a local mysql installation.
# Usage: ./mysql_createdb.sh <keystone> <keystone> <secret-pass>
#
ROOTPW="$1"
DB_NAME="$2"
DB_USER="$3"
DB_PASS="$4"
SQL="mysql -u root -p$ROOTPW -e"
# Creates the database
$SQL "CREATE DATABASE $DB_NAME;"
# Grant all of the database privileges to user `DB_USER` w/ pass `DB_PASS`, when connected from localhost
$SQL "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
# Grant all of the database privileges to user `DB_USER` w/ pass `DB_PASS`, when connected from anywhere
$SQL "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"

# Flushes privileges after creating new user
$SQL "FLUSH PRIVILEGES;"

touch "/.createdb.$DB_NAME.mysql.stamp"
exit 0

