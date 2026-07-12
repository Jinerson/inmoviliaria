from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    first_name: str
    middle_name: str | None = None
    last_name: str
    second_last_name: str | None = None
    email: EmailStr
    phone: str

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    first_name: str | None = None
    middle_name: str | None = None
    last_name: str | None = None
    second_last_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None

class UserResponse(UserBase):
    id: int
    notification_app: bool
    notification_email: bool
    notification_whatsapp: bool
    class Config:
        from_attributes = True

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
