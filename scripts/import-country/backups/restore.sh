#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

BACKUP_DIR="/opt/speedlimit/backups"

usage() {

cat <<EOF

Usage:

    $0 <backup-file>

Example:

    $0 osm_20260707_153000.dump.gz

EOF

}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

FILE="$BACKUP_DIR/$1"

if [ ! -f "$FILE" ]; then
    error "Backup not found: $FILE"
fi


read -p "This will overwrite the current database. Continue? [y/N] " answer

case "$answer" in
    y|Y|yes|YES)
        ;;
    *)
        exit 1
        ;;
esac


TMP=""

if [[ "$FILE" == *.gz ]]; then

    TMP=$(mktemp /tmp/osm_restore_XXXX.dump)

    gunzip -c "$FILE" > "$TMP"

    FILE="$TMP"

fi

log "Stopping API..."

sudo systemctl stop speedlimit

log "Dropping active connections..."

psql \
    -U "$DB_USER" \
    -d postgres \
    -c "
SELECT
pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname='$DATABASE'
AND pid <> pg_backend_pid();
"

log "Restoring database..."

pg_restore \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    -U "$DB_USER" \
    -d "$DATABASE" \
    "$FILE"

if [ -n "$TMP" ]; then
    rm -f "$TMP"
fi

log "Recreating SQL functions..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -f "$SQL_DIR/create_functions.sql"

log "Starting API..."

sudo systemctl start speedlimit

echo
echo "=========================================="
echo "Restore completed successfully"
echo "=========================================="
