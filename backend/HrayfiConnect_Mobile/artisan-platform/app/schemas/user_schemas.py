from pydantic import BaseModel, EmailStr, validator, ConfigDict
from typing import Optional, List
from datetime import datetime

# Schémas de base
class UserBase(BaseModel):
    email: EmailStr
    phone: str
    language: str = "fr"
    profile_picture: Optional[str] = None

class UserCreate(UserBase):
    password: str
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Le mot de passe doit contenir au moins 8 caractères')
        return v

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    language: Optional[str] = None
    password: Optional[str] = None
    profile_picture: Optional[str] = None

class UserInDB(UserBase):
    id: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# Schémas Client
class ClientBase(BaseModel):
    first_name: str
    last_name: str
    address: Optional[str] = None

class ClientCreate(ClientBase, UserCreate):
    pass

class ClientUpdate(ClientBase, UserUpdate):
    pass

class ClientResponse(ClientBase, UserInDB):
    pass

# Schémas Artisan
class Availability(BaseModel):
    monday: List[str] = []
    tuesday: List[str] = []
    wednesday: List[str] = []
    thursday: List[str] = []
    friday: List[str] = []
    saturday: List[str] = []
    sunday: List[str] = []

class IdentityDocument(BaseModel):
    cin_recto: Optional[str] = None  # Photo recto CIN
    cin_verso: Optional[str] = None  # Photo verso CIN
    photo: Optional[str] = None      # Photo d'identité (hecto)

class ArtisanBase(BaseModel):
    first_name: str
    last_name: str
    company_name: Optional[str] = None
    trade: str
    description: Optional[str] = None
    years_of_experience: Optional[int] = None
    address: Optional[str] = None  # NOUVEAU: Adresse de l'artisan
    identity_document: Optional[IdentityDocument] = None  # MODIFIÉ: Structure pour documents
    certifications: List[str] = []
    portfolio: List[str] = []

class ArtisanCreate(ArtisanBase, UserCreate):
    pass

class ArtisanUpdate(ArtisanBase, UserUpdate):
    availability: Optional[Availability] = None

class ArtisanResponse(ArtisanBase, UserInDB):
    is_verified: bool = False
    availability: Optional[Availability] = None
    average_rating: Optional[float] = None
    total_reviews: Optional[int] = None

# Schémas Admin
class AdminBase(BaseModel):
    first_name: str
    last_name: str
    role: str
    permissions: List[str] = []

class AdminCreate(AdminBase, UserCreate):
    pass

class AdminUpdate(AdminBase, UserUpdate):
    pass

class AdminResponse(AdminBase, UserInDB):
    pass

# Schémas pour l'authentification
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_type: str

class TokenData(BaseModel):
    user_id: str
    user_type: str
    email: str

# Schémas pour les réponses avec relations
class ClientWithBookings(ClientResponse):
    bookings: List[str] = []  # IDs des réservations
    reviews: List[str] = []   # IDs des avis

class ArtisanWithServices(ArtisanResponse):
    services: List[str] = []  # IDs des services

# Schéma pour le profil utilisateur
class UserProfile(BaseModel):
    id: str
    email: str
    phone: str
    user_type: str
    profile_data: dict

# Schémas pour la réinitialisation avec code
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class VerifyResetCodeRequest(BaseModel):
    email: EmailStr
    code: str

class ResetPasswordRequest(BaseModel):
    reset_token: str
    new_password: str

    @validator('new_password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Le mot de passe doit contenir au moins 8 caractères')
        return v

# NOUVEAUX SCHÉMAS POUR LES UPLOADS
class UploadResponse(BaseModel):
    message: str
    url: str
    public_id: str
    format: str
    width: int
    height: int

class PortfolioUploadResponse(BaseModel):
    message: str
    url: str
    public_id: str
    portfolio_count: int

class DeleteImageResponse(BaseModel):
    message: str
    deleted_from_cloudinary: bool
    portfolio_count: int

# Schémas pour les documents d'identité
class IdentityDocumentUploadResponse(BaseModel):
    message: str
    document_type: str
    url: str
    public_id: str

class IdentityDocumentsResponse(BaseModel):
    cin_recto: Optional[str] = None
    cin_verso: Optional[str] = None
    photo: Optional[str] = None