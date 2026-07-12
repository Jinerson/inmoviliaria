from enum import Enum

class PropertyType(str, Enum):
    apartment = "apartment"
    house = "house"
    office = "office"
    commercial = "commercial"

class Intention(str, Enum):
    sale = "sale"
    rent = "rent"

class Stratum(int, Enum):
    one = 1
    two = 2
    three = 3
    four = 4
    five = 5
    six = 6
