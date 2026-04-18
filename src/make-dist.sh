#!/bin/bash

CD=$(dirname $0)
CD=$(pushd ${CD}>/dev/null && pwd -P && popd>/dev/null)

CLEAN=0
while [ $# -gt 0 ]; do
  case "$1" in
  --clean)
    CLEAN=1
    ;;
  *)
    break
  esac
  shift
done

for APP in $(ls ${CD}); do
  [ -d "${CD}/${APP}" ] && {
    CONT=1
    if [ "x$@" != "x" ]; then
      CONT=0
      for TARGET in "$@"; do
        if [ "${APP}" = "${TARGET}" ]; then
          CONT=1
          break
        fi
      done
    fi
    if [ ${CONT} -eq 1 ]; then
      DIST=${CD}/${APP}/dist
      if [ ${CLEAN} -eq 1 ]; then
        echo "Clean distributable for ${APP}..."
        [ -d "${DIST}" ] && rm -rf ${DIST}
      else
        echo "Make distributable for ${APP}..."
        mkdir -p "${DIST}"
        rm -rf "${DIST}/*"
        cd "${CD}/${APP}" && tar -czf dist/app.tgz -p --exclude=./dist --exclude-vcs --exclude-vcs-ignores .
      fi
    fi
  }
done
