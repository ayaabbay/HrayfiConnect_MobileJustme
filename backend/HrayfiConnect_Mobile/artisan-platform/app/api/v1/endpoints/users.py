from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from bson import ObjectId

from app.models.user_models import UserManager
from app.schemas.user_schemas import (
    UserUpdate, ClientUpdate, ArtisanUpdate, AdminUpdate,
    ClientResponse, ArtisanResponse, AdminResponse, UserProfile
)
from app.api.v1.endpoints.auth import get_current_user, get_user_manager

router = APIRouter()

# Routes pour les clients
@router.get("/clients/", response_model=List[ClientResponse])
async def list_clients(
    skip: int = 0, 
    limit: int = 100,
    user_manager: UserManager = Depends(get_user_manager)
):
    clients = await user_manager.list_users("client", skip, limit)
    
    # Convertir ObjectId en string pour la réponse
    for client in clients:
        client["id"] = str(client["_id"])
    
    return [ClientResponse(**client) for client in clients]

@router.get("/clients/{client_id}", response_model=ClientResponse)
async def get_client(
    client_id: str,
    user_manager: UserManager = Depends(get_user_manager)
):
    client = await user_manager.find_user_by_id(client_id)
    if not client or client.get("user_type") != "client":
        raise HTTPException(status_code=404, detail="Client not found")
    
    client["id"] = str(client["_id"])
    return ClientResponse(**client)

@router.put("/clients/{client_id}", response_model=ClientResponse)
async def update_client(
    client_id: str, 
    client_update: ClientUpdate,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    # Vérifier que l'utilisateur modifie son propre profil ou est admin
    if str(current_user["_id"]) != client_id and current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    client = await user_manager.find_user_by_id(client_id)
    if not client or client.get("user_type") != "client":
        raise HTTPException(status_code=404, detail="Client not found")
    
    update_data = client_update.model_dump(exclude_unset=True)
    updated_client = await user_manager.update_user(client_id, update_data)
    
    updated_client["id"] = str(updated_client["_id"])
    return ClientResponse(**updated_client)

@router.delete("/clients/{client_id}")
async def delete_client(
    client_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    # Seul l'admin ou l'utilisateur lui-même peut supprimer
    if str(current_user["_id"]) != client_id and current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    success = await user_manager.delete_user(client_id)
    if not success:
        raise HTTPException(status_code=404, detail="Client not found")
    
    return {"message": "Client deleted successfully"}

# Routes pour les artisans
@router.get("/artisans/", response_model=List[ArtisanResponse])
async def list_artisans(
    skip: int = 0, 
    limit: int = 100,
    trade: Optional[str] = None,
    verified: Optional[bool] = None,
    user_manager: UserManager = Depends(get_user_manager)
):
    if trade:
        artisans = await user_manager.find_artisans_by_trade(trade, skip, limit)
    else:
        artisans = await user_manager.list_users("artisan", skip, limit)
    
    # Filtrer les artisans inactifs (ne montrer que les artisans actifs)
    artisans = [a for a in artisans if a.get("is_active", True) is not False]
    
    # Filtrer par statut de vérification si spécifié
    if verified is not None:
        artisans = [a for a in artisans if a.get("is_verified") == verified]
    
    # Convertir ObjectId en string pour la réponse
    for artisan in artisans:
        artisan["id"] = str(artisan["_id"])
    
    try:
        return [ArtisanResponse(**artisan) for artisan in artisans]
    except Exception as e:
        print(f"Erreur lors de la sérialisation des artisans: {e}")
        print(f"Nombre d'artisans: {len(artisans)}")
        if artisans:
            print(f"Premier artisan: {artisans[0]}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des artisans: {str(e)}"
        )

@router.get("/artisans/{artisan_id}", response_model=ArtisanResponse)
async def get_artisan(
    artisan_id: str,
    user_manager: UserManager = Depends(get_user_manager)
):
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    artisan["id"] = str(artisan["_id"])
    return ArtisanResponse(**artisan)

@router.put("/artisans/{artisan_id}", response_model=ArtisanResponse)
async def update_artisan(
    artisan_id: str, 
    artisan_update: ArtisanUpdate,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    # Vérifier que l'utilisateur modifie son propre profil ou est admin
    if str(current_user["_id"]) != artisan_id and current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    update_data = artisan_update.model_dump(exclude_unset=True)
    updated_artisan = await user_manager.update_user(artisan_id, update_data)
    
    updated_artisan["id"] = str(updated_artisan["_id"])
    return ArtisanResponse(**updated_artisan)

@router.put("/artisans/{artisan_id}/verify")
async def verify_artisan(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    # Seul l'admin peut vérifier un artisan
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin permissions required"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    await user_manager.update_user(artisan_id, {"is_verified": True})
    
    return {"message": "Artisan verified successfully"}

@router.put("/artisans/{artisan_id}/disable")
async def disable_artisan(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Désactive un artisan (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin permissions required"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    await user_manager.update_user(artisan_id, {"is_active": False})
    
    return {"message": "Artisan désactivé avec succès"}

@router.put("/artisans/{artisan_id}/enable")
async def enable_artisan(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Réactive un artisan (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin permissions required"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    await user_manager.update_user(artisan_id, {"is_active": True})
    
    return {"message": "Artisan réactivé avec succès"}

@router.delete("/artisans/{artisan_id}")
async def delete_artisan(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Supprime un artisan (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin permissions required"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    success = await user_manager.delete_user(artisan_id)
    if not success:
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    return {"message": "Artisan supprimé avec succès"}

# Route pour récupérer le profil utilisateur
@router.get("/profile", response_model=UserProfile)
async def get_user_profile(current_user: dict = Depends(get_current_user)):
    print("🖼️ DEBUG - Photo de profil:", current_user.get("profile_picture"))
    user_type = current_user["user_type"]
    profile_data = {}
    
    if user_type == "client":
        profile_data = {
            "first_name": current_user.get("first_name"),
            "last_name": current_user.get("last_name"),
            "address": current_user.get("address"),
            "profile_picture": current_user.get("profile_picture") 
        }
    elif user_type == "artisan":
        profile_data = {
            "first_name": current_user.get("first_name"),
            "last_name": current_user.get("last_name"),
            "company_name": current_user.get("company_name"),
            "trade": current_user.get("trade"),
            "description": current_user.get("description"),
            "years_of_experience": current_user.get("years_of_experience"),
            "is_verified": current_user.get("is_verified", False),
            "certifications": current_user.get("certifications", []),
            "profile_picture": current_user.get("profile_picture"),
            "portfolio": current_user.get("portfolio", []),
            "address": current_user.get("address"),
        }
    elif user_type == "admin":
        profile_data = {
            "first_name": current_user.get("first_name"),
            "last_name": current_user.get("last_name"),
            "role": current_user.get("role"),
            "permissions": current_user.get("permissions", [])
        }
    
    return UserProfile(
        id=str(current_user["_id"]),
        email=current_user["email"],
        phone=current_user["phone"],
        user_type=user_type,
        profile_data=profile_data
    )
# Ajoutez ces routes après les routes existantes

@router.get("/artisans/search")
async def search_artisans(
    trade: Optional[str] = None,
    location: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Recherche d'artisans par métier et/ou localisation
    """
    if trade and location:
        # Recherche combinée
        artisans_by_trade = await user_manager.find_artisans_by_trade(trade, skip, limit)
        artisans_by_location = await user_manager.find_artisans_by_location(location, skip, limit)
        
        # Combiner et dédupliquer
        combined_artisans = artisans_by_trade + artisans_by_location
        unique_artisans = {}
        for artisan in combined_artisans:
            artisan_id = str(artisan["_id"])
            if artisan_id not in unique_artisans:
                unique_artisans[artisan_id] = artisan
        
        artisans = list(unique_artisans.values())
    elif trade:
        artisans = await user_manager.find_artisans_by_trade(trade, skip, limit)
    elif location:
        artisans = await user_manager.find_artisans_by_location(location, skip, limit)
    else:
        artisans = await user_manager.list_users("artisan", skip, limit, active_only=True)
    
    # Filtrer les artisans inactifs (double vérification)
    artisans = [a for a in artisans if a.get("is_active", True) is not False]
    
    # Convertir ObjectId en string pour la réponse
    for artisan in artisans:
        artisan["id"] = str(artisan["_id"])
    
    try:
        return [ArtisanResponse(**artisan) for artisan in artisans]
    except Exception as e:
        print(f"Erreur lors de la sérialisation des artisans (search): {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la recherche des artisans: {str(e)}"
        )

@router.put("/artisans/{artisan_id}/verify")
async def verify_artisan(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Vérifie un artisan (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin permissions required"
        )
    
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(status_code=404, detail="Artisan not found")
    
    # Vérifier que l'artisan a tous les documents requis
    identity_docs = artisan.get("identity_document", {})
    if not identity_docs.get("cin_recto") or not identity_docs.get("cin_verso") or not identity_docs.get("photo"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'artisan doit fournir tous les documents d'identité avant d'être vérifié"
        )
    
    await user_manager.update_user(artisan_id, {"is_verified": True})
    
    return {"message": "Artisan vérifié avec succès"}