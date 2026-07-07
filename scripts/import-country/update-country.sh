#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

usage() {

cat <<EOF

Usage:

    $0 <country>

Example:

    $0 germany
    $0 algeria

EOF

}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

COUNTRY=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if ! country_exists "$COUNTRY"; then
    error "Unknown country: $COUNTRY"
fi

SCHEMA="$COUNTRY"

PBF="$OSM_DIR/$COUNTRY/$COUNTRY-latest.osm.pbf"

if [ ! -f "$PBF" ]; then
    error "$PBF does not exist."
fi

log "Updating $COUNTRY..."

##############################################################################
# Backup
##############################################################################

backup_database

##############################################################################
# Replication
##############################################################################

osm2pgsql-replication update \
    --database="$DATABASE" \
    --schema="$SCHEMA" \
    --state-dir="/opt/speedlimit/replication/$COUNTRY"

##############################################################################
# Update replication timestamp
##############################################################################

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
<<EOF
UPDATE countries
SET replication_last_update = NOW()
WHERE schema_name='$COUNTRY';
EOF

##############################################################################
# Refresh statistics
##############################################################################

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
<<EOF
VACUUM ANALYZE $SCHEMA.roads;
EOF

##############################################################################
# Health check
##############################################################################

health_check

echo
echo "========================================="
echo "$COUNTRY updated successfully."
echo "========================================="
