import os

from dotenv import load_dotenv
from psycopg_pool import ConnectionPool

load_dotenv("/opt/speedlimit/config/.env")

pool = ConnectionPool(
    conninfo=(
        f"host={os.getenv('DB_HOST')} "
        f"port={os.getenv('DB_PORT')} "
        f"dbname={os.getenv('DB_NAME')} "
        f"user={os.getenv('DB_USER')} "
        f"password={os.getenv('DB_PASSWORD')}"
    ),
    min_size=2,
    max_size=10,
)
