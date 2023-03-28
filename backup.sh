#!/bin/bash
set uexo

# check .env file exists
if [ ! -f .env ]; then
  echo ".env file not found"
  exit 1
fi

# vars
source .env

# create backup if not exists
mkdir -p $BACKUPDIR

###########
# backup db
###########
cd $WPDIR
mysqldump -u ${DB_USER} -p${DB_PASS}  --single-transaction --quick --lock-tables=false $DB_NAME | gzip > "${BACKUPDIR}"/db.sql.gz

# upload to s3 adding date
aws s3 cp "${BACKUPDIR}"/db.sql.gz s3://$BUCKET/db/"$(date +%Y-%m-%d)"-db.sql.gz

# clean old backups in /db
aws s3 ls s3://$BUCKET/db/ | sort -r | awk "NR>$DB_KEEP_DAYS {print \$4}" | xargs -I {} aws s3 rm s3://$BUCKET/db/{}

##########################
# backup code (no uploads)
##########################
cd $WPDIR
tar \
  --exclude='*/cache' \
  --exclude='./wp-content/uploads' \
  -czf "${BACKUPDIR}"/files.tar.gz ./

# upload to s3 adding date
aws s3 cp "${BACKUPDIR}"/files.tar.gz s3://$BUCKET/files/"$(date +%Y-%m-%d)"-files.tar.gz

# clean old backups in /files
aws s3 ls s3://$BUCKET/files/ | sort -r | awk "NR>$FILES_KEEP_DAYS {print \$4}" | xargs -I {} aws s3 rm s3://$BUCKET/files/{}

###########################################
# backup uploads
# sync files in last and current month only.
# the very first time, sync everything with: 
# aws s3 sync $WPDIR/wp-content/uploads s3://$BUCKET/uploads
###########################################

# go to uploads
cd $WPDIR/wp-content/uploads

# sync files past month
LAST_MONTH=`date -d "$(date +%Y-%m-1) -1 month" +%Y/%m`
aws s3 sync $WPDIR/wp-content/uploads/$LAST_MONTH s3://$BUCKET/uploads/$LAST_MONTH

# sync files this month
THIS_MONTH=`date -d "$(date +%Y-%m-1) 0 month" +%Y/%m`
aws s3 sync $WPDIR/wp-content/uploads/$THIS_MONTH s3://$BUCKET/uploads/$THIS_MONTH
