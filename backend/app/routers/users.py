from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.models import User
from app.schemas.user import UserCreate, UserResponse, UserUpdate, ChangePasswordRequest
from app.schemas.notification import NotificationPreferencesBase
from app.core.security import hash_password, get_current_user, verify_password

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/", response_model=list[UserResponse])
def list_users(db: Session = Depends(get_db)):
    return db.query(User).all()

@router.post("/register", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    hashed_pwd = hash_password(user.password)
    db_user = User(
        first_name=user.first_name,
        middle_name=user.middle_name,
        last_name=user.last_name,
        second_last_name=user.second_last_name,
        email=user.email,
        phone=user.phone,
        hashed_password=hashed_pwd
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/profile", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/profile/change-password")
def change_password(request: ChangePasswordRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not verify_password(request.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")

    user = db.query(User).filter(User.id == current_user.id).first()
    user.hashed_password = hash_password(request.new_password)
    db.commit()
    return {"msg": "Password updated successfully"}

@router.put("/profile/update", response_model=UserResponse)
def update_user(user: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_user = db.query(User).filter(User.id == current_user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    for key, value in user.model_dump(exclude_unset=True).items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user

@router.delete("/profile")
def delete_user(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_user = db.query(User).filter(User.id == current_user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(db_user)
    db.commit()
    return {"message": f"User with id {current_user.id} deleted"}

@router.patch("/me/notifications")
def update_notifications(data: NotificationPreferencesBase, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    current_user.notification_app = data.notification_app
    current_user.notification_email = data.notification_email
    current_user.notification_whatsapp = data.notification_whatsapp

    db.commit()

    return {"message": "Preferences updated"}