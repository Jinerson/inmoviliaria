import random
from app.database.database import get_db
from app.models.models import Property, User, Neighborhood
from app.generators.data_generator import DataGenerator

NUM_PROPERTIES = 500

def populate_properties():
    db = next(get_db())
    generator = DataGenerator()

    users = db.query(User).all()
    neighborhoods = db.query(Neighborhood).all()

    properties = []

    for _ in range(NUM_PROPERTIES):
        owner = random.choice(users)
        neighborhood = random.choice(neighborhoods)
        prop_type = generator.random_property_type()
        description = generator.random_description()
        adress = generator.random_address()
        intention = generator.random_intention()
        stratum = generator.random_stratum(neighborhood)
        area = generator.random_area(prop_type)
        rooms = generator.random_rooms(prop_type, area)
        bathrooms = generator.random_bathrooms(prop_type, rooms)
        parking = generator.random_parking(prop_type)
        price = generator.random_price(neighborhood, area, intention)

        prop = Property(
            owner=owner,
            neighborhood=neighborhood,
            type=prop_type,
            intention=intention,
            stratum=stratum,
            address=adress,
            description=description,
            rooms=rooms,
            bathrooms=bathrooms,
            parking_spots=parking,
            price=price,
            area=area
        )

        properties.append(prop)

    db.add_all(properties)
    db.commit()

    print(f"\u2705 {len(properties)} properties created")