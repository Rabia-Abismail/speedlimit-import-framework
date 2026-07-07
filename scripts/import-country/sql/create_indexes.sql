\set ON_ERROR_STOP on

\echo
\echo ============================================
\echo Creating indexes for :country
\echo ============================================

SELECT format(
'CREATE INDEX IF NOT EXISTS roads_geom_idx
 ON %I.roads
 USING GIST (geom)',
:'country')
AS sql
\gexec

SELECT format(
'CREATE INDEX IF NOT EXISTS roads_name_idx
 ON %I.roads(name)',
:'country')
AS sql
\gexec

SELECT format(
'CREATE INDEX IF NOT EXISTS roads_highway_idx
 ON %I.roads(highway)',
:'country')
AS sql
\gexec

SELECT format(
'ANALYZE %I.roads',
:'country')
AS sql
\gexec
