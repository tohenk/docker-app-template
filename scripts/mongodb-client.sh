#!/bin/bash

LOG=/var/log/mongodb.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt install $APT_OPTS -y curl gnupg 2>>$LOG 1>>$LOG

# setup mongodb repository, see https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
  gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
cat <<EOF > /etc/apt/sources.list.d/mongodb-org-8.0.list
deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main
EOF
apt update $APT_OPTS 2>>$LOG 1>>$LOG
apt install $APT_OPTS -y mongodb-org-tools mongodb-mongosh 2>>$LOG 1>>$LOG
