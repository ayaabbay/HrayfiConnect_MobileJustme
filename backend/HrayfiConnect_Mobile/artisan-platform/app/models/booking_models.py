from datetime import datetime
from typing import Optional, List
from bson import ObjectId

class BookingManager:
    def __init__(self, database):
        self.collection = database["bookings"]
        self.users_collection = database["users"]  # Ajout pour accéder aux users
    
    async def create_booking(self, booking_data: dict):
        """Crée une nouvelle réservation"""
        try:
            booking_data["created_at"] = datetime.utcnow()
            booking_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.insert_one(booking_data)
            booking_data["_id"] = result.inserted_id
            
            print(f"✅ Réservation créée: {booking_data['_id']}")
            return booking_data
            
        except Exception as e:
            print(f"❌ Erreur création réservation: {e}")
            raise
    
    async def find_booking_by_id(self, booking_id: str):
        """Trouve une réservation par son ID"""
        try:
            # Valider que booking_id n'est pas vide
            if not booking_id or not booking_id.strip():
                print(f"❌ Erreur recherche réservation: booking_id est vide")
                return None
            
            # Valider le format ObjectId
            if not ObjectId.is_valid(booking_id):
                print(f"❌ Erreur recherche réservation {booking_id}: format ObjectId invalide")
                return None
                
            return await self.collection.find_one({"_id": ObjectId(booking_id)})
        except Exception as e:
            print(f"❌ Erreur recherche réservation {booking_id}: {e}")
            return None
    
    async def find_bookings_by_client(self, client_id: str, skip: int = 0, limit: int = 100):
        """Trouve les réservations d'un client"""
        try:
            query = {"client_id": client_id}
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            bookings = []
            async for booking in cursor:
                bookings.append(booking)
            return bookings
        except Exception as e:
            print(f"❌ Erreur recherche réservations client {client_id}: {e}")
            return []
    
    async def find_bookings_by_artisan(self, artisan_id: str, skip: int = 0, limit: int = 100):
        """Trouve les réservations d'un artisan"""
        try:
            query = {"artisan_id": artisan_id}
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            bookings = []
            async for booking in cursor:
                bookings.append(booking)
            return bookings
        except Exception as e:
            print(f"❌ Erreur recherche réservations artisan {artisan_id}: {e}")
            return []
    
    async def update_booking(self, booking_id: str, update_data: dict):
        """Met à jour une réservation"""
        try:
            update_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.update_one(
                {"_id": ObjectId(booking_id)},
                {"$set": update_data}
            )
            
            print(f"📝 Réservation {booking_id} mise à jour: {result.modified_count} modification(s)")
            
            if result.modified_count == 0:
                return None
                
            return await self.find_booking_by_id(booking_id)
            
        except Exception as e:
            print(f"❌ Erreur mise à jour réservation {booking_id}: {e}")
            return None
    
    async def update_booking_status(self, booking_id: str, status: str):
        """Met à jour le statut d'une réservation"""
        return await self.update_booking(booking_id, {"status": status})
    
    async def update_booking_schedule(self, booking_id: str, scheduled_date: datetime):
        """Met à jour la date de réservation"""
        return await self.update_booking(booking_id, {"scheduled_date": scheduled_date})
    
    async def delete_booking(self, booking_id: str):
        """Supprime une réservation"""
        try:
            result = await self.collection.delete_one({"_id": ObjectId(booking_id)})
            return result.deleted_count > 0
        except Exception as e:
            print(f"❌ Erreur suppression réservation {booking_id}: {e}")
            return False
    
    async def get_bookings_with_details(self, query: dict, skip: int = 0, limit: int = 100):
        """Récupère les réservations avec les détails des utilisateurs"""
        try:
            # Méthode simplifiée sans aggregation
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            bookings = []
            
            async for booking in cursor:
                # Récupérer les détails du client
                client = await self.users_collection.find_one({"_id": ObjectId(booking["client_id"])})
                # Récupérer les détails de l'artisan
                artisan = await self.users_collection.find_one({"_id": ObjectId(booking["artisan_id"])})
                
                # Préparer les données client
                client_info = None
                if client:
                    # Récupérer l'adresse depuis profile_data si disponible
                    profile_data = client.get("profile_data", {})
                    client_address = profile_data.get("address") if isinstance(profile_data, dict) else None
                    if not client_address:
                        client_address = client.get("address")
                    
                    client_info = {
                        "id": str(client["_id"]),
                        "first_name": client.get("first_name", ""),
                        "last_name": client.get("last_name", ""),
                        "email": client.get("email", ""),
                        "phone": client.get("phone", ""),
                        "address": client_address,
                        "profile_picture": client.get("profile_picture")
                    }
                
                # Préparer les données artisan
                artisan_info = None
                if artisan:
                    artisan_info = {
                        "id": str(artisan["_id"]),
                        "first_name": artisan.get("first_name", ""),
                        "last_name": artisan.get("last_name", ""),
                        "email": artisan.get("email", ""),
                        "phone": artisan.get("phone", ""),
                        "profile_picture": artisan.get("profile_picture"),
                        "company_name": artisan.get("company_name"),
                        "trade": artisan.get("trade", ""),
                        "is_verified": artisan.get("is_verified", False)
                    }
                
                # Ajouter les détails au booking
                booking["client"] = client_info
                booking["artisan"] = artisan_info
                bookings.append(booking)
            
            return bookings
            
        except Exception as e:
            print(f"❌ Erreur recherche réservations détaillées: {e}")
            return []