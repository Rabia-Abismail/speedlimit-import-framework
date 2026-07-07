#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

for COUNTRY in $(list_imported_countries)
do

    echo

    log "Updating $COUNTRY"

    "$SCRIPT_DIR/update-country.sh" "$COUNTRY"

done

echo

log "All countries updated."
