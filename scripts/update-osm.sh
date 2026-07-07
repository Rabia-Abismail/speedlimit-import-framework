#!/usr/bin/env bash
set -euo pipefail

export PGPASSWORD="root"

BASE=/opt/speedlimit

BACKUP_DIR=$BASE/backups
LOG_DIR=$BASE/logs

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/update-$(date +%F).log"

echo "===============================" >> "$LOG_FILE"
echo "$(date)" >> "$LOG_FILE"
echo "===============================" >> "$LOG_FILE"

echo "Creating backup..." >> "$LOG_FILE"

pg_dump \
    -Fc \
    -U speedlimit \
    osm \
> "$BACKUP_DIR/osm-$(date +%F-%H%M).dump"

echo "Backup completed." >> "$LOG_FILE"

echo "Deleting old backups..." >> "$LOG_FILE"

cd "$BACKUP_DIR"

ls -tp *.dump | tail -n +9 | xargs -r rm --

echo "Updating replication..." >> "$LOG_FILE"

osm2pgsql-replication update \
    -d osm \
    -U speedlimit \
>> "$LOG_FILE" 2>&1

echo "Finished replicating..." >> "$LOG_FILE"

echo "Clearing Redis cache..." >> "$LOG_FILE"
redis-cli FLUSHALL
