#!/bin/bash

. /cron/cron.var

# pick host
IFS=" " read -r -a ARR <<< ${APP_HOSTS}
SZ=${#ARR[@]}
IDX=$(($RANDOM % $SZ))
APP_HOST=${ARR[$IDX]}

# execute command
ssh-keygen -f ~/.ssh/known_hosts -R ${APP_HOST}
ssh-keyscan -H -p ${APP_PORT} -t ecdsa-sha2-nistp256 ${APP_HOST}> ~/.ssh/known_hosts
ssh ${APP_USER}@${APP_HOST} -p ${APP_PORT} $1

sleep 10
