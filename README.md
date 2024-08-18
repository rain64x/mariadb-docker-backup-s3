# mariadb-docker-backup-s3
a script to backup all DB for specified MariaDB/MySQL docker container to AWS s3

## Instructions
1. Set all environment variables on top
2. Set a cron job, as this script won't run on its own -> preferrably add the following line in cron (runs daily at 00:00)
```bash
0 0 * * * /your/path/to/backup.sh
```
3. Ensure the script is executable
```bash
chmod +x backup.sh
```
4. You can run the backup.sh manually once to check if it uploads to s3
5. Done, check the next day for new backup in your s3
