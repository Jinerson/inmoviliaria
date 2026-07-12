from pydantic import BaseModel

class CityResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class DistrictResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class NeighborhoodResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True

class LocationBase(BaseModel):
    city: CityResponse
    district: DistrictResponse
    neighborhood: NeighborhoodResponse

    class Config:
        from_attributes = True