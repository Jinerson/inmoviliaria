from sqlalchemy.orm import Session
from app.models.models import City, District, Neighborhood

def get_cities(db: Session):
    return (
        db.query(City)
        .order_by(City.name)
        .all()
    )

def get_districts(city_id: int, db: Session):
    return (
        db.query(District)
        .filter(District.city_id == city_id)
        .order_by(District.name)
        .all()
    )

def get_neighborhoods(district_id: int, db: Session):
    return (
        db.query(Neighborhood)
        .filter(Neighborhood.district_id == district_id)
        .order_by(Neighborhood.name)
        .all()
    )

def get_neighborhood(neighborhood_id: int, db: Session):
    return (
        db.query(Neighborhood)
        .filter(Neighborhood.id == neighborhood_id)
        .first()
    )
