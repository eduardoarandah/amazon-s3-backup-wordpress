#!/bin/bash
set uexo

# check ~/scripts/backup/.env file exists
if [ ! -f ~/scripts/backup/.env ]; then
  echo "~/scripts/backup/.env file not found"
  exit 1
fi

echo "~/scripts/backup/.env file found, loading..."

# vars
source ~/scripts/backup/.env

# create backup if not exists
mkdir -p $BACKUPDIR

###########
# backup db
###########

echo "backup db..."
cd $WPDIR
mysqldump -u ${DB_USER} -p${DB_PASS}  --single-transaction --quick --lock-tables=false $DB_NAME | gzip > "${BACKUPDIR}"/db.sql.gz

# upload to s3 adding date
echo "upload to s3..."
aws s3 cp "${BACKUPDIR}"/db.sql.gz s3://$BUCKET/db/"$(date +%Y-%m-%d)"-db.sql.gz

# clean old backups in /db
echo "clean old backups..."
aws s3 ls s3://$BUCKET/db/ | sort -r | awk "NR>$DB_KEEP_DAYS {print \$4}" | xargs -I {} aws s3 rm s3://$BUCKET/db/{}

##########################
# backup code (no uploads)
##########################
cd $WPDIR
echo "backup code (no uploads)..."
tar \
  --exclude='*/cache' \
  --exclude='./wp-content/uploads' \
  -czf "${BACKUPDIR}"/files.tar.gz ./

# upload to s3 adding date
echo "upload code (no uploads) to s3..."
aws s3 cp "${BACKUPDIR}"/files.tar.gz s3://$BUCKET/files/"$(date +%Y-%m-%d)"-files.tar.gz

# clean old backups in s3 /files
echo "clean old backups in s3..."
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
echo "sync files past month..."
LAST_MONTH=`date -d "$(date +%Y-%m-1) -1 month" +%Y/%m`
aws s3 sync $WPDIR/wp-content/uploads/$LAST_MONTH s3://$BUCKET/uploads/$LAST_MONTH

# sync files this month
echo "sync files this month..."
THIS_MONTH=`date -d "$(date +%Y-%m-1) 0 month" +%Y/%m`
aws s3 sync $WPDIR/wp-content/uploads/$THIS_MONTH s3://$BUCKET/uploads/$THIS_MONTH
