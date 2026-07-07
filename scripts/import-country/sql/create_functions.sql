\set ON_ERROR_STOP on

\echo
\echo ============================================
\echo Creating PostgreSQL functions
\echo ============================================

DROP FUNCTION IF EXISTS find_country(double precision, double precision);

CREATE OR REPLACE FUNCTION find_country(
    p_lon double precision,
    p_lat double precision
)
RETURNS text
LANGUAGE sql
STABLE
AS
$$
SELECT schema_name
FROM countries
WHERE ST_Contains(
    geom,
    ST_SetSRID(ST_Point(p_lon, p_lat), 4326)
)
LIMIT 1;
$$;


DROP FUNCTION IF EXISTS find_speed_limit(double precision, double precision);

CREATE OR REPLACE FUNCTION find_speed_limit(
    p_lon double precision,
    p_lat double precision
)
RETURNS TABLE(
    road text,
    highway text,
    maxspeed text,
    maxspeed_forward text,
    maxspeed_backward text,
    maxspeed_type text,
    oneway boolean,
    bridge boolean,
    tunnel boolean,
    layer smallint,
    distance double precision,
    country text
)
LANGUAGE plpgsql
STABLE
AS
$$
DECLARE
    v_schema text;
    sql text;
BEGIN

    v_schema := find_country(p_lon, p_lat);

    IF v_schema IS NULL THEN
        RETURN;
    END IF;

    sql := format($SQL$

        SELECT
            name,
            highway,
            maxspeed,
            maxspeed_forward,
            maxspeed_backward,
            maxspeed_type,
            oneway,
            bridge,
            tunnel,
            layer,
            ST_Distance(
                geom::geography,
                ST_SetSRID(ST_Point($1,$2),4326)::geography
            ) AS distance,
            %L AS country

        FROM %I.roads

        WHERE ST_DWithin(
            geom::geography,
            ST_SetSRID(ST_Point($1,$2),4326)::geography,
            60
        )

        ORDER BY geom <-> ST_SetSRID(ST_Point($1,$2),4326)

        LIMIT 1

    $SQL$, v_schema, v_schema);

    RETURN QUERY
    EXECUTE sql
    USING p_lon, p_lat;

END;
$$;
