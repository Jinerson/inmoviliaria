from app.models.models import Property, Search, Neighborhood, District, City, Result

weights = {
    "type": 0.2,
    "intention": 0.2,
    "area_range": 0.1,
    "rooms": 0.1,
    "bathrooms": 0.1,
    "parking": 0.1,
    "price": 0.1,
    "location": 0.1
}

def calc_price_score(search: Search, property: Property, min_score: float = 0.05) -> float:
    if search.min_price is not None and search.max_price is not None:
        ratio = abs(property.price - search.min_price) / (search.max_price - search.min_price)
        return weights["price"] - (ratio * min_score)
    elif search.min_price and search.max_price is None:
        if property.price >= search.min_price:
            return 0.0
        else:
            return weights["price"]
    else:
        return 0.0

def calc_area_score(search: Search, property: Property, min_score: float = 0.05) -> float:
    if search.min_area is not None and search.max_area is not None:
        ratio = abs(property.area - search.max_area) / (search.max_area - search.min_area)
        return weights["area_range"] - (ratio * min_score)
    elif search.min_area and search.max_area is None:
        if property.area >= search.min_area:
            return weights["area_range"]
        else:
            return 0.0
    else:
        return 0.0

def calc_rooms_score(search: Search, property: Property):
    if search.min_rooms <= property.rooms:
        return 0.1
    elif search.min_rooms - 1 == property.rooms:
        return 0.07
    elif search.min_rooms - 2 == property.rooms:
        return 0.05
    else:
        return 0.0

def calc_bathrooms_score(search: Search, property: Property):
    if search.min_bathrooms <= property.bathrooms:
        return 0.1
    elif search.min_bathrooms - 1 == property.bathrooms:
        return 0.07
    elif search.min_bathrooms - 2 == property.bathrooms:
        return 0.05
    else:
        return 0.0

def calc_parking_score(search: Search, property: Property):
    if search.min_parking <= property.parking_spots:
        return 0.1
    elif search.min_parking - 1 == property.parking_spots:
        return 0.07
    elif search.min_parking - 2 == property.parking_spots:
        return 0.05
    else:
        return 0.0

def calc_location_score(search: Search):
    if search.city is not None and search.district is not None and search.neighborhood is not None:
        return 0.1
    elif search.city is not None and search.district:
        return 0.07
    else:
        return 0.05

def calculate_match_score(search: Search, property: Property) -> float:
    score = 0.0

    if search.type == property.type:
        score += weights["type"]
    if search.intention == property.intention:
        score += weights["intention"]
    score += calc_area_score(search, property)
    score += calc_price_score(search, property)
    score += calc_rooms_score(search, property)
    score += calc_bathrooms_score(search, property)
    score += calc_parking_score(search, property)
    score += calc_location_score(search)

    return round(score * 100, 2)
