from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

class MongoDB:
    client: AsyncIOMotorClient = None
    database = None

mongodb = MongoDB()

async def connect_to_mongo():
    """Établir la connexion à MongoDB"""
    mongodb.client = AsyncIOMotorClient(settings.MONGODB_URI)
    mongodb.database = mongodb.client[settings.MONGODB_DB]
    print("✅ Connecté à MongoDB")

async def close_mongo_connection():
    """Fermer la connexion à MongoDB"""
    if mongodb.client:
        mongodb.client.close()
        print("✅ Déconnecté de MongoDB")

def get_database():
    return mongodb.database

def get_collection(collection_name: str):
    return mongodb.database[collection_name]