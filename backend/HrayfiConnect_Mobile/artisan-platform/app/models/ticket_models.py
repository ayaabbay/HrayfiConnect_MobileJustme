from datetime import datetime
from typing import Optional, List
from bson import ObjectId
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

class TicketManager:
    def __init__(self, database):
        self.collection = database["tickets"]
        self.users_collection = database["users"]
    
    async def create_ticket(self, ticket_data: dict):
        """Crée un nouveau ticket"""
        try:
            ticket_data["created_at"] = datetime.utcnow()
            ticket_data["updated_at"] = datetime.utcnow()
            ticket_data["status"] = TicketStatus.OPEN
            ticket_data["ticket_number"] = await self._generate_ticket_number()
            
            result = await self.collection.insert_one(ticket_data)
            ticket_data["_id"] = result.inserted_id
            
            print(f"✅ Ticket créé: {ticket_data['ticket_number']}")
            return ticket_data
            
        except Exception as e:
            print(f"❌ Erreur création ticket: {e}")
            raise
    
    async def _generate_ticket_number(self):
        """Génère un numéro de ticket unique"""
        try:
            # Compter le nombre de tickets pour générer un numéro séquentiel
            count = await self.collection.count_documents({})
            return f"TKT-{datetime.utcnow().strftime('%Y%m%d')}-{count + 1:04d}"
        except Exception as e:
            print(f"❌ Erreur génération numéro ticket: {e}")
            return f"TKT-{datetime.utcnow().strftime('%Y%m%d')}-{int(datetime.utcnow().timestamp())}"
    
    async def find_ticket_by_id(self, ticket_id: str):
        """Trouve un ticket par son ID"""
        try:
            return await self.collection.find_one({"_id": ObjectId(ticket_id)})
        except Exception as e:
            print(f"❌ Erreur recherche ticket {ticket_id}: {e}")
            return None
    
    async def find_ticket_by_number(self, ticket_number: str):
        """Trouve un ticket par son numéro"""
        try:
            return await self.collection.find_one({"ticket_number": ticket_number})
        except Exception as e:
            print(f"❌ Erreur recherche ticket {ticket_number}: {e}")
            return None
    
    async def find_tickets_by_user(self, user_id: str, skip: int = 0, limit: int = 100):
        """Trouve les tickets d'un utilisateur"""
        try:
            query = {"user_id": user_id}
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            tickets = []
            async for ticket in cursor:
                tickets.append(ticket)
            return tickets
        except Exception as e:
            print(f"❌ Erreur recherche tickets utilisateur {user_id}: {e}")
            return []
    
    async def find_all_tickets(self, skip: int = 0, limit: int = 100):
        """Trouve tous les tickets (pour admin)"""
        try:
            cursor = self.collection.find().sort("created_at", -1).skip(skip).limit(limit)
            tickets = []
            async for ticket in cursor:
                tickets.append(ticket)
            return tickets
        except Exception as e:
            print(f"❌ Erreur recherche tous les tickets: {e}")
            return []
    
    async def update_ticket(self, ticket_id: str, update_data: dict):
        """Met à jour un ticket"""
        try:
            update_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.update_one(
                {"_id": ObjectId(ticket_id)},
                {"$set": update_data}
            )
            
            print(f"📝 Ticket {ticket_id} mis à jour: {result.modified_count} modification(s)")
            
            if result.modified_count == 0:
                return None
                
            return await self.find_ticket_by_id(ticket_id)
            
        except Exception as e:
            print(f"❌ Erreur mise à jour ticket {ticket_id}: {e}")
            return None
    
    async def update_ticket_status(self, ticket_id: str, status: TicketStatus, admin_notes: str = None):
        """Met à jour le statut d'un ticket (Admin seulement)"""
        update_data = {"status": status}
        if admin_notes:
            update_data["admin_notes"] = admin_notes
            
        return await self.update_ticket(ticket_id, update_data)
    
    async def add_ticket_response(self, ticket_id: str, response_data: dict):
        """Ajoute une réponse à un ticket"""
        try:
            response_data["created_at"] = datetime.utcnow()
            response_data["id"] = str(ObjectId())  # Générer un ID unique pour la réponse
            
            result = await self.collection.update_one(
                {"_id": ObjectId(ticket_id)},
                {"$push": {"responses": response_data}, "$set": {"updated_at": datetime.utcnow()}}
            )
            
            return result.modified_count > 0
            
        except Exception as e:
            print(f"❌ Erreur ajout réponse ticket {ticket_id}: {e}")
            return False
    
    async def delete_ticket(self, ticket_id: str):
        """Supprime un ticket"""
        try:
            result = await self.collection.delete_one({"_id": ObjectId(ticket_id)})
            return result.deleted_count > 0
        except Exception as e:
            print(f"❌ Erreur suppression ticket {ticket_id}: {e}")
            return False
    
    async def get_tickets_with_details(self, query: dict, skip: int = 0, limit: int = 100):
        """Récupère les tickets avec les détails des utilisateurs"""
        try:
            # Méthode simplifiée sans aggregation
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            tickets = []
            
            async for ticket in cursor:
                # Récupérer les détails de l'utilisateur
                user = await self.users_collection.find_one({"_id": ObjectId(ticket["user_id"])})
                
                # Préparer les données utilisateur
                user_info = None
                if user:
                    user_info = {
                        "id": str(user["_id"]),
                        "first_name": user.get("first_name", ""),
                        "last_name": user.get("last_name", ""),
                        "email": user.get("email", ""),
                        "user_type": user.get("user_type", ""),
                        "profile_picture": user.get("profile_picture")
                    }
                
                # Ajouter les détails au ticket
                ticket["user"] = user_info
                tickets.append(ticket)
            
            return tickets
            
        except Exception as e:
            print(f"❌ Erreur recherche tickets détaillés: {e}")
            return []
    
    async def get_ticket_stats(self):
        """Récupère les statistiques des tickets"""
        try:
            total = await self.collection.count_documents({})
            open_count = await self.collection.count_documents({"status": TicketStatus.OPEN})
            in_progress_count = await self.collection.count_documents({"status": TicketStatus.IN_PROGRESS})
            resolved_count = await self.collection.count_documents({"status": TicketStatus.RESOLVED})
            closed_count = await self.collection.count_documents({"status": TicketStatus.CLOSED})
            
            return {
                "total": total,
                "open": open_count,
                "in_progress": in_progress_count,
                "resolved": resolved_count,
                "closed": closed_count
            }
        except Exception as e:
            print(f"❌ Erreur statistiques tickets: {e}")
            return {
                "total": 0,
                "open": 0,
                "in_progress": 0,
                "resolved": 0,
                "closed": 0
            }