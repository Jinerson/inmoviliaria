from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.models import Search, User
from app.schemas.search import SearchCreate, SearchResponse
from app.core.security import get_current_user
from app.services.matching_engine import find_matches, save_matches

router = APIRouter(
    prefix="/searches",
    tags=["searches"]
)

@router.post("/new", response_model=SearchResponse)
def create_search(search: SearchCreate, db: Session = Depends(get_db), user = Depends(get_current_user)):
    new_search = Search(**search.model_dump())
    new_search.user_id = user.id
    db.add(new_search)
    db.commit()
    db.refresh(new_search)

    results = find_matches(new_search, db)
    save_matches(new_search, results, db)
    return new_search

@router.get("/", response_model=list[SearchResponse])
def get_searches(db: Session = Depends(get_db)):
    return db.query(Search).all()

@router.get("/my-searches", response_model=list[SearchResponse])
def get_my_searches(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Search).filter(Search.user_id == current_user.id).all()

@router.get("/{search_id}", response_model=SearchResponse)
def get_search(search_id: int, db: Session = Depends(get_db)):
    search = db.query(Search).filter(Search.id == search_id).first()
    if not search:
        raise HTTPException(status_code=404, detail="Search not found")
    return search

@router.put("/{search_id}", response_model=SearchResponse)
def update_search(search_id: int, search_update: SearchCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
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

    for key, value in search_update.model_dump().items():
        setattr(search, key, value)

    db.commit()
    db.refresh(search)

    matches = find_matches(search, db)
    save_matches(search, matches, db)
    return search

@router.delete("/{search_id}")
def delete_search(search_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    search = db.query(Search).filter(Search.id == search_id, Search.user_id == current_user.id).first()
    if not search:
        raise HTTPException(status_code=404, detail="Search not found")

    db.delete(search)
    db.commit()

    return {"message": "Search deleted successfully"}
