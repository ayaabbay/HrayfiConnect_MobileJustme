from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from bson import ObjectId
import bcrypt

# Utilitaires pour le hashage des mots de passe
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# Classes pour la manipulation des données
class UserManager:
    def __init__(self, database):
        self.collection = database["users"]
    
    async def create_user(self, user_data: dict):
        # Hash du mot de passe
        user_data["password"] = hash_password(user_data["password"])
        user_data["created_at"] = datetime.utcnow()
        
        result = await self.collection.insert_one(user_data)
        user_data["_id"] = result.inserted_id
        return user_data
    
    async def find_user_by_email(self, email: str):
        return await self.collection.find_one({"email": email})
    
    async def find_user_by_id(self, user_id: str):
        try:
            return await self.collection.find_one({"_id": ObjectId(user_id)})
        except:
            return None
    
    async def update_user(self, user_id: str, update_data: dict):
        # Ne pas permettre la modification du mot de passe directement
        if "password" in update_data and update_data["password"]:
            update_data["password"] = hash_password(update_data["password"])
        
        await self.collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": update_data}
        )
        return await self.find_user_by_id(user_id)
    
    async def delete_user(self, user_id: str):
        result = await self.collection.delete_one({"_id": ObjectId(user_id)})
        return result.deleted_count > 0
    
    async def list_users(self, user_type: str = None, skip: int = 0, limit: int = 100, active_only: bool = True):
        query = {}
        if user_type:
            query["user_type"] = user_type
        # Filtrer les utilisateurs inactifs si active_only est True
        if active_only:
            query["is_active"] = {"$ne": False}  # Inclure les utilisateurs actifs ou sans champ is_active
        
        cursor = self.collection.find(query).skip(skip).limit(limit)
        users = []
        async for user in cursor:
            users.append(user)
        return users
    
    async def find_artisans_by_trade(self, trade: str, skip: int = 0, limit: int = 100):
        query = {
            "user_type": "artisan",
            "trade": {"$regex": trade, "$options": "i"},
            "is_active": {"$ne": False}  # Filtrer les artisans inactifs
        }
        cursor = self.collection.find(query).skip(skip).limit(limit)
        artisans = []
        async for artisan in cursor:
            artisans.append(artisan)
        return artisans

    async def find_artisans_by_location(self, location: str, skip: int = 0, limit: int = 100):
        """Trouve les artisans par localisation"""
        query = {
            "user_type": "artisan",
            "address": {"$regex": location, "$options": "i"},
            "is_active": {"$ne": False}  # Filtrer les artisans inactifs
        }
        cursor = self.collection.find(query).skip(skip).limit(limit)
        artisans = []
        async for artisan in cursor:
            artisans.append(artisan)
        return artisans

class PasswordResetManager:
    def __init__(self, database):
        self.collection = database["password_resets"]
    
    async def create_reset_code(self, email: str, code: str):
        """Crée un code de réinitialisation"""
        expires_at = datetime.utcnow() + timedelta(minutes=2)
        
        reset_data = {
            "email": email,
            "code": code,
            "expires_at": expires_at,
            "used": False,
            "created_at": datetime.utcnow()
        }
        
        # Supprimer les anciens codes pour cet email
        await self.collection.delete_many({"email": email})
        
        # Insérer le nouveau code
        result = await self.collection.insert_one(reset_data)
        return result.inserted_id
    
    async def verify_reset_code(self, email: str, code: str):
        """Vérifie si le code est valide"""
        reset_data = await self.collection.find_one({
            "email": email,
            "code": code,
            "used": False
        })
        
        if not reset_data:
            return False
        
        # Vérifier l'expiration
        if datetime.utcnow() > reset_data["expires_at"]:
            await self.collection.delete_one({"_id": reset_data["_id"]})
            return False
        
        return reset_data
    
    async def mark_code_as_used(self, reset_id):
        """Marque un code comme utilisé"""
        await self.collection.update_one(
            {"_id": reset_id},
            {"$set": {"used": True, "used_at": datetime.utcnow()}}
        )
    
    async def cleanup_expired_codes(self):
        """Nettoie les codes expirés"""
        result = await self.collection.delete_many({
            "expires_at": {"$lt": datetime.utcnow()}
        })
        return result.deleted_count