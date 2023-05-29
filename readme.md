# Intro

- Backup database and files fully
- Backup uploads folder incrementally, only last and current month

# Requisites

- command aws in server working (run `aws configure`)
- bucket and user
- check `which aws` is the same as backup.sh

# Configure

Clone the repo and edit variables in .env file

```sh
mkdir -p ~/scripts
git clone https://github.com/eduardoarandah/amazon-s3-backup-wordpress.git ~/scripts/backup
cd ~/scripts/backup
cp .env.example .env

chmod +x ~/scripts/backup/backup.sh
```

# Run backup

```sh
/bin/bash ~/scripts/backup/backup.sh
```

# Cron job example

```
* * * * * cd ~/webapps/XXXX/public && wp cron event run --due-now >/dev/null 2>&1
0 3 * * * cd ~/webapps/XXXX/public && wp core update && wp core update-db
15 3 * * * /bin/bash ~/scripts/backup/backup.sh | tee -a ~/backup.log 2>&1
```

# To sync all uploads folder, run once:

Example:

```sh
WPDIR=/home/my-user/webapps/my-app/public
BUCKET=my-app-backup
aws s3 sync $WPDIR/wp-content/uploads s3://$BUCKET/uploads
```

