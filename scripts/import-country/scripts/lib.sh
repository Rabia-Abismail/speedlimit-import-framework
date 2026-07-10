#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Configuration
################################################################################

BASE_DIR="/opt/speedlimit"
SCRIPT_IMPORT_COUNTRY_DIR="$BASE_DIR/scripts/import-country"

OSM_DIR="$BASE_DIR/osm"
SQL_DIR="$SCRIPT_IMPORT_COUNTRY_DIR/sql"
LOG_DIR="$SCRIPT_IMPORT_COUNTRY_DIR/log"
BACKUP_DIR="$SCRIPT_IMPORT_COUNTRY_DIR/backups"

DATABASE="osm"
DB_USER="speedlimit"

STYLE_FILE="$BASE_DIR/flex/roads.lua"

COUNTRIES_FILE="$SCRIPT_IMPORT_COUNTRY_DIR/config/countries.yml"

mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

################################################################################
# Colors
################################################################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

################################################################################
# Logging
################################################################################

log() {
    echo -e "${GREEN}[$(date '+%F %T')]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%F %T')] WARNING:${RESET} $1"
}

error() {
    echo -e "${RED}[$(date '+%F %T')] ERROR:${RESET} $1"
    exit 1
}

################################################################################
# Execute SQL
################################################################################

sql() {
    psql \
        -U "$DB_USER" \
        -d "$DATABASE" \
        -v ON_ERROR_STOP=1 \
        "$@"
}

################################################################################
# Check command
################################################################################

require_command() {

    command -v "$1" >/dev/null \
        || error "$1 is not installed"

}

################################################################################
# Requirements
################################################################################

check_requirements() {

    log "Checking requirements..."

    require_command wget
    require_command psql
    require_command osm2pgsql
    require_command osm2pgsql-replication
    require_command ogr2ogr
    require_command curl

    log "Requirements OK"

}

################################################################################
# Disk space
################################################################################

check_disk() {

    AVAILABLE=$(df --output=avail / | tail -1)

    AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))

    if [ "$AVAILABLE_GB" -lt 10 ]; then
        error "Less than 10 GB free"
    fi

    log "Disk OK (${AVAILABLE_GB} GB)"

}

################################################################################
# Memory
################################################################################

check_memory() {

    MEM=$(free -m | awk '/Mem:/ {print $2}')

    if [ "$MEM" -lt 700 ]; then
        warn "Less than 700 MB RAM"
    fi

}

################################################################################
# Country lookup
################################################################################

country_exists() {

    grep -q "^$1:" "$COUNTRIES_FILE"

}

country_property() {

    local COUNTRY="$1"
    local KEY="$2"

    awk -v country="$COUNTRY" -v key="$KEY" '

        $1==country":" {found=1; next}

        found && $1==key":" {

            print $2

            exit

        }

        /^[^ ]/ {

            found=0

        }

    ' "$COUNTRIES_FILE"

}

continent_of() {

    country_property "$1" continent

}

boundary_name() {

    country_property "$1" boundary_name

}

################################################################################
# Download URL
################################################################################

country_url() {

    COUNTRY="$1"

    CONTINENT=$(continent_of "$COUNTRY")

    echo "https://download.geofabrik.de/${CONTINENT}/${COUNTRY}-latest.osm.pbf"

}

################################################################################
# Download
################################################################################

download_country() {

    COUNTRY="$1"
    mkdir -p "$OSM_DIR/$COUNTRY"

    URL=$(country_url "$COUNTRY")

    cd "$OSM_DIR/$COUNTRY"

    log "Downloading"

    wget -N "$URL"

    cd -

}

################################################################################
# Schema
################################################################################

create_schema() {

    psql \
        -U "$DB_USER" \
        -d "$DATABASE" \
        -v country="$1" \
        -f "$SQL_DIR/create_schema.sql"

}

################################################################################
# Import
################################################################################

import_country() {

    COUNTRY="$1"

    FILE="$OSM_DIR/$COUNTRY/${COUNTRY}-latest.osm.pbf"

    log "Importing $COUNTRY"

    export PGHOST=localhost
    export PGUSER=speedlimit

    osm2pgsql \
        --create \
        --slim \
        --output=flex \
        --style="$STYLE_FILE" \
        --schema="$COUNTRY" \
        --database="$DATABASE" \
        "$FILE"

}

################################################################################
# Verify
################################################################################

verify_import() {

    COUNTRY="$1"

sql <<EOF

SELECT COUNT(*)
FROM ${COUNTRY}.roads;

EOF

}

################################################################################
# Replication
################################################################################

init_replication() {

    COUNTRY="$1"

    FILE="$OSM_DIR/$COUNTRY/${COUNTRY}-latest.osm.pbf"

    osm2pgsql-replication init \
        --database="$DATABASE" \
        --schema="$COUNTRY" \
        "$FILE"

}

################################################################################
# List imported countries
################################################################################

list_imported_countries() {

psql \
    -At \
    -U "$DB_USER" \
    -d "$DATABASE" \
<<EOF
SELECT schema_name
FROM countries
ORDER BY schema_name;
EOF

}

################################################################################
# Backup
################################################################################

backup_database() {

    FILE="$BACKUP_DIR/osm_$(date +%F).backup"

    log "Backup -> $FILE"

    pg_dump \
        -Fc \
        -U "$DB_USER" \
        "$DATABASE" \
        > "$FILE"

}

################################################################################
# Health
################################################################################

health_check() {

    log "PostgreSQL"

    pg_isready \
        -U "$DB_USER"

    log "Redis"

    redis-cli ping

    log "FastAPI"

    curl \
        -fs \
        http://127.0.0.1:8000/docs \
        >/dev/null

    log "Nginx"

    systemctl is-active nginx

}

################################################################################
# Summary
################################################################################

summary() {

    COUNTRY="$1"

    log "Finished"

    sql <<EOF

SELECT
    COUNT(*)
FROM
    ${COUNTRY}.roads;

EOF

}
