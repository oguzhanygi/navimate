from pydantic import BaseModel

class goalInput(BaseModel):
    x: float
    y: float

class status(BaseModel):
    status: str

class positionOutput(BaseModel):
    x: float
    y: float