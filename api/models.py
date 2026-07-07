from pydantic import BaseModel
from typing import Optional


class SpeedLimitResponse(BaseModel):
    road: Optional[str] = None
    highway: Optional[str] = None

    speed_limit: Optional[str] = None
    speed_limit_forward: Optional[str] = None
    speed_limit_backward: Optional[str] = None
    speed_limit_type: Optional[str] = None

    oneway: Optional[bool] = None

    bridge: Optional[bool] = None
    tunnel: Optional[bool] = None
    layer: Optional[int] = None

    distance: Optional[float] = None

    source: str
