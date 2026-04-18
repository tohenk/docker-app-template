#!/bin/bash

LOG=/var/log/mysql-client.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt install ${APT_OPTS} -y gnupg lsb-release wget 7zip 1>>${LOG} 2>&1

wget -O /tmp/mysql-apt-config.deb https://repo.mysql.com/mysql-apt-config.deb 1>>${LOG} 2>&1
dpkg -i /tmp/mysql-apt-config.deb 1>>${LOG} 2>&1

apt update ${APT_OPTS} 1>>${LOG} 2>&1
apt install ${APT_OPTS} -y mysql-community-client 1>>${LOG} 2>&1
