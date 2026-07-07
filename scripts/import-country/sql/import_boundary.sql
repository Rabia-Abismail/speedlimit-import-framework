\set ON_ERROR_STOP on

\echo
\echo ============================================
\echo Importing boundary for :country
\echo ============================================

INSERT INTO countries
(
    name,
    schema_name,
    geom,
    replication_enabled,
    replication_last_update
)
SELECT
    :'boundary',
    :'country',
    ST_Multi(wkb_geometry),
    TRUE,
    NOW()
FROM country_boundaries
WHERE name = :'boundary'

ON CONFLICT(schema_name)
DO UPDATE
SET
    name = EXCLUDED.name,
    geom = EXCLUDED.geom,
    replication_enabled = TRUE,
    replication_last_update = NOW();
