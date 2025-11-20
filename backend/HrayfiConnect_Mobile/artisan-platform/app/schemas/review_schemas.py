from pydantic import BaseModel, validator, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ReviewBase(BaseModel):
    client_id: str
    artisan_id: str
    booking_id: str
    rating: int
    comment: str

class ReviewCreate(ReviewBase):
    @validator('rating')
    def rating_must_be_between_0_and_5(cls, v):
        if v < 0 or v > 5:
            raise ValueError('La note doit être entre 0 et 5 étoiles')
        return v
    
    @validator('comment')
    def comment_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Le commentaire ne peut pas être vide')
        return v

class ReviewUpdate(BaseModel):
    rating: Optional[int] = None
    comment: Optional[str] = None
    
    @validator('rating')
    def rating_must_be_between_0_and_5(cls, v):
        if v is not None and (v < 0 or v > 5):
            raise ValueError('La note doit être entre 0 et 5 étoiles')
        return v
    
    @validator('comment')
    def comment_must_not_be_empty(cls, v):
        if v is not None and not v.strip():
            raise ValueError('Le commentaire ne peut pas être vide')
        return v

class ReviewResponse(ReviewBase):
    id: str
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# Schémas pour les réponses détaillées
class UserInfo(BaseModel):
    id: str
    first_name: str
    last_name: str
    profile_picture: Optional[str] = None

class ArtisanInfo(UserInfo):
    company_name: Optional[str] = None
    trade: str

class BookingInfo(BaseModel):
    id: str
    scheduled_date: datetime
    description: str
    status: str

class ReviewDetailedResponse(ReviewResponse):
    client: UserInfo
    artisan: ArtisanInfo
    booking: BookingInfo

# Statistiques de notation
class RatingStats(BaseModel):
    artisan_id: str
    average_rating: float
    review_count: int
    rating_distribution: dict

# Filtres de recherche
class ReviewFilter(BaseModel):
    min_rating: Optional[int] = None
    max_rating: Optional[int] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None