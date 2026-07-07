import json
import redis

redis_client = redis.Redis(
    host="localhost",
    port=6379,
    db=0,
    decode_responses=True,
)

CACHE_TTL = 60


def get(key):
    value = redis_client.get(key)

    if value is None:
        return None

    result = json.loads(value)
    result["source"] = "cache"
    return result


def set(key, value):
    redis_client.setex(
        key,
        CACHE_TTL,
        json.dumps(value),
    )
