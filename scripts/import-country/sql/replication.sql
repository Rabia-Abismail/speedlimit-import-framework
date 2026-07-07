\set ON_ERROR_STOP on

UPDATE countries
SET
    replication_enabled = TRUE,
    replication_last_update = NOW()
WHERE
    schema_name = :'country';

SELECT
    name,
    schema_name,
    replication_enabled,
    replication_last_update
FROM countries
WHERE schema_name = :'country';
