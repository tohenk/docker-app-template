#!/bin/bash

LOG=/var/log/apt.log

apt_mirror() {
  [ -f /etc/apt/sources.list.d/debian.sources ] && sed -i -e "s/deb.debian.org/${APT_MIRROR}/g" /etc/apt/sources.list.d/debian.sources
}

apt_updates() {
  apt-get update>>$LOG
}

apt_mirror
apt_updates
