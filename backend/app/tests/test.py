import time
from app.database.database import create_database, reset_database, get_db
from app.scripts.populate_users import populate_users
from app.scripts.populate_locations import populate_locations
from app.scripts.populate_properties import populate_properties
from app.models.models import Search
from app.services.matching_engine import find_matches, save_matches

def set_and_populate_db():
    reset_database()
    """time.sleep(1)
    populate_users()
    time.sleep(1)
    populate_locations()
    time.sleep(1)
    populate_properties()"""

set_and_populate_db()