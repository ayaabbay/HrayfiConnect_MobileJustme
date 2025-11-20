import json
from typing import Dict, List
from fastapi import WebSocket, WebSocketDisconnect, status
from bson import ObjectId

from app.models.chat_models import ChatManager
from app.models.booking_models import BookingManager
from app.models.user_models import UserManager
from app.core.database import get_database
from app.schemas.chat_schemas import ChatMessageCreate, WebSocketMessage

class ConnectionManager:
    def __init__(self):
        # Structure: {user_id: WebSocket}
        self.active_connections: Dict[str, WebSocket] = {}
        # Structure: {booking_id: List[user_id]}
        self.booking_rooms: Dict[str, List[str]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Connecte un utilisateur"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"✅ Utilisateur {user_id} connecté au chat")
    
    def disconnect(self, user_id: str):
        """Déconnecte un utilisateur"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            
        # Retirer l'utilisateur de toutes les rooms
        for booking_id, users in self.booking_rooms.items():
            if user_id in users:
                users.remove(user_id)
                if not users:
                    del self.booking_rooms[booking_id]
        
        print(f"❌ Utilisateur {user_id} déconnecté du chat")
    
    async def join_booking_room(self, user_id: str, booking_id: str):
        """Rejoint une room de réservation"""
        if booking_id not in self.booking_rooms:
            self.booking_rooms[booking_id] = []
        
        if user_id not in self.booking_rooms[booking_id]:
            self.booking_rooms[booking_id].append(user_id)
        
        print(f"🎯 Utilisateur {user_id} a rejoint la room {booking_id}")
    
    def leave_booking_room(self, user_id: str, booking_id: str):
        """Quitte une room de réservation"""
        if booking_id in self.booking_rooms and user_id in self.booking_rooms[booking_id]:
            self.booking_rooms[booking_id].remove(user_id)
            if not self.booking_rooms[booking_id]:
                del self.booking_rooms[booking_id]
    
    async def send_personal_message(self, message: str, user_id: str):
        """Envoie un message à un utilisateur spécifique"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(message)
            except Exception as e:
                print(f"❌ Erreur envoi message à {user_id}: {e}")
                self.disconnect(user_id)
    
    async def broadcast_to_booking(self, message: str, booking_id: str, exclude_user: str = None):
        """Diffuse un message à tous les utilisateurs d'une réservation"""
        if booking_id in self.booking_rooms:
            for user_id in self.booking_rooms[booking_id]:
                if user_id != exclude_user and user_id in self.active_connections:
                    try:
                        await self.active_connections[user_id].send_text(message)
                    except Exception as e:
                        print(f"❌ Erreur broadcast à {user_id}: {e}")
                        self.disconnect(user_id)

# Instance globale du gestionnaire de connexions
manager = ConnectionManager()

async def handle_websocket_connection(websocket: WebSocket, user_id: str):
    """Gère la connexion WebSocket d'un utilisateur"""
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Recevoir les messages de l'utilisateur
            data = await websocket.receive_text()
            await handle_websocket_message(user_id, data)
            
    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as e:
        print(f"❌ Erreur WebSocket: {e}")
        manager.disconnect(user_id)

async def handle_websocket_message(user_id: str, message_data: str):
    """Traite les messages WebSocket"""
    try:
        data = json.loads(message_data)
        message_type = data.get("type")
        
        if message_type == "join_room":
            await handle_join_room(user_id, data)
        elif message_type == "send_message":
            await handle_send_message(user_id, data)
        elif message_type == "mark_read":
            await handle_mark_read(user_id, data)
        elif message_type == "typing":
            await handle_typing(user_id, data)
            
    except json.JSONDecodeError:
        print(f"❌ Message JSON invalide de {user_id}")
    except Exception as e:
        print(f"❌ Erreur traitement message: {e}")

async def handle_join_room(user_id: str, data: dict):
    """Gère la jointure d'une room de réservation"""
    booking_id = data.get("booking_id")
    
    if not booking_id:
        return
    
    # Vérifier que l'utilisateur a accès à cette réservation
    database = get_database()
    booking_manager = BookingManager(database)
    user_manager = UserManager(database)
    
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        return
    
    user = await user_manager.find_user_by_id(user_id)
    if not user:
        return
    
    # Vérifier que l'utilisateur est soit le client soit l'artisan de la réservation
    if user_id not in [booking["client_id"], booking["artisan_id"]]:
        return
    
    # Rejoindre la room
    await manager.join_booking_room(user_id, booking_id)
    
    # Envoyer l'historique des messages
    chat_manager = ChatManager(database)
    messages = await chat_manager.get_messages_by_booking(booking_id)
    
    response = WebSocketMessage(
        type="message_history",
        data={
            "booking_id": booking_id,
            "messages": [
                {
                    "id": str(msg["_id"]),
                    "sender_id": msg["sender_id"],
                    "sender_type": msg["sender_type"],
                    "content": msg["content"],
                    "message_type": msg.get("message_type", "text"),
                    "created_at": msg["created_at"].isoformat(),
                    "is_read": msg.get("is_read", False)
                }
                for msg in messages
            ]
        }
    )
    
    await manager.send_personal_message(response.model_dump_json(), user_id)

async def handle_send_message(user_id: str, data: dict):
    """Gère l'envoi d'un message"""
    booking_id = data.get("booking_id")
    content = data.get("content")
    message_type = data.get("message_type", "text")
    
    if not booking_id or not content:
        return
    
    # Vérifier les permissions
    database = get_database()
    booking_manager = BookingManager(database)
    user_manager = UserManager(database)
    
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        return
    
    user = await user_manager.find_user_by_id(user_id)
    if not user:
        return
    
    # Déterminer le destinataire
    if user_id == booking["client_id"]:
        receiver_id = booking["artisan_id"]
        sender_type = "client"
    else:
        receiver_id = booking["client_id"]
        sender_type = "artisan"
    
    # Créer le message dans la base de données
    chat_manager = ChatManager(database)
    
    message_data = {
        "booking_id": booking_id,
        "sender_id": user_id,
        "sender_type": sender_type,
        "receiver_id": receiver_id,
        "content": content,
        "message_type": message_type
    }
    
    try:
        created_message = await chat_manager.create_message(message_data)
        
        # Préparer la réponse WebSocket
        response = WebSocketMessage(
            type="new_message",
            data={
                "id": str(created_message["_id"]),
                "booking_id": booking_id,
                "sender_id": user_id,
                "sender_type": sender_type,
                "content": content,
                "message_type": message_type,
                "created_at": created_message["created_at"].isoformat(),
                "is_read": False
            }
        )
        
        # Diffuser le message à tous les participants de la room
        await manager.broadcast_to_booking(
            response.model_dump_json(), 
            booking_id, 
            exclude_user=user_id
        )
        
    except Exception as e:
        print(f"❌ Erreur envoi message: {e}")

async def handle_mark_read(user_id: str, data: dict):
    """Gère le marquage des messages comme lus"""
    booking_id = data.get("booking_id")
    
    if not booking_id:
        return
    
    database = get_database()
    chat_manager = ChatManager(database)
    
    # Marquer les messages comme lus
    read_count = await chat_manager.mark_messages_as_read(booking_id, user_id)
    
    if read_count > 0:
        # Notifier les autres utilisateurs
        response = WebSocketMessage(
            type="messages_read",
            data={
                "booking_id": booking_id,
                "user_id": user_id,
                "read_count": read_count
            }
        )
        
        await manager.broadcast_to_booking(
            response.model_dump_json(), 
            booking_id, 
            exclude_user=user_id
        )

async def handle_typing(user_id: str, data: dict):
    """Gère l'indication de frappe"""
    booking_id = data.get("booking_id")
    is_typing = data.get("is_typing", False)
    
    if not booking_id:
        return
    
    response = WebSocketMessage(
        type="typing",
        data={
            "booking_id": booking_id,
            "user_id": user_id,
            "is_typing": is_typing
        }
    )
    
    await manager.broadcast_to_booking(
        response.model_dump_json(), 
        booking_id, 
        exclude_user=user_id
    )