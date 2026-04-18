#!/bin/bash

MONGODB_VER=8.2
MONGODB_REPO_KEY=server-8.0
APT_OPTS="-o DPkg::Lock::Timeout=-1"
LOG=/var/log/mongodb-client.log

apt install ${APT_OPTS} -y curl gnupg 1>>${LOG} 2>&1

# setup mongodb repository, see https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/
curl -fsSL https://pgp.mongodb.com/${MONGODB_REPO_KEY}.asc | \
  gpg -o /usr/share/keyrings/mongodb-${MONGODB_REPO_KEY}.gpg --dearmor
cat <<EOF > /etc/apt/sources.list.d/mongodb-org-${MONGODB_VER}.list
deb [ signed-by=/usr/share/keyrings/mongodb-${MONGODB_REPO_KEY}.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/${MONGODB_VER} main
EOF
apt update ${APT_OPTS} 1>>${LOG} 2>&1
apt install ${APT_OPTS} -y mongodb-org-tools mongodb-mongosh 1>>${LOG} 2>&1
