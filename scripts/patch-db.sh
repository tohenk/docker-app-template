#!/bin/bash

create_patch_db() {
  DB=$1
  HASDB=$(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DB}';" | mysql -u root -p${MYSQL_ROOT_PASSWORD} --silent)
  if [ "$HASDB" -eq "0" ]; then
    echo "Creating patch database ${DB}..."
    cat <<EOF | mysql -u root -p${MYSQL_ROOT_PASSWORD}
CREATE SCHEMA ${DB};
GRANT ALL PRIVILEGES ON ${DB}.* TO '${MYSQL_USER}'@'%';
USE ${DB};
CREATE TABLE patchinfo (
  id INT NOT NULL AUTO_INCREMENT,
  ver INT,
  patched TIMESTAMP default CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);
EOF
  fi
}

patch_sql() {
  DB=$1
  SQL=$2
  if [ -f "$SQL" ]; then
    echo "Patching ${SQL} into ${DB}..."
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -D ${DB}<$SQL
  fi
}

echo "=== Patch database begin ==="

# wait for mysqld
while ! mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} --silent ping; do
  sleep 1
done

# wait more
sleep 3

echo "Scanning for patches..."

PATCHDB=${MYSQL_PATCH_DB_NAME:-patchdb}
SQLPATCHDIR=/sql-patches

create_patch_db $PATCHDB
VER=$(echo "SELECT ver FROM ${PATCHDB}.patchinfo WHERE id IN (SELECT MAX(id) FROM ${PATCHDB}.patchinfo);" | mysql -u root -p${MYSQL_ROOT_PASSWORD} --silent)
VER=${VER:-0}
NVER=$VER

echo "Current patch version is $NVER..."

for VERDIR in $SQLPATCHDIR/*; do
  V=$(basename $VERDIR)
  if [[ "$V" =~ ^[0-9]+$ ]]; then
    if [ "$V" -gt "$NVER" ]; then
      echo "Applying version $V..."
      NVER=$V
      for DBDIR in $VERDIR/*; do
        DB=$(basename $DBDIR)
        for SQL in $DBDIR/*.sql; do
          patch_sql $DB $SQL
        done
      done
    fi
  fi
done

if [ "$NVER" -gt "$VER" ]; then
  echo "Saving patch version ${NVER}..."
  echo "INSERT INTO ${PATCHDB}.patchinfo VALUES (NULL, ${NVER}, NULL);" | mysql -u root -p${MYSQL_ROOT_PASSWORD}
fi

echo "=== Patch database end ==="
