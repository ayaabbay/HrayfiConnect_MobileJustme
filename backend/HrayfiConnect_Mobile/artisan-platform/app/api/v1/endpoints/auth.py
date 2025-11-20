from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime, timedelta
from jose import JWTError, jwt
from bson import ObjectId

from app.models.user_models import UserManager, verify_password, hash_password, PasswordResetManager
from app.schemas.user_schemas import (
    LoginRequest, ClientCreate, ArtisanCreate, 
    ClientResponse, ArtisanResponse, AdminResponse,
    ForgotPasswordRequest, VerifyResetCodeRequest, ResetPasswordRequest
)
from app.core.config import settings
from app.core.database import get_database
from app.utils.email_service import email_service

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def get_user_manager():
    database = get_database()
    return UserManager(database)

def get_reset_manager():
    database = get_database()
    return PasswordResetManager(database)

def create_access_token(data: dict, expires_delta: timedelta = None):
    """Crée un token JWT"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    user_manager: UserManager = Depends(get_user_manager)
):
    """Récupère l'utilisateur actuel à partir du token JWT"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        user_type: str = payload.get("user_type")
        email: str = payload.get("email")
        
        if user_id is None or user_type is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = await user_manager.find_user_by_id(user_id)
    if user is None:
        raise credentials_exception
    
    return user

@router.post("/register/client", response_model=ClientResponse)
async def register_client(
    client_data: ClientCreate,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Inscription d'un nouveau client
    """
    # Vérifier si l'email existe déjà
    existing_user = await user_manager.find_user_by_email(client_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email déjà utilisé"
        )
    
    # Créer le client
    client_dict = client_data.model_dump()
    client_dict["user_type"] = "client"
    created_client = await user_manager.create_user(client_dict)
    
    # Convertir ObjectId en string pour la réponse
    created_client["id"] = str(created_client["_id"])
    return ClientResponse(**created_client)

@router.post("/register/artisan", response_model=ArtisanResponse)
async def register_artisan(
    artisan_data: ArtisanCreate,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Inscription d'un nouvel artisan
    """
    # Vérifier si l'email existe déjà
    existing_user = await user_manager.find_user_by_email(artisan_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email déjà utilisé"
        )
    
    # Créer l'artisan
    artisan_dict = artisan_data.model_dump()
    artisan_dict["user_type"] = "artisan"
    created_artisan = await user_manager.create_user(artisan_dict)
    
    # Convertir ObjectId en string pour la réponse
    created_artisan["id"] = str(created_artisan["_id"])
    return ArtisanResponse(**created_artisan)

@router.post("/login")
async def login(
    login_data: LoginRequest,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Connexion d'un utilisateur avec email et mot de passe
    """
    user = await user_manager.find_user_by_email(login_data.email)
    
    if not user or not verify_password(login_data.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Générer le token JWT
    access_token = create_access_token(
        data={
            "sub": str(user["_id"]), 
            "user_type": user["user_type"], 
            "email": user["email"]
        }
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_type": user["user_type"],
        "user_id": str(user["_id"]),
        "email": user["email"]
    }

@router.get("/me")
async def read_users_me(current_user: dict = Depends(get_current_user)):
    """
    Récupère le profil de l'utilisateur connecté
    """
    user_data = dict(current_user)
    user_data["id"] = str(user_data["_id"])
    
    # Retourner la réponse formatée selon le type d'utilisateur
    if current_user["user_type"] == "client":
        return ClientResponse(**user_data)
    elif current_user["user_type"] == "artisan":
        return ArtisanResponse(**user_data)
    elif current_user["user_type"] == "admin":
        return AdminResponse(**user_data)

@router.post("/refresh")
async def refresh_token(current_user: dict = Depends(get_current_user)):
    """
    Rafraîchit le token JWT
    """
    access_token = create_access_token(
        data={
            "sub": str(current_user["_id"]), 
            "user_type": current_user["user_type"], 
            "email": current_user["email"]
        }
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.post("/logout")
async def logout():
    """
    Déconnexion de l'utilisateur
    Note: Avec JWT, la déconnexion est gérée côté client en supprimant le token
    """
    return {
        "message": "Déconnexion réussie",
        "detail": "Supprimez le token côté client"
    }

# NOUVELLE LOGIQUE DE RÉINITIALISATION AVEC CODE (CORRIGÉE)

@router.post("/forgot-password")
async def forgot_password(
    request: ForgotPasswordRequest,  # ✅ Correction: Utiliser le schéma Pydantic
    user_manager: UserManager = Depends(get_user_manager),
    reset_manager: PasswordResetManager = Depends(get_reset_manager)
):
    """
    Étape 1: Demande de réinitialisation - Envoie un code par email
    """
    email = request.email  # ✅ Récupérer l'email depuis le schéma
    
    user = await user_manager.find_user_by_email(email)
    
    # 🔒 SECURITE: On ne révèle jamais si un email existe ou non
    if not user:
        return {
            "message": "Si l'email existe, un code de sécurité a été envoyé"
        }
    
    # Générer un code de sécurité
    reset_code = email_service.generate_reset_code()
    
    # Sauvegarder le code en base de données
    await reset_manager.create_reset_code(email, reset_code)
    
    # Envoyer le code par email
    email_sent = await email_service.send_reset_code(email, reset_code)
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'envoi de l'email"
        )
    
    return {
        "message": "Si l'email existe, un code de sécurité a été envoyé",
        "email": email,  # Pour le développement, en production on ne renvoie pas l'email
        "code_expires_in": "2 minutes"
    }

@router.post("/verify-reset-code")
async def verify_reset_code(
    request: VerifyResetCodeRequest,  # ✅ Correction: Utiliser le schéma Pydantic
    reset_manager: PasswordResetManager = Depends(get_reset_manager)
):
    """
    Étape 2: Vérification du code de sécurité
    """
    email = request.email
    code = request.code
    
    reset_data = await reset_manager.verify_reset_code(email, code)
    
    if not reset_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré"
        )
    
    # Marquer le code comme utilisé
    await reset_manager.mark_code_as_used(reset_data["_id"])
    
    # Générer un token temporaire pour autoriser la réinitialisation
    reset_token = create_access_token(
        data={
            "sub": "password_reset",
            "email": email,
            "purpose": "password_reset"
        },
        expires_delta=timedelta(minutes=5)
    )
    
    return {
        "message": "Code vérifié avec succès",
        "reset_token": reset_token,
        "email": email
    }

@router.post("/reset-password")
async def reset_password(
    request: ResetPasswordRequest,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Étape 3: Réinitialisation du mot de passe avec le token de réinitialisation
    """
    reset_token = request.reset_token
    new_password = request.new_password
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Token de réinitialisation invalide ou expiré"
    )
    
    try:
        payload = jwt.decode(reset_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("email")
        purpose: str = payload.get("purpose")
        
        if email is None or purpose != "password_reset":
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Mettre à jour le mot de passe
    user = await user_manager.find_user_by_email(email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    # ✅ CORRECTION: Ne pas hacher le mot de passe ici, laisser update_user le faire
    await user_manager.update_user(str(user["_id"]), {"password": new_password})
    
    return {
        "message": "Mot de passe réinitialisé avec succès",
        "email": email
    }

@router.get("/check-email/{email}")
async def check_email_availability(
    email: str,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Vérifie si un email est déjà utilisé
    """
    existing_user = await user_manager.find_user_by_email(email)
    
    return {
        "email": email,
        "available": existing_user is None,
        "exists": existing_user is not None
    }

@router.get("/test")
async def auth_test():
    """
    Endpoint de test pour l'authentification
    """
    return {
        "message": "Auth endpoint works!",
        "timestamp": datetime.utcnow().isoformat()
    }
# Ajoutez cette fonction à la fin du fichier auth.py

async def get_current_user_websocket(token: str):
    """
    Vérifie l'authentification pour les WebSockets
    """
    from app.core.config import settings
    from jose import JWTError, jwt
    from fastapi import HTTPException, status
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        user_type: str = payload.get("user_type")
        email: str = payload.get("email")
        
        if user_id is None or user_type is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    database = get_database()
    user_manager = UserManager(database)
    user = await user_manager.find_user_by_id(user_id)
    
    if user is None:
        raise credentials_exception
    
    return user