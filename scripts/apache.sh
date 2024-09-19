#!/bin/bash

if [ -f "${APACHE_APP_CONF}" ]; then
  # set apache site configuration
  rm -rf ${APACHE_CONFDIR}/sites-enabled/*
  ln -s ${APACHE_APP_CONF} ${APACHE_CONFDIR}/sites-enabled/
  # patch listen ports
  if [ -n "${APP_HTTP_PORT}" ]; then
    sed -i -e "s/Listen 80/Listen ${APP_HTTP_PORT}/g" ${APACHE_CONFDIR}/ports.conf
  fi
  if [ -n "${APP_HTTPS_PORT}" ]; then
    sed -i -e "s/Listen 443/Listen ${APP_HTTPS_PORT}/g" ${APACHE_CONFDIR}/ports.conf
  fi
  # adjust workers and connections
  if [ -n "${APP_HTTP_WORKERS}" ]; then
    sed -i -e "s/MaxRequestWorkers       150/MaxRequestWorkers       ${APP_HTTP_WORKERS}/g" \
      ${APACHE_CONFDIR}/mods-available/mpm_prefork.conf
  fi
  if [ -n "${APP_HTTP_CONNECTIONS}" ]; then
    sed -i -e "s/MaxConnectionsPerChild  0/MaxConnectionsPerChild  ${APP_HTTP_CONNECTIONS}/g" \
      ${APACHE_CONFDIR}/mods-available/mpm_prefork.conf
  fi
  # enable ssl and rewrite module
  a2enmod ssl rewrite
fi
