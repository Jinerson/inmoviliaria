from faker import Faker
import random
from app.core.enums import PropertyType, Intention, Stratum

class DataGenerator:

    def __init__(self):
        self.fake = Faker("es_CO")
        random.seed(42)

    def random_name(self):
        return self.fake.first_name()

    def random_lastname(self):
        return self.fake.last_name()

    def random_email(self, name, lastname):
        domain = random.choice(["gmail.com", "hotmail.com", "outlook.com", "yahoo.com"])
        number = random.randint(1, 999)
        return f"{name.lower()}.{lastname.lower()}{number}@{domain}"

    def random_phone(self):
        prefix = ["311", "312", "313", "314", "315", "300", "301"]
        return (
            random.choice(prefix)
            + "".join(str(random.randint(0, 9)) for _ in range(7))
        )

    def random_property_type(self):
        return random.choices(
            population=[
                PropertyType.apartment,
                PropertyType.house,
                PropertyType.commercial,
                PropertyType.office
            ],
            weights=[55, 25, 10, 10]
        )[0]

    def random_description(self):
        return "Aqui va una descripcion del inmueble."
    
    def random_address(self):
        return "Direccion del inmueble."
    
    def random_intention(self):
        return random.choices(
            population=[Intention.sale, Intention.rent],
            weights=[70, 30]
        )[0]

    def random_area(self, type):
        if type == PropertyType.apartment:
            return random.randint(40, 105)
        elif type == PropertyType.house:
            return random.randint(80, 250)
        elif type == PropertyType.commercial:
            return random.randint(20, 120)
        elif type == PropertyType.office:
            return random.randint(30, 200)

    def random_rooms(self, type, area):
        if type == PropertyType.apartment:
            if area < 60:
                return random.randint(1, 2)
            elif area < 100:
                return random.randint(2, 3)
            return random.randint(3, 4)
        elif type == PropertyType.house:
            if area < 120:
                return random.randint(2, 3)
            elif area < 220:
                return random.randint(3, 5)
            return random.randint(4, 6)
        return 0

    def random_bathrooms(self, type, rooms):
        if type == PropertyType.commercial:
            return 1
        elif type == PropertyType.office:
            return 1
        elif type == PropertyType.apartment:
            if rooms == 1:
                return 1
            elif rooms == 2:
                return 1
            elif rooms == 3:
                return random.choice([1, 2])
            else:
                return random.choice([2, 3])
        elif type == PropertyType.house:
            if rooms <= 2:
                return random.randint(1, 2)
            elif rooms <= 4:
                return random.randint(2, 3)
            else:
                return 3

    def random_parking(self, type):
        if type == PropertyType.apartment:
            return random.choices([0, 1, 2], weights=[20, 65, 15])[0]
        elif type == PropertyType.house:
            return random.randint(1, 2)
        elif type == PropertyType.commercial:
            return random.choice([0, 1])
        elif type == PropertyType.office:
            return random.choice([0, 1])

    def random_stratum(self, neighborhood):
        return Stratum(
            random.randint(neighborhood.min_stratum, neighborhood.max_stratum)
        )

    def random_price(self, neighborhood, area, intention):
        price = area * neighborhood.price_per_m2
        price *= random.uniform(0.90, 1.10)

        if intention == Intention.sale:
            return round(price)

        price *= random.uniform(0.0065, 0.009)
        return round(price)
