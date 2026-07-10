#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo
    echo "./remove-country.sh germany"
    exit 1
fi

COUNTRY="$1"

read -p "Delete '$COUNTRY'? [y/N] " answer

case "$answer" in
    y|Y|yes|YES)
        ;;
    *)
        exit 0
        ;;
esac

backup_database

echo
echo "Removing database schema..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" <<EOF

DROP SCHEMA IF EXISTS ${COUNTRY}_replication CASCADE;

DROP SCHEMA IF EXISTS $COUNTRY CASCADE;

DELETE
FROM countries
WHERE schema_name='$COUNTRY';

EOF

echo
echo "Removing downloaded files..."

rm -rf "$OSM_DIR/$COUNTRY"

echo
echo "Refreshing SQL functions..."

psql \
    -U "$DB_USER" \
    -d "$DATABASE" \
    -f "$SQL_DIR/create_functions.sql"

echo
echo "Country removed."
