# SpeedLimit API

A self-hosted, high-performance Speed Limit API built on OpenStreetMap (OSM), PostgreSQL/PostGIS, FastAPI, Redis, and Nginx.

The project provides a scalable backend capable of importing one or more countries from OpenStreetMap, automatically detecting the country from GPS coordinates, and returning road attributes such as speed limits with very low response times.

Unlike cloud map providers, this solution is fully self-hosted and can be expanded to support any country available from Geofabrik.

---

# Features

* Self-hosted speed limit service
* Automatic country detection from latitude/longitude
* Multi-country support
* PostgreSQL + PostGIS spatial queries
* FastAPI REST API
* Redis response caching
* Nginx reverse proxy
* Automatic OSM replication updates
* Country boundary management
* Automated country import framework
* Backup and restore scripts
* Health check utilities
* Country removal utility
* Git-friendly project structure
* Designed for horizontal growth

---

# Architecture

```
                    Client App
                         |
                         |
                     HTTPS / REST
                         |
                    +------------+
                    |   Nginx    |
                    +------------+
                         |
                         |
                    +------------+
                    |  FastAPI   |
                    +------------+
                         |
              +----------+----------+
              |                     |
              |                     |
         PostgreSQL            Redis Cache
           + PostGIS
              |
              |
    +---------+---------+
    |                   |
 Algeria Schema     Germany Schema
    |                   |
    +---------+---------+
              |
      Country Boundaries
```

---

# Repository Structure

```
speedlimit-framework/

├── README.md
├── LICENSE
├── VERSION
├── .gitignore
│
├── scripts/
│   ├── import-country.sh
│   ├── update-country.sh
│   ├── update-all.sh
│   ├── remove-country.sh
│   ├── health-check.sh
│   └── lib.sh
│
├── sql/
│   ├── create_schema.sql
│   ├── create_indexes.sql
│   ├── create_functions.sql
│   ├── import_boundary.sql
│   └── verify.sql
│
├── backup/
│   ├── backup.sh
│   └── restore.sh
│
├── config/
│   └── countries.yml
│
├── docs/
│
└── examples/
```

---

# Requirements

## Operating System

Ubuntu Server 24.04 LTS

The framework has been developed and tested on Ubuntu 24.04 and assumes a clean installation.

---

## Hardware Recommendations

### Development

* 2 vCPU
* 4 GB RAM
* 50 GB SSD

### Production

* 4–8 vCPU
* 16 GB RAM
* NVMe SSD
* 100+ GB storage

---

# Software Requirements

The following software is required.

| Component             | Purpose                 |
| --------------------- | ----------------------- |
| PostgreSQL            | Database                |
| PostGIS               | Spatial queries         |
| osm2pgsql             | OSM importer            |
| osm2pgsql-replication | Incremental updates     |
| GDAL                  | Country boundary import |
| Redis                 | API cache               |
| Python 3              | Backend                 |
| FastAPI               | REST API                |
| Uvicorn               | ASGI server             |
| Nginx                 | Reverse proxy           |

---

# One-Time Server Setup

This section describes how to prepare a brand-new Ubuntu server.

The setup only needs to be completed once.

After it has been completed, importing additional countries becomes a single command.

---

## Step 1 — Update Ubuntu

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

---

## Step 2 — Install PostgreSQL

```bash
sudo apt install \
postgresql \
postgresql-contrib \
-y
```

Verify:

```bash
psql --version
```

---

## Step 3 — Install PostGIS

```bash
sudo apt install \
postgis \
postgresql-16-postgis-3 \
-y
```

Enable the extension:

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE osm;

\c osm

CREATE EXTENSION postgis;
```

Verify:

```sql
SELECT PostGIS_Version();
```

---

## Step 4 — Create Database User

```sql
CREATE USER speedlimit
WITH PASSWORD 'YOUR_PASSWORD';

ALTER DATABASE osm OWNER TO speedlimit;

GRANT ALL PRIVILEGES
ON DATABASE osm
TO speedlimit;
```

Exit PostgreSQL:

```sql
\q
```

---

## Step 5 — Install osm2pgsql

```bash
sudo apt install osm2pgsql -y
```

Verify:

```bash
osm2pgsql --version
```

---

## Step 6 — Install osm2pgsql-replication

```bash
sudo apt install python3-pip -y

pip install osm2pgsql-replication
```

Verify:

```bash
osm2pgsql-replication --help
```

---

## Step 7 — Install GDAL

```bash
sudo apt install gdal-bin -y
```

Verify:

```bash
ogr2ogr --version
```

---

## Step 8 — Install Redis

```bash
sudo apt install redis-server -y
```

Enable Redis:

```bash
sudo systemctl enable redis-server

sudo systemctl start redis-server
```

Verify:

```bash
redis-cli ping
```

Expected output:

```
PONG
```

---

## Step 9 — Install Python

```bash
sudo apt install \
python3 \
python3-venv \
python3-pip \
-y
```

Create the virtual environment:

```bash
python3 -m venv /opt/speedlimit/venv
```

Activate it:

```bash
source /opt/speedlimit/venv/bin/activate
```

Install required packages:

```bash
pip install \
fastapi \
uvicorn \
psycopg \
redis \
pyyaml
```

---

## Step 10 — Install Nginx

```bash
sudo apt install nginx -y
```

Enable:

```bash
sudo systemctl enable nginx

sudo systemctl start nginx
```

Verify:

```bash
systemctl status nginx
```

If the service is active, the server is ready for API deployment.

---

# Deploying the FastAPI Application

This section explains how to deploy the FastAPI application as a production service.

## Directory Layout

Create the following directory structure:

```text
/opt/speedlimit
│
├── api/
│   ├── main.py
│   ├── cache.py
│   ├── db.py
│   ├── models.py
│   ├── requirements.txt
│   └── ...
│
├── venv/
│
├── osm/
│
├── ssl/
│
├── backup-files/
│
└── framework/
```

---

## Install Python Dependencies

Activate the virtual environment.

```bash
source /opt/speedlimit/venv/bin/activate
```

Install dependencies.

```bash
pip install \
fastapi \
uvicorn \
redis \
psycopg[binary] \
pyyaml \
pydantic
```

Freeze dependencies.

```bash
pip freeze > requirements.txt
```

---

## Verify the API

Start FastAPI manually.

```bash
cd /opt/speedlimit/api

uvicorn main:app --host 0.0.0.0 --port 8000
```

Open:

```
http://SERVER_IP:8000/docs
```

Swagger UI should appear.

Press **Ctrl+C** once verified.

---

# Configure systemd

Running FastAPI manually is only useful for development.

In production, the API should run as a systemd service.

Create:

```
/etc/systemd/system/speedlimit.service
```

```ini
[Unit]
Description=SpeedLimit API
After=network.target postgresql.service redis-server.service

[Service]

User=ubuntu
Group=ubuntu

WorkingDirectory=/opt/speedlimit/api

Environment="PATH=/opt/speedlimit/venv/bin"

ExecStart=/opt/speedlimit/venv/bin/uvicorn \
main:app \
--host 127.0.0.1 \
--port 8000

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Reload systemd.

```bash
sudo systemctl daemon-reload
```

Enable the service.

```bash
sudo systemctl enable speedlimit
```

Start it.

```bash
sudo systemctl start speedlimit
```

Verify.

```bash
sudo systemctl status speedlimit
```

View logs.

```bash
journalctl -u speedlimit -f
```

---

# Configure Nginx

Install Nginx if not already installed.

```bash
sudo apt install nginx
```

Create:

```
/etc/nginx/sites-available/speedlimit
```

Example configuration:

```nginx
server {

    listen 80;

    server_name _;

    location / {

        proxy_pass http://127.0.0.1:8000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header X-Real-IP $remote_addr;

    }

}
```

Enable it.

```bash
sudo ln -s \
/etc/nginx/sites-available/speedlimit \
/etc/nginx/sites-enabled/
```

Test.

```bash
sudo nginx -t
```

Reload.

```bash
sudo systemctl reload nginx
```

Verify.

```
http://SERVER_IP/docs
```

---

# HTTPS

If you own a domain, install a Let's Encrypt certificate.

If you only access the API through a public IP, use a self-signed certificate or place the server behind a reverse proxy or load balancer that provides TLS termination.

---

# Importing the First Country

Country imports are handled by the framework.

Example:

```bash
./scripts/import-country.sh germany
```

The import process automatically:

* Downloads the latest PBF file
* Creates the database schema
* Imports OSM data
* Imports country boundaries
* Creates indexes
* Initializes replication
* Registers the country
* Verifies the import

Import duration depends on country size.

Approximate import times:

| Country    | Time      |
| ---------- | --------- |
| Luxembourg | <10 min   |
| Algeria    | 30–60 min |
| Germany    | 3–5 hours |

---

# Verifying the Import

List schemas.

```sql
\dn
```

Example.

```text
public
countries
germany
germany_replication
```

Verify road count.

```sql
SELECT COUNT(*)
FROM germany.roads;
```

Verify indexes.

```sql
SELECT indexname
FROM pg_indexes
WHERE schemaname='germany';
```

---

# Automatic Replication

Each imported country has its own replication metadata schema.

Initialize replication.

```bash
osm2pgsql-replication init \
--database osm \
--schema germany \
--middle-schema germany_replication \
--osm-file germany-latest.osm.pbf
```

Update later.

```bash
./scripts/update-country.sh germany
```

Update every imported country.

```bash
./scripts/update-all.sh
```

Weekly cron example.

```cron
0 3 * * 0 /opt/speedlimit/framework/scripts/update-all.sh
```

This executes every Sunday at 03:00.

---

# API

## Endpoint

```
GET /speedlimit
```

Parameters

| Name | Type   |
| ---- | ------ |
| lat  | double |
| lon  | double |

Example.

```
GET /speedlimit?lat=36.7525&lon=3.0420
```

Example response.

```json
{
    "road":"Autoroute Est-Ouest",
    "highway":"motorway",
    "speed_limit":"120",
    "oneway":true,
    "bridge":false,
    "tunnel":false,
    "distance":7.3
}
```

---

# Country Detection

Clients only provide latitude and longitude.

The API automatically:

1. Finds the containing country polygon.
2. Selects the matching schema.
3. Searches the nearest road.
4. Returns road attributes.

No country parameter is required.

---

# Redis Cache

Redis is used to cache identical requests.

Cache key:

```
speed:<lat>:<lon>
```

Typical TTL:

```
60 seconds
```

Benefits:

* Lower PostgreSQL load
* Faster repeated requests
* Better scalability

---

# Backup

Create a compressed database backup.

```bash
./backup/backup.sh
```

Backups are stored under:

```
/opt/speedlimit/backup-files
```

Automate using cron if desired.

---

# Restore

Restore a backup.

```bash
./backup/restore.sh osm_20260707.dump.gz
```

The restore process:

* Stops FastAPI
* Restores PostgreSQL
* Recreates SQL functions
* Starts FastAPI

---

# Health Check

Run.

```bash
./scripts/health-check.sh
```

The script verifies:

* PostgreSQL
* PostGIS
* Redis
* FastAPI
* Nginx
* Imported countries
* Replication status
* Disk usage
* Memory usage

---

# Removing a Country

Example.

```bash
./scripts/remove-country.sh germany
```

The script:

* Creates a backup
* Removes the schema
* Removes replication metadata
* Deletes downloaded files
* Updates the countries table

---

# Migrating to Another Server

Migration is straightforward.

1. Install Ubuntu.
2. Complete the one-time server setup.
3. Clone the framework repository.
4. Install the API.
5. Restore the latest PostgreSQL backup.
6. Copy SSL certificates (if applicable).
7. Start FastAPI.
8. Verify using the health check.

This process avoids re-importing OSM data and is significantly faster than rebuilding the database from scratch.

---

# Troubleshooting

## PostgreSQL connection refused

Verify PostgreSQL is running.

```bash
sudo systemctl status postgresql
```

---

## Redis unavailable

```bash
redis-cli ping
```

Expected output:

```
PONG
```

---

## FastAPI does not start

Inspect logs.

```bash
journalctl -u speedlimit -f
```

---

## Nginx configuration error

Validate configuration.

```bash
sudo nginx -t
```

---

## Country not detected

Verify the country boundary exists.

```sql
SELECT name
FROM countries;
```

---

## No road found

Possible causes:

* GPS coordinate outside imported country
* Search radius too small
* OSM data missing
* Road excluded by the import style

---

## Replication fails

Check status.

```bash
osm2pgsql-replication status \
-d osm \
--schema germany \
--middle-schema germany_replication
```

If necessary, reinitialize replication for that country.

---

# Performance Tips

* Allocate sufficient RAM for PostgreSQL.
* Store the database on SSD or NVMe storage.
* Increase Redis memory for larger deployments.
* Use `VACUUM ANALYZE` after large updates.
* Create backups before applying replication updates.
* Monitor disk space regularly.

---