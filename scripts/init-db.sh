#!/bin/bash

import_sql() {
  DB=$1
  SQL=$2
  CREATE=$3
  if [ -f "$SQL" ]; then
    SQLTMP=/tmp/$(basename ${SQL})
    echo "Import ${SQL} into ${DB}..."
    cp ${SQL} /tmp
    # fix storage engine (e.g. remove MyISAM and use default storage engine)
    sed -i -e 's/ ENGINE=MyISAM//g' ${SQLTMP}
    # create database
    if [ "${CREATE}" == "1" ]; then
      echo "CREATE SCHEMA ${DB}; GRANT ALL PRIVILEGES ON ${DB}.* TO '${MYSQL_USER}'@'%';" | mysql -u root -p${MYSQL_ROOT_PASSWORD}
    fi
    # import sql
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -D ${DB} < ${SQLTMP}
    # cleanup
    rm -f ${SQLTMP}
  fi
}

SQLDIR=/sql
for DIR in $SQLDIR/*; do
  DB=$(basename $DIR)
  CREATEDB=1
  for SQL in $DIR/*.sql; do
    if [ -f $SQL ]; then
      import_sql $DB $SQL $CREATEDB
    fi
    if [ "${CREATEDB}" == "1" ]; then
      CREATEDB=0
    fi
  done
done
