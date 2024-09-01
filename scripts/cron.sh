#!/bin/bash

LOG=/var/log/cron.log
APT_OPTS="-o DPkg::Lock::Timeout=-1"

if [ -n "$CRON_DIR" ]; then
  apt-get install $APT_OPTS -y dos2unix cron>>$LOG
  # fixup line ending and permissions
  dos2unix $CRON_DIR/*>>$LOG
  find $CRON_DIR -type f -name '*.sh' -exec chmod +x {} \;
  # https://levelup.gitconnected.com/cron-docker-the-easiest-job-scheduler-youll-ever-create-e1753eb5ea44
  if [ -z "$SCHEDULER_ENV" ]; then
    echo "SCHEDULER_ENV is not set, using prod"
    SCHEDULER_ENV="prod"
  fi
  # select the crontab file based on the environment
  CRON_FILE="$CRON_DIR/crontab.$SCHEDULER_ENV"
  echo "Loading crontab file: $CRON_FILE"
  # load the crontab file
  crontab $CRON_FILE
fi