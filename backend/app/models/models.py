from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float, DateTime, Enum, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database.database import Base
from app.core.enums import PropertyType, Intention, Stratum

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, nullable=False)
    middle_name = Column(String, nullable=True, default="")
    last_name = Column(String, nullable=False)
    second_last_name = Column(String, nullable=True, default="")
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    notification_app = Column(Boolean, default=True, nullable=False)
    notification_email = Column(Boolean, default=False, nullable=False)
    notification_whatsapp = Column(Boolean, default=False, nullable=False)

    properties = relationship("Property", back_populates="owner", cascade="all, delete-orphan")
    searches = relationship("Search", back_populates="user", cascade="all, delete-orphan")

class Property(Base):
    __tablename__ = "properties"

    id = Column(Integer, primary_key = True, index = True)
    owner_id = Column(Integer, ForeignKey("users.id", ondelete = "CASCADE"), nullable = False)
    description = Column(Text, nullable = True)
    type = Column(Enum(PropertyType), nullable = False)
    intention = Column(Enum(Intention), nullable = False)
    stratum = Column(Enum(Stratum), nullable = True)
    neighborhood_id = Column(Integer, ForeignKey("neighborhoods.id"), nullable = False)
    address = Column(String, nullable = False)
    rooms = Column(Integer)
    bathrooms = Column(Integer)
    parking_spots = Column(Integer)
    price = Column(Float, nullable = False)
    area = Column(Float)
    published_at = Column(DateTime, default = datetime.utcnow)

    owner = relationship("User", back_populates = "properties")
    results = relationship("Result", back_populates = "property", cascade = "all, delete-orphan")
    neighborhood = relationship("Neighborhood", back_populates = "properties")
    photos = relationship("PropertyPhoto", back_populates = "property", cascade = "all, delete-orphan")

    @property
    def neighborhood_name(self):
        return self.neighborhood.name


    @property
    def district_name(self):
        return self.neighborhood.district.name


    @property
    def city_name(self):
        return self.neighborhood.district.city.name

class PropertyPhoto(Base):
    __tablename__ = "property_photos"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False)
    url = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False)

    property = relationship("Property", back_populates="photos")

class Search(Base):
    __tablename__ = "searches"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(Enum(PropertyType))
    intention = Column(Enum(Intention))
    min_area = Column(Float)
    max_area = Column(Float)
    min_rooms = Column(Integer)
    min_bathrooms = Column(Integer)
    min_parking = Column(Integer)
    city_id = Column(Integer, ForeignKey("cities.id"), nullable=True)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=True)
    neighborhood_id = Column(Integer, ForeignKey("neighborhoods.id"), nullable=True)
    min_price = Column(Float)
    max_price = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    user = relationship("User", back_populates="searches")
    city = relationship("City", back_populates="searches")
    district = relationship("District", back_populates="searches")
    neighborhood = relationship("Neighborhood", back_populates="searches")
    results = relationship("Result", back_populates="search", cascade="all, delete-orphan")

class Result(Base):
    __tablename__ = "results"

    id = Column(Integer, primary_key=True, index=True)
    search_id = Column(Integer, ForeignKey("searches.id", ondelete="CASCADE"), nullable=False)
    property_id = Column(Integer, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False)
    match_percentage = Column(Float, nullable=False)
    matched_at = Column(DateTime, default=datetime.utcnow)
    notified = Column(Boolean, default=False)
    notified_at = Column(DateTime, default=None)

    search = relationship("Search", back_populates="results")
    property = relationship("Property", back_populates="results")

class City(Base):
    __tablename__ = "cities"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)

    districts = relationship("District", back_populates="city")
    searches = relationship("Search", back_populates="city")

class District(Base):
    __tablename__ = "districts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id"), nullable=False, index=True)

    city = relationship("City", back_populates="districts")
    neighborhoods = relationship("Neighborhood", back_populates="district")
    searches = relationship("Search", back_populates="district")

class Neighborhood(Base):
    __tablename__ = "neighborhoods"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=False, index=True)
    min_stratum = Column(Integer)
    max_stratum = Column(Integer)
    price_per_m2 = Column(Float)

    district = relationship("District", back_populates="neighborhoods")
    properties = relationship("Property", back_populates="neighborhood")
    searches = relationship("Search", back_populates="neighborhood")