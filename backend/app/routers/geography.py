from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.locations import (
    CityResponse,
    DistrictResponse,
    NeighborhoodResponse,
)
from app.services.geography_service import (
    get_cities,
    get_districts,
    get_neighborhoods,
    get_neighborhood,
)

router = APIRouter(
    prefix="/geography",
    tags=["geography"],
)

@router.get("/cities", response_model=list[CityResponse])
def cities(db: Session = Depends(get_db)):
    return get_cities(db)

@router.get("/cities/{city_id}/districts", response_model=list[DistrictResponse])
def districts(city_id: int, db: Session = Depends(get_db)):
    return get_districts(city_id, db)

@router.get("/districts/{district_id}/neighborhoods", response_model=list[NeighborhoodResponse])
def neighborhoods(district_id: int, db: Session = Depends(get_db)):
    return get_neighborhoods(district_id, db)

@router.get("/neighborhoods/{neighborhood_id}", response_model=NeighborhoodResponse)
def neighborhood(neighborhood_id: int, db: Session = Depends(get_db)):
    return get_neighborhood(neighborhood_id, db)
