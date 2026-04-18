#!/bin/bash

if [ -n "${TARGET_DIR}" ]; then
  cd "${TARGET_DIR}"
  if [ ! -d node_modules ]; then
    npm install
  fi
fi
