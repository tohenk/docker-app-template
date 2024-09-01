#!/bin/bash

LOG=/var/log/ssh.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt-get install $APT_OPTS -y openssh-client>>$LOG
