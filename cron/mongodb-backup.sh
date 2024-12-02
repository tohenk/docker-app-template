#!/bin/bash

CD=`dirname $0`
CD=`pushd $CD>/dev/null && pwd -P && popd>/dev/null`
ENV=${CD}/mongodb-backup.env

[ -f "${ENV}" ] && {

  . ${ENV}

  MONGODUMP=$(which mongodump)
  if [ -n "$MONGODUMP" -a -n "${DB_BACKUPS}" ]; then
    QUERY=/tmp/query.json
    SCRIPT=/tmp/mongodb-backup.js
    # list databases to backup if wildcard
    if [ "$DB_BACKUPS" = "*" ]; then
      cat << EOF > $SCRIPT
res = db.adminCommand({listDatabases: 1});
dbs = res.databases.map(d => d.name);
print(dbs.join(' '));
EOF
      DB_BACKUPS=$(mongosh -u $DB_USER -p $DB_PASSWORD --authenticationDatabase=admin --quiet mongodb://$DB_HOST:$DB_PORT/admin $SCRIPT)
    fi
    # prepare backup storage
    TOPDIR=/backup/MongoDB
    for DB in $DB_BACKUPS; do
      echo "--- mongodb://$DB_HOST:$DB_PORT/$DB ---"
      # get backup type -> full or delta
      BACKUP="delta"
      if [ -d "$TOPDIR/full" ]; then
        BACKUP="full"
        DIRS=$(ls $TOPDIR/full)
        if [ -n "$DIRS" ]; then
          for DIR in $DIRS; do
            if [ -d "$TOPDIR/full/$DIR/$DB" ]; then
              BACKUP="delta"
              break
            fi
          done
        fi
      else
        BACKUP="full"
      fi
      BACKUPDIR=$TOPDIR/$BACKUP/$(date +%Y%m%d)
      # get backup last date
      LASTDATE=""
      if [ "$BACKUP" != "full" ]; then
        # get last date from delta backup
        XDIR=$(dirname $BACKUPDIR)
        DIRS=$(ls $XDIR)
        if [ -n "$DIRS" ]; then
          echo "Found backup entries [${DIRS//$'\n'/ }]..."
          for DIR in $DIRS; do
            if [ -d "$XDIR/$DIR/$DB" ]; then
              LASTDATE=$DIR
              break
            fi
          done
        fi
        # get last date from full backup
        if [ -z "$LASTDATE" ]; then
          DIRS=$(ls $TOPDIR/full)
          if [ -n "$DIRS" ]; then
            for DIR in $DIRS; do
              if [ -d "$TOPDIR/full/$DIR/$DB" ]; then
                LASTDATE=$DIR
                break
              fi
            done
          fi
        fi
      fi
      # create backup directory
      mkdir -p $BACKUPDIR
      # execute backup
      if [ "$BACKUP" = "full" ]; then
        echo "Creating mongodb database full dump for $DB..."
        $MONGODUMP -h $DB_HOST:$DB_PORT -u $DB_USER -p $DB_PASSWORD --authenticationDatabase=admin -j 1 --gzip --out=$BACKUPDIR \
          --db=$DB
      elif [ -n "$LASTDATE" ]; then
        echo "Creating mongodb database delta dump for $DB..."
        DATE1="${LASTDATE:0:4}-${LASTDATE:4:2}-${LASTDATE:6:2}T23:59:59.999Z"
        DATE2="`date +%Y-%m-%d`T23:59:59.999Z"
        echo "Last backup date $LASTDATE..."
        echo "Delta backup performed from $DATE1 to $DATE2..."
        # backup fs.files collection
        cat << EOF > $QUERY
{"uploadDate":{"\$gt":{"\$date":"$DATE1"},"\$lte":{"\$date":"$DATE2"}}}
EOF
        $MONGODUMP -h $DB_HOST:$DB_PORT -u $DB_USER -p $DB_PASSWORD --authenticationDatabase=admin -j 1 --gzip --out=$BACKUPDIR \
          --db=$DB --collection=fs.files --queryFile=$QUERY
        # backup fs.chunks collection
        cat << EOF > $SCRIPT
db = db.getSiblingDB('$DB');
res = [];
c = db.fs.files.find({"uploadDate":{"\$gt":ISODate("$DATE1"),"\$lte":ISODate("$DATE2")}});
while (c.hasNext()) {
    res.push('{"\$oid":"_ID_"}'.replace(/_ID_/, c.next()._id));
}
print(res.join(','));
EOF
        IDS=$(mongosh -u $DB_USER -p $DB_PASSWORD --authenticationDatabase=admin --quiet mongodb://$DB_HOST:$DB_PORT/$DB $SCRIPT)
        if [ -n "$IDS" ]; then
          cat << EOF > $QUERY
{"files_id":{"\$in":[$IDS]}}
EOF
          $MONGODUMP -h $DB_HOST:$DB_PORT -u $DB_USER -p $DB_PASSWORD --authenticationDatabase=admin -j 1 --gzip --out=$BACKUPDIR \
            --db=$DB --collection=fs.chunks --queryFile=$QUERY
        fi
      fi
    done
  fi
}