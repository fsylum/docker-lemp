#!/bin/bash
# Dumps MySQL database to a compressed file with 7-day retention.
# Usage: backup-db.sh /path/to/project
# Cron:  0 3 * * * /srv/example.com/docker/scripts/backup-db.sh /srv/example.com

set -euo pipefail

PROJECT_DIR="${1:-.}"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Load environment variables
source "$PROJECT_DIR/.env"

mkdir -p "$BACKUP_DIR"

FILENAME="${COMPOSE_PROJECT_NAME:-docker-lemp}_${TIMESTAMP}.sql.gz"

docker compose -f "$PROJECT_DIR/docker-compose.yml" \
  exec -T mysql mysqldump \
  -u"${MYSQL_USER:-docker}" \
  -p"${MYSQL_PASSWORD:-password}" \
  "${MYSQL_DATABASE:-docker}" \
  | gzip > "$BACKUP_DIR/$FILENAME"

# Retain only the last 7 days of backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo "Backup complete: $FILENAME"
