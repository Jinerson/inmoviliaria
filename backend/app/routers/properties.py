from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.models import Property
from app.schemas.property import PropertyCreate, PropertyResponse, PropertyDetailsResponse
from app.models.models import User, PropertyPhoto
from app.core.security import get_current_user
from app.services.matching_engine import find_searches, save_matches_from_property
from app.services.cloudinary_service import upload_photo

router = APIRouter(prefix="/properties", tags=["properties"])

@router.post("/new", response_model=PropertyDetailsResponse)
def create_property(property_data: PropertyCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    db_property = Property(**property_data.model_dump())
    db_property.owner_id = user.id
    db.add(db_property)
    db.commit()
    db.refresh(db_property)

    searches = find_searches(db_property, db)
    save_matches_from_property(db_property, searches, db)
    return db_property

@router.get("/", response_model=list[PropertyDetailsResponse])
def list_properties(db: Session = Depends(get_db)):
    return db.query(Property).all()

@router.get("/my-properties", response_model=list[PropertyDetailsResponse])
def list_my_properties(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Property).filter(Property.owner_id == current_user.id).all()

@router.get("/{property_id}", response_model=PropertyDetailsResponse)
def get_property(property_id: int, db: Session = Depends(get_db)):
    db_property = db.query(Property).filter(Property.id == property_id).first()
    if not db_property:
        raise HTTPException(status_code=404, detail="Property not found")
    return db_property


@router.put("/{property_id}", response_model=PropertyDetailsResponse)
def update_property(property_id: int, property_data: PropertyCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_property = db.query(Property).filter(Property.id == property_id, current_user.id == Property.owner_id).first()

    if not db_property:
        raise HTTPException(status_code=404, detail="Property not found")

    for key, value in property_data.model_dump().items():
        setattr(db_property, key, value)
    db.commit()
    db.refresh(db_property)

    searches = find_searches(db_property, db)
    save_matches_from_property(db_property, searches, db)
    return db_property

@router.delete("/{property_id}")
def delete_property(property_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_property = db.query(Property).filter(Property.id == property_id, Property.owner_id == current_user.id).first()
    if not db_property:
        raise HTTPException(status_code=404, detail="Property not found")
    db.delete(db_property)
    db.commit()
    return {"message": "Property deleted"}

@router.post("/{property_id}/upload-photos")
async def upload_photos(property_id: int,  photo: UploadFile = File(...), db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):

    db_property = (
        db.query(Property)
        .filter(
            Property.id == property_id,
            Property.owner_id == current_user.id
        )
        .first()
    )
    print(f"db_property: {db_property}")
    if not db_property:
        raise HTTPException(
            status_code=404,
            detail="Property not found"
        )

    existing_photos_count = (
        db.query(PropertyPhoto)
        .filter(PropertyPhoto.property_id == property_id)
        .count()
    )

    result = upload_photo(photo)
    property_photo = PropertyPhoto(
        property_id=property_id,
        url=result,
        is_primary=(existing_photos_count == 0),
    )

    db.add(property_photo)

    db.commit()

    return {
        "message": "1 photo uploaded successfully"
    }
