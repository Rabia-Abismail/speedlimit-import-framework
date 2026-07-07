\set ON_ERROR_STOP on

\echo
\echo ============================================
\echo Verifying :country
\echo ============================================

SELECT
    COUNT(*) AS roads
FROM
    :"country".roads;

SELECT
    COUNT(*) FILTER (WHERE maxspeed IS NOT NULL) AS roads_with_speed,
    COUNT(*) FILTER (WHERE name IS NOT NULL) AS roads_with_name,
    COUNT(*) FILTER (WHERE oneway IS TRUE) AS one_way_roads
FROM
    :"country".roads;

SELECT
    MIN(ST_XMin(geom)) AS min_lon,
    MAX(ST_XMax(geom)) AS max_lon,
    MIN(ST_YMin(geom)) AS min_lat,
    MAX(ST_YMax(geom)) AS max_lat
FROM
    :"country".roads;
