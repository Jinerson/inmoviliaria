from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.models import User, Search, Result, Property
from app.schemas.result import ResultResponse
from app.core.security import get_current_user

router = APIRouter(prefix="/results", tags=["results"])

@router.get("/my-results", response_model=list[ResultResponse])
def get_my_results(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    results = (
        db.query(Result)
        .join(Property, Result.property_id == Property.id)
        .join(Search, Search.id == Result.search_id)
        .filter(Search.user_id == current_user.id)
        .distinct()
        .all()
    )
    return results

@router.get("/search/{search_id}", response_model=list[ResultResponse])
def get_results_by_search(
    search_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    search = (
        db.query(Search)
        .filter(
            Search.id == search_id,
            Search.user_id == current_user.id
        )
        .first()
    )

    if not search:
        raise HTTPException(status_code=404, detail="Search not found")

    results = (
        db.query(Result)
        .join(Property)
        .filter(Result.search_id == search.id)
        .all()
    )

    return results
