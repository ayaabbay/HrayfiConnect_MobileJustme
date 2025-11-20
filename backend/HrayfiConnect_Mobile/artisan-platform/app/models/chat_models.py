from datetime import datetime
from typing import Optional, List
from bson import ObjectId

class ChatManager:
    def __init__(self, database):
        self.collection = database["chat_messages"]
        self.bookings_collection = database["bookings"]
        self.users_collection = database["users"]
    
    async def create_message(self, message_data: dict):
        """Crée un nouveau message de chat"""
        try:
            # Vérifier qu'il existe une réservation entre le client et l'artisan
            booking = await self.bookings_collection.find_one({
                "_id": ObjectId(message_data["booking_id"])
            })
            
            if not booking:
                raise ValueError("Aucune réservation trouvée")
            
            # Vérifier que l'expéditeur et le destinataire font partie de la réservation
            if message_data["sender_type"] == "client":
                if message_data["sender_id"] != booking["client_id"] or message_data["receiver_id"] != booking["artisan_id"]:
                    raise ValueError("L'expéditeur ou le destinataire ne correspondent pas à la réservation")
            else:
                if message_data["sender_id"] != booking["artisan_id"] or message_data["receiver_id"] != booking["client_id"]:
                    raise ValueError("L'expéditeur ou le destinataire ne correspondent pas à la réservation")
            
            message_data["created_at"] = datetime.utcnow()
            message_data["is_read"] = False
            
            result = await self.collection.insert_one(message_data)
            message_data["_id"] = result.inserted_id
            
            print(f"💬 Message créé: {message_data['_id']}")
            return message_data
            
        except Exception as e:
            print(f"❌ Erreur création message: {e}")
            raise
    
    async def get_messages_by_booking(self, booking_id: str, skip: int = 0, limit: int = 100):
        """Récupère les messages d'une réservation"""
        try:
            query = {"booking_id": booking_id}
            cursor = self.collection.find(query).sort("created_at", 1).skip(skip).limit(limit)
            messages = []
            async for message in cursor:
                message["id"] = str(message["_id"])  # Convertir ObjectId en string
                messages.append(message)
            return messages
        except Exception as e:
            print(f"❌ Erreur recherche messages booking {booking_id}: {e}")
            return []
    
    async def get_conversations_for_user(self, user_id: str, user_type: str):
        """Récupère les conversations d'un utilisateur"""
        try:
            print(f"🔍 Recherche conversations pour {user_id} (type: {user_type})")
            
            # Trouver toutes les réservations où l'utilisateur est impliqué
            if user_type == "client":
                bookings_cursor = self.bookings_collection.find({"client_id": user_id})
            else:
                bookings_cursor = self.bookings_collection.find({"artisan_id": user_id})
            
            bookings = await bookings_cursor.to_list(length=100)
            print(f"📖 Réservations trouvées: {len(bookings)}")
            
            conversations = []
            
            for booking in bookings:
                print(f"📋 Traitement réservation: {booking['_id']}")
                
                # Récupérer le dernier message de chaque conversation
                last_message = await self.collection.find_one(
                    {"booking_id": str(booking["_id"])},
                    sort=[("created_at", -1)]
                )
                
                # Récupérer les détails de l'autre utilisateur
                other_user_id = booking["client_id"] if user_type == "artisan" else booking["artisan_id"]
                print(f"👤 Recherche autre utilisateur: {other_user_id}")
                
                other_user = await self.users_collection.find_one({"_id": ObjectId(other_user_id)})
                
                if other_user:
                    print(f"✅ Utilisateur trouvé: {other_user.get('first_name')} {other_user.get('last_name')}")
                    
                    if last_message:
                        conversation_data = {
                            "booking_id": str(booking["_id"]),
                            "other_user": {
                                "id": other_user_id,
                                "first_name": other_user.get("first_name", ""),
                                "last_name": other_user.get("last_name", ""),
                                "profile_picture": other_user.get("profile_picture"),
                                "user_type": "client" if user_type == "artisan" else "artisan"
                            },
                            "last_message": {
                                "content": last_message["content"],
                                "created_at": last_message["created_at"],
                                "is_read": last_message["is_read"],
                                "sender_id": last_message["sender_id"]
                            },
                            "unread_count": await self.collection.count_documents({
                                "booking_id": str(booking["_id"]),
                                "receiver_id": user_id,
                                "is_read": False
                            })
                        }
                    else:
                        # Créer une conversation vide s'il n'y a pas de messages
                        conversation_data = {
                            "booking_id": str(booking["_id"]),
                            "other_user": {
                                "id": other_user_id,
                                "first_name": other_user.get("first_name", ""),
                                "last_name": other_user.get("last_name", ""),
                                "profile_picture": other_user.get("profile_picture"),
                                "user_type": "client" if user_type == "artisan" else "artisan"
                            },
                            "last_message": {
                                "content": "Aucun message échangé",
                                "created_at": booking.get("created_at", datetime.utcnow()),
                                "is_read": True,
                                "sender_id": None  # ✅ Correction: None au lieu de chaîne vide
                            },
                            "unread_count": 0
                        }
                    
                    conversations.append(conversation_data)
                    print(f"✅ Conversation ajoutée pour la réservation {booking['_id']}")
                else:
                    print(f"❌ Utilisateur {other_user_id} non trouvé")
            
            # Trier par date du dernier message (plus récent en premier)
            conversations.sort(key=lambda x: x["last_message"]["created_at"], reverse=True)
            print(f"🎯 Conversations finales: {len(conversations)}")
            
            return conversations
            
        except Exception as e:
            print(f"❌ Erreur recherche conversations utilisateur {user_id}: {e}")
            import traceback
            traceback.print_exc()
            return []
    
    async def mark_messages_as_read(self, booking_id: str, user_id: str):
        """Marque les messages comme lus"""
        try:
            result = await self.collection.update_many(
                {
                    "booking_id": booking_id,
                    "receiver_id": user_id,
                    "is_read": False
                },
                {"$set": {"is_read": True, "read_at": datetime.utcnow()}}
            )
            
            print(f"📖 Messages marqués comme lus: {result.modified_count}")
            return result.modified_count
            
        except Exception as e:
            print(f"❌ Erreur marquage messages comme lus: {e}")
            return 0
    
    async def get_unread_count(self, user_id: str):
        """Récupère le nombre de messages non lus"""
        try:
            count = await self.collection.count_documents({
                "receiver_id": user_id,
                "is_read": False
            })
            return count
        except Exception as e:
            print(f"❌ Erreur comptage messages non lus: {e}")
            return 0