from datetime import datetime
from typing import Optional, List
from bson import ObjectId

class ReviewManager:
    def __init__(self, database):
        self.collection = database["reviews"]
        self.bookings_collection = database["bookings"]
        self.users_collection = database["users"]
    
    async def create_review(self, review_data: dict):
        """Crée un nouvel avis"""
        try:
            # Vérifier qu'il existe une réservation complétée entre ce client et cet artisan
            booking = await self.bookings_collection.find_one({
                "_id": ObjectId(review_data["booking_id"]),
                "client_id": review_data["client_id"],
                "artisan_id": review_data["artisan_id"],
                "status": "completed"
            })
            
            if not booking:
                raise ValueError("Aucune réservation complétée trouvée entre ce client et cet artisan")
            
            # Vérifier si l'utilisateur a déjà laissé un avis pour cette réservation
            existing_review = await self.collection.find_one({
                "booking_id": review_data["booking_id"],
                "client_id": review_data["client_id"]
            })
            
            if existing_review:
                raise ValueError("Vous avez déjà laissé un avis pour cette réservation")
            
            review_data["created_at"] = datetime.utcnow()
            review_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.insert_one(review_data)
            review_data["_id"] = result.inserted_id
            
            # Mettre à jour la note moyenne de l'artisan
            await self._update_artisan_rating(review_data["artisan_id"])
            
            print(f"✅ Avis créé: {review_data['_id']}")
            return review_data
            
        except Exception as e:
            print(f"❌ Erreur création avis: {e}")
            raise
    
    async def _update_artisan_rating(self, artisan_id: str):
        """Met à jour la note moyenne de l'artisan"""
        try:
            # Calculer la nouvelle moyenne
            pipeline = [
                {"$match": {"artisan_id": artisan_id}},
                {"$group": {
                    "_id": "$artisan_id",
                    "average_rating": {"$avg": "$rating"},
                    "review_count": {"$sum": 1}
                }}
            ]
            
            cursor = self.collection.aggregate(pipeline)
            result = await cursor.to_list(length=1)
            
            if result:
                rating_data = result[0]
                await self.users_collection.update_one(
                    {"_id": ObjectId(artisan_id)},
                    {"$set": {
                        "average_rating": round(rating_data["average_rating"], 1),
                        "review_count": rating_data["review_count"]
                    }}
                )
                
        except Exception as e:
            print(f"❌ Erreur mise à jour note artisan: {e}")
    
    async def find_review_by_id(self, review_id: str):
        """Trouve un avis par son ID"""
        try:
            return await self.collection.find_one({"_id": ObjectId(review_id)})
        except Exception as e:
            print(f"❌ Erreur recherche avis {review_id}: {e}")
            return None
    
    async def find_reviews_by_artisan(self, artisan_id: str, skip: int = 0, limit: int = 100):
        """Trouve les avis d'un artisan"""
        try:
            query = {"artisan_id": artisan_id}
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            reviews = []
            async for review in cursor:
                reviews.append(review)
            return reviews
        except Exception as e:
            print(f"❌ Erreur recherche avis artisan {artisan_id}: {e}")
            return []
    
    async def find_reviews_by_client(self, client_id: str, skip: int = 0, limit: int = 100):
        """Trouve les avis d'un client"""
        try:
            query = {"client_id": client_id}
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            reviews = []
            async for review in cursor:
                reviews.append(review)
            return reviews
        except Exception as e:
            print(f"❌ Erreur recherche avis client {client_id}: {e}")
            return []
    
    async def get_reviews_with_details(self, query: dict, skip: int = 0, limit: int = 100):
        """Récupère les avis avec les détails des utilisateurs"""
        try:
            # Méthode simplifiée sans aggregation
            cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
            reviews = []
            
            async for review in cursor:
                # Récupérer les détails du client
                client = await self.users_collection.find_one({"_id": ObjectId(review["client_id"])})
                # Récupérer les détails de l'artisan
                artisan = await self.users_collection.find_one({"_id": ObjectId(review["artisan_id"])})
                # Récupérer les détails de la réservation
                booking = await self.bookings_collection.find_one({"_id": ObjectId(review["booking_id"])})
                
                # Préparer les données client
                client_info = None
                if client:
                    client_info = {
                        "id": str(client["_id"]),
                        "first_name": client.get("first_name", ""),
                        "last_name": client.get("last_name", ""),
                        "profile_picture": client.get("profile_picture")
                    }
                
                # Préparer les données artisan
                artisan_info = None
                if artisan:
                    artisan_info = {
                        "id": str(artisan["_id"]),
                        "first_name": artisan.get("first_name", ""),
                        "last_name": artisan.get("last_name", ""),
                        "company_name": artisan.get("company_name"),
                        "trade": artisan.get("trade", ""),
                        "profile_picture": artisan.get("profile_picture")
                    }
                
                # Préparer les données booking
                booking_info = None
                if booking:
                    booking_info = {
                        "id": str(booking["_id"]),
                        "scheduled_date": booking.get("scheduled_date"),
                        "description": booking.get("description"),
                        "status": booking.get("status")
                    }
                
                # Ajouter les détails au review
                review["client"] = client_info
                review["artisan"] = artisan_info
                review["booking"] = booking_info
                reviews.append(review)
            
            return reviews
            
        except Exception as e:
            print(f"❌ Erreur recherche avis détaillés: {e}")
            return []
    
    async def update_review(self, review_id: str, update_data: dict):
        """Met à jour un avis"""
        try:
            update_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.update_one(
                {"_id": ObjectId(review_id)},
                {"$set": update_data}
            )
            
            print(f"📝 Avis {review_id} mis à jour: {result.modified_count} modification(s)")
            
            if result.modified_count == 0:
                return None
                
            updated_review = await self.find_review_by_id(review_id)
            
            # Mettre à jour la note moyenne de l'artisan
            if "rating" in update_data:
                await self._update_artisan_rating(updated_review["artisan_id"])
            
            return updated_review
            
        except Exception as e:
            print(f"❌ Erreur mise à jour avis {review_id}: {e}")
            return None
    
    async def delete_review(self, review_id: str):
        """Supprime un avis"""
        try:
            # Récupérer l'avis avant suppression pour mettre à jour la note de l'artisan
            review = await self.find_review_by_id(review_id)
            
            result = await self.collection.delete_one({"_id": ObjectId(review_id)})
            
            if result.deleted_count > 0 and review:
                # Mettre à jour la note moyenne de l'artisan
                await self._update_artisan_rating(review["artisan_id"])
                return True
            
            return False
            
        except Exception as e:
            print(f"❌ Erreur suppression avis {review_id}: {e}")
            return False
    
    async def get_artisan_rating_stats(self, artisan_id: str):
        """Récupère les statistiques de notation d'un artisan"""
        try:
            pipeline = [
                {"$match": {"artisan_id": artisan_id}},
                {"$group": {
                    "_id": "$artisan_id",
                    "average_rating": {"$avg": "$rating"},
                    "review_count": {"$sum": 1},
                    "rating_breakdown": {
                        "$push": "$rating"
                    }
                }}
            ]
            
            cursor = self.collection.aggregate(pipeline)
            result = await cursor.to_list(length=1)
            
            if result:
                stats = result[0]
                ratings = stats["rating_breakdown"]
                
                # Calculer la répartition par étoile
                rating_distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
                for rating in ratings:
                    if 1 <= rating <= 5:
                        rating_distribution[rating] += 1
                
                return {
                    "artisan_id": artisan_id,
                    "average_rating": round(stats["average_rating"], 1),
                    "review_count": stats["review_count"],
                    "rating_distribution": rating_distribution
                }
            
            return {
                "artisan_id": artisan_id,
                "average_rating": 0,
                "review_count": 0,
                "rating_distribution": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            }
            
        except Exception as e:
            print(f"❌ Erreur statistiques avis artisan {artisan_id}: {e}")
            return {
                "artisan_id": artisan_id,
                "average_rating": 0,
                "review_count": 0,
                "rating_distribution": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            }