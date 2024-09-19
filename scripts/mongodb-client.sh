#!/bin/bash

APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt-get install $APT_OPTS -y curl gnupg>/dev/null

# setup mongodb repository, see https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
  gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
  tee /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update $APT_OPTS>/dev/null
apt-get install $APT_OPTS -y mongodb-org-tools mongodb-mongosh>/dev/null
