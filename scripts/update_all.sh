#!/usr/bin/env bash

set -e

BASE=/opt/speedlimit
LOG=$BASE/logs/update.log

echo "===== $(date) =====" >> "$LOG"

for COUNTRY in algeria germany
do
    echo "Updating $COUNTRY..." >> "$LOG"

    # Future:
    # osm2pgsql-replication update ...

    echo "$COUNTRY finished." >> "$LOG"
done
