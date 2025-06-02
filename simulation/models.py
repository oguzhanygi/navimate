from pydantic import BaseModel
from typing import Optional

class goalInput(BaseModel):
    x: float
    y: float

class status(BaseModel):
    status: str

class positionOutput(BaseModel):
    x: float
    y: float

class MappingStatus(BaseModel):
    status: str

class SaveMapRequest(BaseModel):
    map_name: Optional[str] = "my_map"

class ChangeMapRequest(BaseModel):
    map_name: str
