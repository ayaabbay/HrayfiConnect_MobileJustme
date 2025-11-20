from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, Query, Body
from typing import List
from bson import ObjectId

from app.models.chat_models import ChatManager
from app.models.booking_models import BookingManager
from app.models.user_models import UserManager
from app.schemas.chat_schemas import Conversation, ChatStats, ChatMessageResponse, ChatMessageCreate
from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_database
from app.api.v1.websockets.chat import handle_websocket_connection

router = APIRouter()

def get_chat_manager():
    database = get_database()
    return ChatManager(database)

def get_booking_manager():
    database = get_database()
    return BookingManager(database)

def get_user_manager():
    database = get_database()
    return UserManager(database)

@router.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket, token: str = Query(...)):
    """
    Endpoint WebSocket pour le chat en temps réel
    Connexion: ws://localhost:8000/api/v1/chat/ws/chat?token=<jwt_token>
    """
    from app.api.v1.endpoints.auth import get_current_user_websocket
    
    try:
        # Vérifier l'authentification
        user = await get_current_user_websocket(token)
        user_id = str(user["_id"])
        
        # Gérer la connexion WebSocket
        await handle_websocket_connection(websocket, user_id)
        
    except HTTPException:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
    except Exception as e:
        print(f"❌ Erreur connexion WebSocket: {e}")
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)

@router.get("/conversations", response_model=List[Conversation])
async def get_my_conversations(
    current_user: dict = Depends(get_current_user),
    chat_manager: ChatManager = Depends(get_chat_manager)
):
    """
    Récupère les conversations de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    if user_type not in ["client", "artisan"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients et artisans peuvent accéder au chat"
        )
    
    conversations = await chat_manager.get_conversations_for_user(user_id, user_type)
    return conversations

@router.get("/conversations/{booking_id}/messages", response_model=List[ChatMessageResponse])
async def get_conversation_messages(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    chat_manager: ChatManager = Depends(get_chat_manager),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Récupère les messages d'une conversation spécifique
    """
    user_id = str(current_user["_id"])
    
    # Vérifier que l'utilisateur a accès à cette réservation
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    if user_id not in [booking["client_id"], booking["artisan_id"]]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette conversation"
        )
    
    messages = await chat_manager.get_messages_by_booking(booking_id)
    
    # Convertir ObjectId en string
    for message in messages:
        message["id"] = str(message["_id"])
    
    return [ChatMessageResponse(**message) for message in messages]

@router.post("/conversations/{booking_id}/messages", response_model=ChatMessageResponse)
async def send_message(
    booking_id: str,
    message_data: ChatMessageCreate = Body(...),
    current_user: dict = Depends(get_current_user),
    chat_manager: ChatManager = Depends(get_chat_manager),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Envoie un message dans une conversation (Alternative REST au WebSocket)
    """
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier que l'utilisateur a accès à cette réservation
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    if user_id not in [booking["client_id"], booking["artisan_id"]]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette conversation"
        )
    
    # Vérifier que le message est envoyé par l'utilisateur connecté
    if message_data.sender_id != user_id or message_data.sender_type != user_type:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez envoyer des messages qu'en votre nom"
        )
    
    # Vérifier que booking_id correspond
    if message_data.booking_id != booking_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le booking_id dans l'URL ne correspond pas au message"
        )
    
    # Déterminer le receiver_id
    if user_type == "client":
        receiver_id = booking["artisan_id"]
        receiver_type = "artisan"
    else:
        receiver_id = booking["client_id"]
        receiver_type = "client"
    
    # Créer le message
    message_dict = message_data.model_dump()
    message_dict["receiver_id"] = receiver_id
    message_dict["receiver_type"] = receiver_type
    
    try:
        created_message = await chat_manager.create_message(message_dict)
        created_message["id"] = str(created_message["_id"])
        
        return ChatMessageResponse(**created_message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de l'envoi du message: {str(e)}"
        )

@router.post("/conversations/{booking_id}/read")
async def mark_conversation_as_read(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    chat_manager: ChatManager = Depends(get_chat_manager),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Marque tous les messages d'une conversation comme lus
    """
    user_id = str(current_user["_id"])
    
    # Vérifier que l'utilisateur a accès à cette réservation
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    if user_id not in [booking["client_id"], booking["artisan_id"]]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette conversation"
        )
    
    read_count = await chat_manager.mark_messages_as_read(booking_id, user_id)
    
    return {
        "message": f"{read_count} messages marqués comme lus",
        "read_count": read_count
    }

@router.get("/stats", response_model=ChatStats)
async def get_chat_stats(
    current_user: dict = Depends(get_current_user),
    chat_manager: ChatManager = Depends(get_chat_manager)
):
    """
    Récupère les statistiques de chat de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    
    # Récupérer les conversations pour compter les conversations actives
    conversations = await chat_manager.get_conversations_for_user(
        user_id, 
        current_user.get("user_type")
    )
    
    unread_count = await chat_manager.get_unread_count(user_id)
    
    # Compter le nombre total de messages (approximatif)
    total_messages = 0
    for conversation in conversations:
        # Cette méthode n'est pas optimale, mais fonctionne pour de petits volumes
        booking_messages = await chat_manager.get_messages_by_booking(conversation["booking_id"])
        total_messages += len(booking_messages)
    
    return ChatStats(
        total_messages=total_messages,
        unread_messages=unread_count,
        active_conversations=len(conversations)
    )