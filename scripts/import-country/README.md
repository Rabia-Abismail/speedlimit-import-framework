# SpeedLimit Import Framework

## Usage

``` bash
chmod +x import-country.sh
./import-country.sh germany
```

Prerequisites:

-   PostgreSQL/PostGIS installed
-   osm2pgsql
-   flex/roads.lua
-   countries table already created
-   FastAPI, Redis and Nginx already configured

After import: - insert boundary into `countries` - verify with
sql/verify.sql - test `/speedlimit` - backup database
