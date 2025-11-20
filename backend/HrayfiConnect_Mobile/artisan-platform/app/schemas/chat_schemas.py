from pydantic import BaseModel, validator, ConfigDict, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class MessageType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    FILE = "file"

class ChatMessageBase(BaseModel):
    booking_id: str
    sender_id: str
    sender_type: str  # "client" ou "artisan"
    receiver_id: str
    content: str
    message_type: MessageType = MessageType.TEXT

class ChatMessageCreate(ChatMessageBase):
    @validator('content')
    def content_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Le message ne peut pas être vide')
        return v
    
    @validator('sender_type')
    def sender_type_must_be_valid(cls, v):
        if v not in ["client", "artisan"]:
            raise ValueError('Le type d\'expéditeur doit être "client" ou "artisan"')
        return v

class ChatMessageResponse(ChatMessageBase):
    id: str
    is_read: bool
    created_at: datetime
    read_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)

# Schémas pour les conversations
class UserInfo(BaseModel):
    id: str
    first_name: str
    last_name: str
    profile_picture: Optional[str] = None
    user_type: str

class LastMessage(BaseModel):
    content: str
    created_at: datetime
    is_read: bool
    sender_id: Optional[str] = None  # ✅ Correction: Rendre sender_id optionnel

class Conversation(BaseModel):
    booking_id: str
    other_user: UserInfo
    last_message: LastMessage
    unread_count: int

# Schéma pour les réponses WebSocket
class WebSocketMessage(BaseModel):
    type: str  # "message", "read_receipt", "typing"
    data: dict

# Statistiques de chat
class ChatStats(BaseModel):
    total_messages: int
    unread_messages: int
    active_conversations: int