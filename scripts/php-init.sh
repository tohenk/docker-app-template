#!/bin/bash

LOG=/var/log/init.log

get_php_ini() {
  KEY=$1
  IFS="=>" read -r -a ARR <<< `php -i | grep "^${KEY}"`
  echo ${ARR[2]} | xargs
}

php_ext_enabled() {
  EXT_INI="$PHP_INI_DIR/conf.d/docker-php-ext-$1.ini"
  if [ -f $EXT_INI ]; then
    echo 1
  else
    echo 0
  fi
}

CACHE_DIR=/cache/php-$(php -v | awk '/PHP ([0-9]\.[0-9]\.[0-9]+)/{print $2}')/$(uname -m)
EXTENSIONS="gd mysqli pdo_mysql zip"
PECL_EXTENSIONS="mongodb xdebug"

PHP_INI_DIR=`get_php_ini 'Configuration File (php.ini) Path'`
PHP_EXT_DIR=`get_php_ini 'extension_dir'`

echo "PHP ini dir = ${PHP_INI_DIR}...">>$LOG
echo "Extension dir = ${PHP_EXT_DIR}...">>$LOG

mkdir -p ${CACHE_DIR}>>$LOG

# install PHP extensions
for EXT in ${EXTENSIONS}; do
  if [ `php_ext_enabled ${EXT}` -eq 1 ]; then
    echo "Extension ${EXT} already enabled, skipping..."
    continue
  fi
  if [ -f "${CACHE_DIR}/${EXT}.so" ]; then
    cp "${CACHE_DIR}/${EXT}.so" "${PHP_EXT_DIR}/${EXT}.so">>$LOG
    PACKAGES=""
    case "${EXT}" in
      gd)
        PACKAGES="${PACKAGES} libfreetype6 libjpeg62-turbo libpng16-16 libxpm4 libwebp7 zlib1g";;
      zip)
        PACKAGES="${PACKAGES} libzip4";;
    esac
    if [ -n "${PACKAGES}" ]; then
      apt-get install -y ${PACKAGES}>>$LOG
    fi
    docker-php-ext-enable ${EXT}>>$LOG
  else
    PACKAGES=""
    CONFIGURES=""
    case "${EXT}" in
      gd)
        PACKAGES="${PACKAGES} libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libwebp-dev zlib1g-dev"
        CONFIGURES="--with-freetype --with-jpeg --with-xpm --with-webp";;
      zip)
        PACKAGES="${PACKAGES} libzip-dev";;
    esac
    if [ -n "${PACKAGES}" ]; then
      apt-get install -y ${PACKAGES}>>$LOG
    fi
    if [ -n "${CONFIGURES}" ]; then
      docker-php-ext-configure ${EXT} ${CONFIGURES}>>$LOG
    fi
    docker-php-ext-install -j$(nproc) ${EXT}>>$LOG
    cp "${PHP_EXT_DIR}/${EXT}.so" "${CACHE_DIR}/${EXT}.so">>$LOG
  fi
done

# install PHP pecl extensions
for EXT in ${PECL_EXTENSIONS}; do
  if [ `php_ext_enabled ${EXT}` -eq 1 ]; then
    echo "Extension ${EXT} already enabled, skipping..."
    continue
  fi
  if [ -f "${CACHE_DIR}/${EXT}.so" ]; then
    cp "${CACHE_DIR}/${EXT}.so" "${PHP_EXT_DIR}/${EXT}.so">>$LOG
    docker-php-ext-enable ${EXT}>>$LOG
  else
    PACKAGES=""
    case "${EXT}" in
      mongodb)
        PACKAGES="${PACKAGES} libssl-dev";;
      xdebug)
        if [ "${EXT}" == "xdebug" ]; then
          if [ "${APP_DEBUG}" != "true" ]; then
            continue
          fi
        fi;;
    esac
    if [ -n "${PACKAGES}" ]; then
      apt-get install -y ${PACKAGES}>>$LOG
    fi
    pecl install ${EXT}>>$LOG
    docker-php-ext-enable ${EXT}>>$LOG
    cp "${PHP_EXT_DIR}/${EXT}.so" "${CACHE_DIR}/${EXT}.so">>$LOG
  fi
done

# prepare php.ini
PHP_INI=${PHP_INI_DIR}/php.ini
cp ${PHP_INI}-production ${PHP_INI}
sed -i -e "s#memory_limit = 128M#memory_limit = 1024M#g" ${PHP_INI}
sed -i -e "s#post_max_size = 8M#post_max_size = 0#g" ${PHP_INI}
sed -i -e "s#;date.timezone =#date.timezone = ${APP_TIMEZONE}#g" ${PHP_INI}

# reload apache
/etc/init.d/apache2 reload>>$LOG

# mark as ready
touch /tmp/.ready