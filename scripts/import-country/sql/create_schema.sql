\set ON_ERROR_STOP on

\echo
\echo ============================================
\echo Creating schema : :country
\echo ============================================
\echo

SELECT format(
    'CREATE SCHEMA IF NOT EXISTS %I AUTHORIZATION speedlimit',
    :'country'
) AS sql
\gexec

SELECT format(
    'COMMENT ON SCHEMA %I IS %L',
    :'country',
    'OSM road data'
) AS sql
\gexec

SELECT format(
    'GRANT USAGE ON SCHEMA %I TO speedlimit',
    :'country'
) AS sql
\gexec

SELECT format(
    'GRANT CREATE ON SCHEMA %I TO speedlimit',
    :'country'
) AS sql
\gexec

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = :'country';
