from pydantic import BaseModel, validator, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

class TicketStatus(str, Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    CLOSED = "closed"

class TicketPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class TicketCategory(str, Enum):
    TECHNICAL = "technical"
    BILLING = "billing"
    ACCOUNT = "account"
    BOOKING = "booking"
    OTHER = "other"

class TicketBase(BaseModel):
    user_id: str
    subject: str
    description: str
    category: TicketCategory
    priority: TicketPriority = TicketPriority.MEDIUM

class TicketCreate(TicketBase):
    @validator('subject')
    def subject_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Le sujet ne peut pas être vide')
        return v
    
    @validator('description')
    def description_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('La description ne peut pas être vide')
        return v

class TicketUpdate(BaseModel):
    subject: Optional[str] = None
    description: Optional[str] = None
    category: Optional[TicketCategory] = None
    priority: Optional[TicketPriority] = None
    
    @validator('subject')
    def subject_must_not_be_empty(cls, v):
        if v is not None and not v.strip():
            raise ValueError('Le sujet ne peut pas être vide')
        return v
    
    @validator('description')
    def description_must_not_be_empty(cls, v):
        if v is not None and not v.strip():
            raise ValueError('La description ne peut pas être vide')
        return v

class TicketStatusUpdate(BaseModel):
    status: TicketStatus
    admin_notes: Optional[str] = None

class TicketResponse(BaseModel):
    id: str
    user_id: str
    message: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class TicketResponseCreate(BaseModel):
    message: str
    
    @validator('message')
    def message_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Le message ne peut pas être vide')
        return v

class TicketResponse(TicketBase):
    id: str
    ticket_number: str
    status: TicketStatus
    responses: List[TicketResponse] = []
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# Schémas pour les réponses détaillées
class UserInfo(BaseModel):
    id: str
    first_name: str
    last_name: str
    email: str
    user_type: str
    profile_picture: Optional[str] = None

class TicketDetailedResponse(TicketResponse):
    user: UserInfo

# Statistiques
class TicketStats(BaseModel):
    total: int
    open: int
    in_progress: int
    resolved: int
    closed: int

# Filtres de recherche
class TicketFilter(BaseModel):
    status: Optional[TicketStatus] = None
    category: Optional[TicketCategory] = None
    priority: Optional[TicketPriority] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None