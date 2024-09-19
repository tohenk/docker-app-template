#!/bin/bash

LOG=/var/log/sync-src.log

SRC_DIR=/src
if [ -n "${TARGET_DIR}" ]; then
  mkdir -p ${TARGET_DIR}
  if [ -f $SRC_DIR/dist/app.tgz ]; then
    tar -xvzf $SRC_DIR/dist/app.tgz -C ${TARGET_DIR}>>$LOG
  else
    if [ -n "${EXCLUDE_FILE}" ]; then
      rsync -avzi --exclude-from=${EXCLUDE_FILE} ${SRC_DIR} ${TARGET_DIR}>>$LOG
    else
      rsync -avzi ${SRC_DIR} ${TARGET_DIR}>>$LOG
    fi
  fi
  if [ -n "${COPY_FILES}" ]; then
    for F in ${COPY_FILES}; do
      cp /config/${F} ${TARGET_DIR}>>$LOG
      if [ "${F: -3}" = ".sh" ]; then
        chmod +x ${TARGET_DIR}/${F}
      fi
    done
  fi
fi
