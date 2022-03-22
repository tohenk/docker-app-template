#!/bin/bash

echo "=== `basename $0` ==="

LOG=/var/log/init.log
RETRY=2

# set timezone
if [ -n "${APP_TIMEZONE}" ]; then
  ln -sf /usr/share/zoneinfo/${APP_TIMEZONE} /etc/localtime
  dpkg-reconfigure -f noninteractive tzdata>>$LOG
fi

apt_mirror() {
  sed -i -e "s/deb\.debian\.org/kartolo\.sby\.datautama\.net\.id/g" /etc/apt/sources.list
}

apt_updates() {
  for i in {1..$RETRY}; do
    apt-get update>>$LOG
  done
}

apt_install() {
  for i in {1..$RETRY}; do
    apt-get install -y $@>>$LOG
  done
}

get_php_ini() {
  KEY=$1
  IFS="=>" read -r -a ARR <<< `php -i | grep "^${KEY}"`
  echo ${ARR[2]} | xargs
}

ROOT_DIR=/home/www
APP_DIR=${ROOT_DIR}/app
VAR_DIR=${ROOT_DIR}/var
CACHE_DIR=/cache/php8.0/$(uname -m)
EXTENSIONS="gd mysqli pdo_mysql zip"
PECL_EXTENSIONS="mongodb xdebug"

PHP_INI_DIR=`get_php_ini 'Configuration File (php.ini) Path'`
PHP_EXT_DIR=`get_php_ini 'extension_dir'`

echo "PHP ini dir = ${PHP_INI_DIR}...">>$LOG
echo "Extension dir = ${PHP_EXT_DIR}...">>$LOG

mkdir -p ${CACHE_DIR}>>$LOG

# give write access to app var
for F in `ls ${VAR_DIR}`; do
  if [ -d ${VAR_DIR}/${F} ]; then
    chmod -R 0777 ${VAR_DIR}/${F}>>$LOG
  fi
done

# update packages
apt_mirror
apt_updates

# install PHP extensions
for EXT in ${EXTENSIONS}; do
  if [ -f "${CACHE_DIR}/${EXT}.so" ]; then
    cp "${CACHE_DIR}/${EXT}.so" "${PHP_EXT_DIR}/${EXT}.so">>$LOG
    PACKAGES=""
    case "${EXT}" in
      gd)
        PACKAGES="${PACKAGES} libfreetype6 libjpeg62-turbo libpng16-16 libxpm4 libwebp6 zlib1g";;
      zip)
        PACKAGES="${PACKAGES} libzip4";;
    esac
    if [ -n "${PACKAGES}" ]; then
      apt_install ${PACKAGES}
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
      apt_install ${PACKAGES}
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
      apt_install ${PACKAGES}
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

# mark as initialized
touch /tmp/.initialized

# run add-ons
if [ -f /scripts/addons.lst ]; then
  for ADDON in `cat /scripts/addons.lst`; do
    if [ -f /scripts/${ADDON} ]; then
      echo "=== ${ADDON} ==="
      cp /scripts/${ADDON} ~/${ADDON}
      chmod +x ~/${ADDON}
      ~/${ADDON}
    fi
  done
fi
