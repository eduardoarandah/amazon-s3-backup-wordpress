# Intro

- Backup database and files fully
- Backup uploads folder incrementally, only last and current month

# Configure

Clone the repo and edit variables in .env file

```sh
git clone https://github.com/eduardoarandah/amazon-s3-backup-wordpress.git ~/scripts
cd ~/scripts
cp .env.example .env
```

# Run backup

```sh
~/scripts/backup.sh
```

# Cron job example

```
* * * * * cd ~/webapps/XXXX/public && wp cron event run --due-now >/dev/null 2>&1
0 3 * * * cd ~/webapps/XXXX/public && wp core update && wp core update-db
15 3 * * * ~/scripts/backup.sh
```

# To sync all uploads folder, run once:

Example:

```sh
WPDIR=/home/my-user/webapps/my-app/public
BUCKET=my-app-backup
aws s3 sync $WPDIR/wp-content/uploads s3://$BUCKET/uploads
```

