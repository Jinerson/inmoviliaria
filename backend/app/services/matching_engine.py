from sqlalchemy.orm import Session
from app.models.models import Property, Search, Neighborhood, District, City, Result
from app.services.scoring_service import calculate_match_score

def find_matches(search: Search, db: Session):
    query = db.query(Property)

    query = query.filter(Property.type == search.type)
    query = query.filter(Property.intention == search.intention)

    if search.min_area is not None:
        query = query.filter(Property.area >= search.min_area)

    if search.max_area is not None:
        query = query.filter(Property.area <= search.max_area)

    if search.min_rooms is not None:
        query = query.filter(Property.rooms >= search.min_rooms)

    if search.min_bathrooms is not None:
        query = query.filter(Property.bathrooms >= search.min_bathrooms)

    if search.min_parking is not None:
        query = query.filter(Property.parking_spots >= search.min_parking)

    if search.min_price is not None:
        query = query.filter(Property.price >= search.min_price)

    if search.max_price is not None:
        query = query.filter(Property.price <= search.max_price)

    if search.neighborhood_id is not None:
        query = query.filter(Property.neighborhood_id == search.neighborhood_id)
    elif search.district_id is not None:
        query = (
            query
            .join(Property.neighborhood)
            .join(Neighborhood.district)
            .filter(District.id == search.district_id)
        )
    elif search.city_id is not None:
        query = (
            query
            .join(Property.neighborhood)
            .join(Neighborhood.district)
            .join(District.city)
            .filter(City.id == search.city_id)
        )

    return query.distinct().all()


def find_searches(property: Property, db: Session):
    query = db.query(Search)

    query = query.filter(Search.type == property.type)
    query = query.filter(Search.intention == property.intention)

    query = query.filter(Search.min_area <= property.area)

    if property.area is not None:
        query = query.filter(
            (Search.max_area == None) |
            (Search.max_area >= property.area)
        )

    query = query.filter(Search.min_rooms <= property.rooms)
    query = query.filter(Search.min_bathrooms <= property.bathrooms)
    query = query.filter(Search.min_parking <= property.parking_spots)
    query = query.filter(Search.min_price <= property.price)
    query = query.filter(Search.max_price >= property.price)

    query = query.filter(
        (Search.neighborhood_id == None) |
        (Search.neighborhood_id == property.neighborhood_id)
    )

    query = query.join(Neighborhood)

    query = query.filter(
        (Search.district_id == None) |
        (Search.district_id == Neighborhood.district_id)
    )

    query = query.join(District)

    query = query.filter(
        (Search.city_id == None) |
        (Search.city_id == District.city_id)
    )

    return query.distinct().all()


def save_matches(search: Search, properties: list[Property], db: Session):
    db.query(Result).filter(Result.search_id == search.id).delete()

    for prop in properties:
        score = calculate_match_score(search, prop)
        result = Result(
            search_id=search.id,
            property_id=prop.id,
            match_percentage=score
        )
        db.add(result)

    db.commit()
    return True


def save_matches_from_property(property: Property, searches: list[Search], db: Session):
    db.query(Result).filter(Result.property_id == property.id).delete()

    for search in searches:
        score = calculate_match_score(search, property)
        result = Result(
            search_id=search.id,
            property_id=property.id,
            match_percentage=score
        )
        db.add(result)

    db.commit()