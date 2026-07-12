
from app.models.models import City, District, Neighborhood
from app.data.Bogota import BOGOTA
from app.database.database import get_db
from app.utils.decode import normalize_text

def create_locations(db):
    city = City(name="Bogota")
    db.add(city)
    db.commit()
    db.refresh(city)

    for district_name, neighborhoods in BOGOTA.items():
        district = District(
            name=normalize_text(district_name),
            city_id=city.id
        )
        db.add(district)
        db.commit()
        db.refresh(district)

        for neighborhood_data in neighborhoods:
            neighborhood = Neighborhood(
                name=normalize_text(neighborhood_data["name"]),
                min_stratum=neighborhood_data["min_stratum"],
                max_stratum=neighborhood_data["max_stratum"],
                price_per_m2=neighborhood_data["price_per_m2"],
                district_id=district.id
            )
            db.add(neighborhood)

    db.commit()

    print("\u2705 City created")
    print(f"\u2705 {len(BOGOTA)} districts")
    print(f"\u2705 {sum(len(x) for x in BOGOTA.values())} neighborhoods")

def populate_locations():
    db = next(get_db())
    create_locations(db)