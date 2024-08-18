#!/bin/bash

CONTAINER_NAME="WordpressDBs"                      # name of the mariadb container
DB_USER="root"
DB_PASSWORD="yourdbpassword"
BACKUP_DIR="$(dirname "$0")"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
BACKUP_FILE="$BACKUP_DIR/database-$DATE.sql"        # on host - filename of the backup
TEMP_FILE="/backup.sql"                             # inside container
TAR_FILE="$BACKUP_DIR/database-$DATE.tar.gz"        # Tarball file for S3 upload

BUCKET_NAME="backups-bucket"
BUCKET_SUBFOLDER="WordpressDBs"
AWS_ACCESS_KEY_ID="YOUR_AMAZON_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_AMAZON_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION="eu-central-1"
BACKUP_DEST="s3://$BUCKET_NAME/$BUCKET_SUBFOLDER"

# Execute mariadb-dump command inside the container to backup all databases
docker exec $CONTAINER_NAME sh -c "mariadb-dump -u $DB_USER --password=$DB_PASSWORD --all-databases > $TEMP_FILE"

# Copy backup file from container to host (current directory of the script)
docker cp $CONTAINER_NAME:$TEMP_FILE $BACKUP_FILE

# Perform cleanup (delete backup file from container)
docker exec $CONTAINER_NAME rm $TEMP_FILE


# Run AWS CLI configure command with provided credentials
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region "$AWS_DEFAULT_REGION"

# Function to perform backup
perform_backup_to_s3() {
    echo "Starting backup at $(date)"

    # Create the tarball from the SQL backup file
    tar -czf "$TAR_FILE" -C "$BACKUP_DIR" "$(basename "$BACKUP_FILE")"

    # Sync tarball to S3 bucket
    echo "Syncing tarball to S3 bucket..."
    if aws s3 cp "$TAR_FILE" "$BACKUP_DEST/$(basename "$TAR_FILE")"; then
        echo "Sync of tarball to S3 bucket completed."
        # Remove tarball and original SQL backup file after successful upload
        rm "$TAR_FILE" "$BACKUP_FILE"
    else
        echo "Failed to sync tarball to S3 bucket."
    fi

    echo "Backup completed at $(date)"
}

# Main script
perform_backup_to_s3
