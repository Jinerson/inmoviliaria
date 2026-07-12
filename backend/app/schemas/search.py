from pydantic import BaseModel
from typing import Optional
from app.core.enums import PropertyType, Intention

class SearchBase(BaseModel):
    type: PropertyType
    intention: Intention
    min_area: Optional[float] = None
    max_area: Optional[float] = None
    min_rooms: Optional[int] = None
    min_bathrooms: Optional[int] = None
    min_parking: Optional[int] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    city_id: Optional[int] = None
    district_id: Optional[int] = None
    neighborhood_id: Optional[int] = None

class SearchCreate(SearchBase):
    pass

class SearchResponse(SearchBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
