#!/bin/bash

import_sql() {
  DB=$1
  SQL=$2
  if [ -f "$SQL" ]; then
    # create database
    HASDB=$(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DB}';" | mysql -u root -p${MYSQL_ROOT_PASSWORD} --silent)
    if [ "$HASDB" -eq "0" ]; then
      echo "Creating database ${DB}..."
      cat <<EOF | mysql -u root -p${MYSQL_ROOT_PASSWORD}
CREATE SCHEMA ${DB};
GRANT ALL PRIVILEGES ON ${DB}.* TO '${MYSQL_USER}'@'%';
EOF
    fi
    SQLTMP=/tmp/$(basename ${SQL})
    echo "Import ${SQL} into ${DB}..."
    # copy to temporary
    cp ${SQL} /tmp
    # fix storage engine (e.g. remove MyISAM and use default storage engine)
    sed -i -e 's/ ENGINE=MyISAM//g' ${SQLTMP}
    # import sql
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -D ${DB}<${SQLTMP}
    # cleanup
    rm -f ${SQLTMP}
  fi
}

SQLDIR=/sql
for DIR in $SQLDIR/*; do
  DB=$(basename $DIR)
  for SQL in $DIR/*.sql; do
    import_sql $DB $SQL
  done
done
