import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import DATABASE_URL

#SQLALCHEMY_DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"

print("DATABASE_URL =", os.getenv("DATABASE_URL"))
print("DATABASE_URL =", DATABASE_URL)
engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit = False, autoflush = False, bind = engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_database():
    Base.metadata.create_all(bind = engine)

def reset_database():
    Base.metadata.drop_all(bind = engine)
    Base.metadata.create_all(bind = engine)

from urllib.parse import urlparse
