#!/bin/bash

FILES="id_rsa id_rsa.pub"
for F in ${FILES}; do
  if [ -f /config/hostkey/${F} ]; then
    if [ ! -d ~/.ssh ]; then mkdir -p ~/.ssh; fi
    cp /config/hostkey/${F} ~/.ssh/${F}
    if [ "${F}" == "id_rsa" ]; then
      chmod 0600 ~/.ssh/${F}
    else
      chmod 0640 ~/.ssh/${F}
    fi
  fi
done
