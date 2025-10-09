#!/bin/bash

LOG=/var/log/apt.log

[ -f /etc/apt/sources.list.d/debian.sources ] && \
  sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
apt update 2>>$LOG 1>>$LOG
if [ -n "${APT_PACKAGES}" ]; then
  apt install -y ${APT_PACKAGES} 2>>$LOG 1>>$LOG
fi