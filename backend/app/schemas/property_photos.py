from pydantic import BaseModel

class PropertyPhotoBase(BaseModel):
    id: int
    url: str
    is_primary: bool

    class Config:
        from_attributes = True
