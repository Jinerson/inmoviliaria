from pydantic import BaseModel

class NotificationPreferencesBase(BaseModel):
    notification_app: bool
    notification_email: bool
    notification_whatsapp: bool
    
    class Config:
        from_attributes = True