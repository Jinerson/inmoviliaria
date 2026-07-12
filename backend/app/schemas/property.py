from pydantic import BaseModel
from typing import List, Optional
from app.core.enums import PropertyType, Intention, Stratum
from app.schemas.property_photos import PropertyPhotoBase
from app.schemas.locations import LocationBase
from datetime import datetime

class OwnerResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    phone: str

    class Config:
        from_attributes = True

class PropertyBase(BaseModel):
    type: PropertyType
    description: Optional[str] = None
    intention: Intention
    stratum: Stratum
    neighborhood_id: int
    address: str
    rooms: int
    bathrooms: int
    parking_spots: Optional[int] = None
    price: float
    area: Optional[float] = None
    
class PropertyCreate(PropertyBase):
    pass

class PropertyResponse(PropertyBase):
    id: int
    owner_id: int
    published_at: datetime
    photos: List[PropertyPhotoBase] = []

    class Config:
        from_attributes = True

class PropertyDetailsResponse(PropertyBase):
    id: int
    owner: OwnerResponse
    neighborhood_name: str
    district_name: str
    city_name: str
    photos: List[PropertyPhotoBase] = []

    class Config:
        from_attributes = True

