from fastapi import FastAPI
from app.database.database import create_database, Base, engine
from app.routers import auth, properties, searches, results, users, geography, summary

app = FastAPI()

create_database()

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(properties.router)
app.include_router(searches.router)
app.include_router(results.router)
app.include_router(geography.router)
app.include_router(summary.router)