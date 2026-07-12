from app.core import cloudinary_config
from app.core.config import CLOUDINARY_FOLDER
from cloudinary.uploader import upload

result = upload("C:\\Users\\Jiner\\Documents\\Proyectos\\Raices\\backend\\img.png", folder=CLOUDINARY_FOLDER)
print(result["secure_url"])


