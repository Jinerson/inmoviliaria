from app.core.config import CLOUDINARY_FOLDER
from cloudinary.uploader import upload

def upload_photo(photo, folder: str = CLOUDINARY_FOLDER):

    result = upload(
        photo.file,
        folder=folder
    )

    return result["secure_url"]