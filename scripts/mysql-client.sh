#!/bin/bash

LOG=/var/log/mysql.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt install $APT_OPTS -y curl gnupg 7zip 2>>$LOG 1>>$LOG

# import MySQL GPG public key
mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /etc/apt/keyrings/mysql.gpg

# bootstrap mysql-community-client
cat <<EOF > /etc/apt/sources.list.d/mysql.list
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
# You may comment out entries below, but any other modifications may be lost.
# Use command 'dpkg-reconfigure mysql-apt-config' as root for modifications.
deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-apt-config
deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-8.4-lts
deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-tools
#deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-tools-preview
deb-src [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-8.4-lts
EOF
apt update $APT_OPTS 2>>$LOG 1>>$LOG
apt install $APT_OPTS -y mysql-community-client 2>>$LOG 1>>$LOG
