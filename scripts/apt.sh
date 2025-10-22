#!/bin/bash

LOG=/var/log/apt.log

[ -n "${KEEP_PACKAGES}" -a -f /etc/apt/apt.conf.d/docker-clean ] && \
  rm -f /etc/apt/apt.conf.d/docker-clean
[ -f /etc/apt/sources.list.d/debian.sources ] && {
  sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
  if [ -n "${DEBIAN_OLDSTABLE}" ]; then
    cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/oldstable.sources
    [ -f /etc/os-release ] && . /etc/os-release
    [ -n "${VERSION_CODENAME}" ] && sed -i -e "s/${VERSION_CODENAME}/oldstable/g" /etc/apt/sources.list.d/oldstable.sources
  fi
}
[ -f /etc/apt/sources.list.d/ubuntu.sources ] && {
  sed -i -e "s/archive.ubuntu.com/${APT_MIRROR}/g" /etc/apt/sources.list.d/ubuntu.sources
}
apt update 2>>$LOG 1>>$LOG
if [ -n "${APT_CORE_PACKAGES}" ]; then
  apt install -y ${APT_CORE_PACKAGES} 2>>$LOG 1>>$LOG
fi