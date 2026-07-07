#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

echo
echo "========================================="
echo " SpeedLimit Health Check"
echo "========================================="
echo

########################################
# PostgreSQL
########################################

log "Checking PostgreSQL..."

psql -U "$DB_USER" -d "$DATABASE" -c "SELECT version();" >/dev/null

echo "✓ PostgreSQL"

########################################
# PostGIS
########################################

psql -U "$DB_USER" -d "$DATABASE" \
-c "SELECT PostGIS_Version();" >/dev/null

echo "✓ PostGIS"

########################################
# Redis
########################################

log "Checking Redis..."

redis-cli ping >/dev/null

echo "✓ Redis"

########################################
# API
########################################

log "Checking API..."

curl -fs http://127.0.0.1:8000/docs >/dev/null

echo "✓ FastAPI"

########################################
# Nginx
########################################

log "Checking nginx..."

systemctl is-active nginx >/dev/null

echo "✓ nginx"

########################################
# Imported countries
########################################

echo
echo "Imported countries"

psql -U "$DB_USER" -d "$DATABASE" <<EOF
SELECT
    schema_name,
    replication_enabled,
    replication_last_update
FROM countries
ORDER BY schema_name;
EOF

########################################
# Replication status
########################################

echo
echo "Replication"

for COUNTRY in $(list_imported_countries)
do
    echo
    echo "----- $COUNTRY -----"

    osm2pgsql-replication status \
        -d "$DATABASE" \
        --schema "$COUNTRY" \
        --middle-schema "${COUNTRY}_replication"

done

########################################
# Disk
########################################

echo
df -h /

########################################
# Memory
########################################

echo
free -h

########################################
# Finished
########################################

echo
echo "✓ Health check completed."
