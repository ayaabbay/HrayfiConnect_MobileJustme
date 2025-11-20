# create_admin.py
import asyncio
import sys
import os

# Ajouter le chemin de l'application
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import connect_to_mongo, close_mongo_connection
from app.models.user_models import UserManager, hash_password
from app.core.config import settings

async def create_admin():
    """Crée un compte administrateur"""
    try:
        # Connexion à la base de données
        await connect_to_mongo()
        
        # Initialiser le UserManager
        from app.core.database import get_database
        user_manager = UserManager(get_database())
        
        # Données de l'admin
        admin_data = {
            "email": "admin@hrayficonnect.com",
            "phone": "+33123456780",
            "password": "AdminPassword123!",
            "first_name": "Admin",
            "last_name": "System",
            "role": "superadmin",
            "permissions": ["all"],
            "user_type": "admin"
        }
        
        # Vérifier si l'admin existe déjà
        existing_admin = await user_manager.find_user_by_email(admin_data["email"])
        if existing_admin:
            print("❌ Un admin avec cet email existe déjà.")
            return
        
        # Créer l'admin
        admin_dict = admin_data.copy()
        created_admin = await user_manager.create_user(admin_dict)
        
        print("✅ Compte administrateur créé avec succès!")
        print(f"📧 Email: {admin_data['email']}")
        print(f"🔑 Mot de passe: {admin_data['password']}")
        print(f"👤 ID: {created_admin['_id']}")
        
    except Exception as e:
        print(f"❌ Erreur lors de la création de l'admin: {e}")
    finally:
        await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(create_admin())