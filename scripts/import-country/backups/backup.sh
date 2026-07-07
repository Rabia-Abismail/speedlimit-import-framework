#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

BACKUP_DIR="/opt/speedlimit/backups"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

FILE="$BACKUP_DIR/osm_$TIMESTAMP.dump"

log "Creating database backup..."

pg_dump \
    -Fc \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -f "$FILE"

gzip -f "$FILE"

FILE="$FILE.gz"

SIZE=$(du -h "$FILE" | cut -f1)

log "Backup completed"

echo
echo "=========================================="
echo "Backup file : $FILE"
echo "Size        : $SIZE"
echo "=========================================="


# keep only the last 30 days of backup...
find "$BACKUP_DIR" \
    -name "*.gz" \
    -mtime +30 \
    -delete
