from fastapi import FastAPI, APIRouter
import logging

from api.cache import redis_client, get, set
from api.db import pool
from api.models import SpeedLimitResponse
from api.queries import GET_SPEED_LIMIT

app = FastAPI(title="SpeedLimit API")
#app = FastAPI(title="SpeedLimit API", root_path="/api")
api_router = APIRouter(prefix="/api/speedlimit")


@api_router.get("/health")
def health():
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")

    return {"status": "ok"}


@api_router.get(
    "/get",
    response_model=SpeedLimitResponse,
)
def speedlimit(lat: float, lon: float):

    lat = round(lat, 5)
    lon = round(lon, 5)

    key = f"speed:{lat}:{lon}"

    logging.info(key)

    try:
        cached = get(key)
        if cached:
            return cached
    except Exception:
        pass

    with pool.connection() as conn:
        with conn.cursor() as cur:

            cur.execute(
                GET_SPEED_LIMIT,
                (
                    lon,
                    lat,
                ),
            )

            row = cur.fetchone()

            logging.warning(row)

    if row is None:

        result = {
            "error": "road not found",
            "source": "db",
        }

        try:
            set(key, result)
        except Exception:
            pass

        return result

    result = {
        "road": row[0],
        "highway": row[1],
        "speed_limit": row[2],
        "speed_limit_forward": row[3],
        "speed_limit_backward": row[4],
        "speed_limit_type": row[5],
        "oneway": row[6],
        "bridge": row[7],
        "tunnel": row[8],
        "layer": row[9],
        "distance": round(row[10], 2),
        "source": "db",
    }

    try:
        set(key, result)
    except Exception:
        pass

    return result


@api_router.get("/cache/stats")
def cache_stats():

    info = redis_client.info()

    return {
        "keys": redis_client.dbsize(),
        "memory": info["used_memory_human"],
        "hits": info["keyspace_hits"],
        "misses": info["keyspace_misses"],
    }


@api_router.get("/cache/status")
def cache_status():
    try:
        redis_client.ping()
        return {
            "status": "ok"
        }
    except Exception as e:
        return {
            "status": "down",
            "error": str(e),
        }


app.include_router(api_router)
