#!/bin/bash

LOG=/var/log/mysql-client.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt install $APT_OPTS -y gnupg lsb-release wget 7zip 2>>$LOG 1>>$LOG

wget -O /tmp/mysql-apt-config.deb https://repo.mysql.com/mysql-apt-config.deb 2>>$LOG 1>>$LOG
dpkg -i /tmp/mysql-apt-config.deb 2>>$LOG 1>>$LOG

apt update $APT_OPTS 2>>$LOG 1>>$LOG
apt install $APT_OPTS -y mysql-community-client 2>>$LOG 1>>$LOG
