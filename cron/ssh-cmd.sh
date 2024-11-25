#!/bin/bash

CD=`dirname $0`
CD=`pushd $CD>/dev/null && pwd -P && popd>/dev/null`
ENV=${CD}/ssh-cmd.env

[ -f "${ENV}" ] && {

  . ${ENV}

  # pick host
  IFS=" " read -r -a ARR <<< ${APP_HOSTS}
  SZ=${#ARR[@]}
  IDX=$(($RANDOM % $SZ))
  APP_HOST=${ARR[$IDX]}

  # execute command
  ssh-keygen -f ~/.ssh/known_hosts -R ${APP_HOST}
  ssh-keyscan -H -p ${APP_PORT} -t ecdsa-sha2-nistp256 ${APP_HOST}> ~/.ssh/known_hosts
  ssh ${APP_USER}@${APP_HOST} -p ${APP_PORT} $1
}
