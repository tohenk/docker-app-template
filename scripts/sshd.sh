#!/bin/bash

LOG=/var/log/sshd.log

# start sshd
if [ -f /config/hostkey/id_rsa.pub ]; then
  mkdir -p ~/.ssh
  cp /config/hostkey/id_rsa.pub ~/.ssh/authorized_keys
  chmod 0640 ~/.ssh/authorized_keys
  apt-get install -y openssh-server>>$LOG
  # prepare openssh-server configuration
  SSHD_CONFIG=/etc/ssh/sshd_config
  if [ -n "${APP_SSH_PORT}" ]; then
    sed -i -e "s/#Port 22/Port ${APP_SSH_PORT}/g" ${SSHD_CONFIG}
  fi
  sed -i -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" ${SSHD_CONFIG}
  mkdir -p /run/sshd
  touch ~/.Xauthority
  /usr/sbin/sshd -D &
fi
