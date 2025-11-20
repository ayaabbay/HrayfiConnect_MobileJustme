from pydantic import BaseModel, validator, ConfigDict
from typing import Optional, List
from datetime import datetime, timezone
from enum import Enum

class BookingStatus(str, Enum):
    PENDING = "pending"       # En attente
    CONFIRMED = "confirmed"   # Confirmé
    IN_PROGRESS = "in_progress"  # En cours
    COMPLETED = "completed"   # Terminé
    CANCELLED = "cancelled"   # Annulé
    REJECTED = "rejected"     # Refusé

class BookingBase(BaseModel):
    client_id: str
    artisan_id: str
    scheduled_date: datetime
    description: str
    urgency: bool = False
    address: Optional[str] = None
    status: BookingStatus = BookingStatus.PENDING

class BookingCreate(BookingBase):
    @validator('scheduled_date')
    def scheduled_date_must_be_future(cls, v):
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        
        now = datetime.now(timezone.utc)
        if v <= now:
            raise ValueError('La date de réservation doit être dans le futur')
        return v

class BookingUpdate(BaseModel):
    scheduled_date: Optional[datetime] = None
    status: Optional[BookingStatus] = None
    description: Optional[str] = None
    urgency: Optional[bool] = None
    address: Optional[str] = None

    @validator('scheduled_date')
    def scheduled_date_must_be_future(cls, v):
        if v is None:
            return v
            
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        
        now = datetime.now(timezone.utc)
        if v <= now:
            raise ValueError('La date de réservation doit être dans le futur')
        return v

class BookingResponse(BookingBase):
    id: str
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# Schémas pour les réponses détaillées
class UserInfo(BaseModel):
    id: str
    first_name: str
    last_name: str
    email: str
    phone: str
    profile_picture: Optional[str] = None

class ArtisanInfo(UserInfo):
    company_name: Optional[str] = None
    trade: str
    is_verified: bool = False

class BookingDetailedResponse(BookingResponse):
    client: Optional[UserInfo] = None  # ⬅️ Rendre optionnel
    artisan: Optional[ArtisanInfo] = None  # ⬅️ Rendre optionnel

# Statistiques
class BookingStats(BaseModel):
    total: int
    pending: int
    confirmed: int
    in_progress: int
    completed: int
    cancelled: int

# Filtres de recherche
class BookingFilter(BaseModel):
    status: Optional[BookingStatus] = None
    urgency: Optional[bool] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None