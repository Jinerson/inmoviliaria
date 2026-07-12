from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.summary import SummaryBase
from app.core.security import get_current_user
from app.models.models import Property, Result, Search, User

router = APIRouter(
    prefix="/summary",
    tags=["summary"]
)

@router.get("/", response_model=SummaryBase)
def get_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    active_properties = db.query(Property).filter(Property.owner_id == current_user.id).count()
    active_searches = db.query(Search).filter(Search.user_id == current_user.id, Search.is_active == True).count()
    active_results = db.query(Result).join(Search).filter(Search.user_id == current_user.id, Search.is_active == True).count()
    new_matches = db.query(Result).join(Search).filter(Search.user_id == current_user.id, Search.is_active == True, Result.notified == False).count()

    return {
        "active_properties": active_properties,
        "active_searches": active_searches,
        "active_results": active_results,
        "new_matches": new_matches
    }
