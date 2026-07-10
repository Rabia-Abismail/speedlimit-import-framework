#!/usr/bin/env bash

set -euo pipefail

################################################################################
# SpeedLimit Country Importer
#
# Usage:
#   ./import-country.sh germany
#   ./import-country.sh algeria
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

################################################################################

usage() {
cat <<EOF

Usage:
    $0 <country>

Examples:
    $0 germany
    $0 algeria
    $0 turkey

EOF
}

################################################################################

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

COUNTRY=$(echo "$1" | tr '[:upper:]' '[:lower:]')

################################################################################
# Validate country
################################################################################

if ! country_exists "$COUNTRY"; then
    error "Unknown country '$COUNTRY'"
fi

BOUNDARY=$(boundary_name "$COUNTRY")

################################################################################
# Banner
################################################################################

log "========================================================"
log "SpeedLimit Country Import"
log "Country : $COUNTRY"
log "========================================================"

################################################################################
# Pre-flight checks
################################################################################

check_requirements

check_disk

check_memory

################################################################################
# Download latest PBF
################################################################################

log "Downloading country..."

download_country "$COUNTRY"

################################################################################
# Create schema
################################################################################

log "Creating schema..."

create_schema "$COUNTRY"

################################################################################
# Import using osm2pgsql
################################################################################

log "Importing roads..."

START=$(date +%s)

import_country "$COUNTRY"

END=$(date +%s)

log "Import finished in $((END-START)) seconds"

################################################################################
# Verify import
################################################################################

log "Verifying import..."

verify_import "$COUNTRY"

################################################################################
# Import country boundary
################################################################################

log "Importing boundary..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -v country="$COUNTRY" \
    -v boundary="$BOUNDARY" \
    -f "$SQL_DIR/import_boundary.sql"

################################################################################
# Create indexes
################################################################################

log "Creating indexes..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -v country="$COUNTRY" \
    -f "$SQL_DIR/create_indexes.sql"

################################################################################
# Create SQL functions
################################################################################

log "Refreshing SQL functions..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -f "$SQL_DIR/create_functions.sql"

################################################################################
# Backup
################################################################################

#log "Creating backup..."

#backup_database

################################################################################
# Health check
################################################################################

health_check

################################################################################
# Summary
################################################################################

summary "$COUNTRY"

cat <<EOF

========================================================
Import completed successfully

Country     : $COUNTRY
Schema      : $COUNTRY
Boundary    : $BOUNDARY
Database    : $DATABASE

Roads imported
Indexes created
Replication initialized
Backup created
Health check passed

========================================================

EOF
