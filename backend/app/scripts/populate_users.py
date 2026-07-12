import random
from app.database.database import get_db
from app.models.models import User
from app.core.security import hash_password
from app.generators.data_generator import DataGenerator
from app.utils.decode import normalize_text

NUM_USERS = 20


def create_users(db, generator):
    users = []

    for _ in range(NUM_USERS):
        first_name = generator.random_name()
        middle_name = generator.random_name() if random.random() < 0.4 else None
        last_name = generator.random_lastname()
        second_last_name = generator.random_lastname() if random.random() < 0.4 else None
        email = generator.random_email(first_name, last_name)
        phone = generator.random_phone()

        user = User(
            first_name=normalize_text(first_name),
            middle_name=normalize_text(middle_name) if middle_name else None,
            last_name=normalize_text(last_name),
            second_last_name=normalize_text(second_last_name) if second_last_name else None,
            email=normalize_text(email),
            phone=phone,
            hashed_password=hash_password("12345")
        )

        users.append(user)

    db.add_all(users)
    db.commit()

    print(f"\u2705 {len(users)} users created")

    return users


def populate_users():
    db = next(get_db())
    generator = DataGenerator()

    try:
        create_users(db, generator)
    finally:
        db.close()

