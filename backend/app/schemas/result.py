from pydantic import BaseModel
from app.schemas.property import PropertyDetailsResponse
from datetime import datetime


class ResultBase(BaseModel):
    match_percentage: float
    matched_at: datetime
    notified: bool
    notified_at: datetime | None = None


class ResultResponse(ResultBase):
    id: int
    search_id: int
    property_id: int
    property: PropertyDetailsResponse

    class Config:
        from_attributes = True
