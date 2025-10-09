#!/bin/bash

LOG=/var/log/ssh.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

apt install $APT_OPTS -y openssh-client 2>>$LOG 1>>$LOG
