#!/bin/bash

LOG=/var/log/php.log

get_php_ini() {
  KEY=$1
  IFS="=>" read -r -a ARR <<< `php -i | grep "^${KEY}"`
  echo ${ARR[2]} | xargs
}

php_ext_enabled() {
  EXT_INI="${PHP_INI_DIR}/conf.d/docker-php-ext-$1.ini"
  if [ -f "${EXT_INI}" ]; then
    echo 1
  else
    echo 0
  fi
}

ENV=/scripts/php.env

[ -f "${ENV}" ] && {

  . ${ENV}

  CACHE_DIR=/cache/php-$(php -v | awk '/PHP ([0-9]\.[0-9]\.[0-9]+)/{print $2}')/$(uname -m)
  PHP_INI_DIR=`get_php_ini 'Configuration File (php.ini) Path'`
  PHP_EXT_DIR=`get_php_ini 'extension_dir'`

  echo "PHP ini dir = ${PHP_INI_DIR}...">>$LOG
  echo "Extension dir = ${PHP_EXT_DIR}...">>$LOG

  mkdir -p ${CACHE_DIR}>>$LOG

  # install dependencies
  if [ -n "${EXTRA_PACKAGES}" -a -z "${PHP_BOOTSTRAP}" ]; then
    apt install -y ${EXTRA_PACKAGES} 2>>$LOG 1>>$LOG
  fi

  # install PHP extensions
  for EXT in ${EXTENSIONS}; do
    IFS=':' read -ra ARR <<< "${EXT}"
    EXT_TYPE=
    EXT_ENABLED=
    EXT_YES=
    if [ ${#ARR[@]} -gt 1 ]; then
      EXT=${ARR[0]}
      EXT_TYPE=${ARR[1]}
    fi
    if [ ${#ARR[@]} -gt 2 -a "x${ARR[2]}" != "x" ]; then
      EXT_ENABLED="APP_${ARR[2]}"
    fi
    if [ ${#ARR[@]} -gt 3 ]; then
      EXT_YES=${ARR[3]}
    fi
    if [ `php_ext_enabled ${EXT}` -eq 1 ]; then
      echo "Extension ${EXT} already enabled, skipping..."
      continue
    fi
    if [ -n "${EXT_ENABLED}" ]; then
      if [ "x${!EXT_ENABLED}" != "xtrue" ]; then
        echo "Extension ${EXT} not enabled, skipping..."
        continue
      fi
    fi

    XID=${EXT^^}
    XPACKAGES="EXT_${XID}_PACKAGES"
    XDEVPACKAGES="EXT_${XID}_DEV_PACKAGES"
    XCONFIGURES="EXT_${XID}_CONFIGURES"
    if [ -f "${CACHE_DIR}/${EXT}.so" ]; then
      XBUILD=0
    else
      XBUILD=1
    fi

    # install extension dependencies
    if [ ${XBUILD} -eq 0 ]; then
      # set packages only when not bootstrapping
      if [ -z "${PHP_BOOTSTRAP}" ]; then
        PACKAGES="${!XPACKAGES}"
      else
        PACKAGES=
      fi
    else
      PACKAGES="${!XDEVPACKAGES}"
    fi
    if [ -n "${PACKAGES}" ]; then
      apt install -y ${PACKAGES} 2>>$LOG 1>>$LOG
    fi
    if [ ${XBUILD} -eq 0 ]; then
      if [ -z "${PHP_BOOTSTRAP}" ]; then
        cp "${CACHE_DIR}/${EXT}.so" "${PHP_EXT_DIR}/${EXT}.so">>$LOG
        docker-php-ext-enable ${EXT}>>$LOG
      fi
    else
      CONFIGURES="${!XCONFIGURES}"
      if [ -n "${CONFIGURES}" ]; then
        docker-php-ext-configure ${EXT} ${CONFIGURES}>>$LOG
      fi
      case "${EXT_TYPE}" in
        pecl)
          if [ -n "${EXT_YES}" ]; then
            yes | pecl install ${EXT}>>$LOG
          else
            pecl install ${EXT}>>$LOG
          fi
          docker-php-ext-enable ${EXT}>>$LOG
          ;;
        *)
          docker-php-ext-install -j$(nproc) ${EXT}>>$LOG
          ;;
      esac
      cp "${PHP_EXT_DIR}/${EXT}.so" "${CACHE_DIR}/${EXT}.so">>$LOG
    fi
  done
}

[ -z "${PHP_BOOTSTRAP}" ] && {
  # prepare php.ini
  PHP_INI=${PHP_INI_DIR}/php.ini
  cp ${PHP_INI}-production ${PHP_INI}
  sed -i -e "s#memory_limit = 128M#memory_limit = 1024M#g" \
         -e "s#max_execution_time = 30#max_execution_time = 60#g" \
         -e "s#post_max_size = 8M#post_max_size = 0#g" \
         -e "s#;date.timezone =#date.timezone = ${APP_TIMEZONE}#g" \
         ${PHP_INI}

  # reload apache
  /etc/init.d/apache2 reload>>$LOG
}