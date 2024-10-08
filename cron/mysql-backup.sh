#!/bin/bash

CD=`dirname $0`
CD=`pushd $CD>/dev/null && pwd -P && popd>/dev/null`
ENV=${CD}/mysql-backup.var

[ -f "${ENV}" ] && {

  . ${ENV}

  MYSQLDUMP=$(which mysqldump)
  if [ -n "$MYSQLDUMP" -a -n "${DB_BACKUPS}" ]; then
    ZZ=$(which 7z)
    [ -z "${ZZ}" ] && ZZ=$(which 7zz)
    # prepare backup storage
    BACKUPDIR=/backup/MySQL
    if [ `date +%d` = "01" ]; then
      DAILY="false"
      BACKUPDIR=$BACKUPDIR/monthly
    else
      DAILY="true"
      BACKUPDIR=$BACKUPDIR/daily
    fi
    BACKUPDIR=$BACKUPDIR/$(date +%Y%m%d)
    mkdir -p $BACKUPDIR
    # execute backup
    for DB in $DB_BACKUPS; do
      DB_BACKUP=$BACKUPDIR/$DB.sql.7z
      echo "Creating MySQL database dump for $DB..."
      [ -f "$DB_BACKUP" ] && mv "$DB_BACKUP" "$DB_BACKUP~"
      $MYSQLDUMP --single-transaction --routines --quick --set-gtid-purged=OFF -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD $DB | \
        $ZZ a -si "$DB_BACKUP"
    done
    # cleanup daily backup
    if [ "$DAILY" = "true" ]; then
      BACKUPDIR=$(dirname $BACKUPDIR)
      DIRS=$(ls $BACKUPDIR)
      if [ -n "$DIRS" ]; then
        echo "Found daily backup entries [$DIRS]..."
        MAXBACKUP=7
        N=0
        for DIR in $DIRS; do
          if [ -d "$BACKUPDIR/$DIR" ]; then
            ((N++))
          fi
        done
        for DIR in $DIRS; do
          if [ -d "$BACKUPDIR/$DIR" -a $N -gt $MAXBACKUP ]; then
            echo "Cleaning up backup $DIR..."
            rm -rf $BACKUPDIR/$DIR
            ((N--))
          fi
        done
      fi
    fi
  fi
}
