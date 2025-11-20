# app/core/config.py
import os
from typing import Optional

class Settings:
    # Database
    MONGODB_URI: str = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    MONGODB_DB: str = os.getenv("MONGODB_DB", "artisan_platform")
    
    # JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    
    # App
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"

    # Email SMTP
    SMTP_SERVER: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = "ayaabbay17@gmail.com"
    SMTP_PASSWORD: str = "srtzxqckwabefvzs"

    # Cloudinary
    CLOUDINARY_CLOUD_NAME: str = "dlfujtrvi"
    CLOUDINARY_API_KEY: str = "652433646737159"
    CLOUDINARY_API_SECRET: str = "ut9e7TyqRr7bx-GuOmHukqquv8Y"

settings = Settings()