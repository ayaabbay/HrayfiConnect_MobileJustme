from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from typing import List, Optional
from bson import ObjectId
from datetime import datetime, timezone

from app.models.booking_models import BookingManager
from app.models.user_models import UserManager
from app.schemas.booking_schemas import (
    BookingCreate, BookingUpdate, BookingResponse, 
    BookingDetailedResponse, BookingStats, BookingFilter,
    BookingStatus
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_database

router = APIRouter()

def get_booking_manager():
    database = get_database()
    return BookingManager(database)

def get_user_manager():
    database = get_database()
    return UserManager(database)

# Routes Client
@router.post("/", response_model=BookingResponse)
async def create_booking(
    booking_data: BookingCreate,
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Crée une nouvelle réservation (Client seulement)
    """
    if current_user.get("user_type") != "client":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients peuvent créer des réservations"
        )
    
    # Vérifier que l'artisan existe
    artisan = await user_manager.find_user_by_id(booking_data.artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artisan non trouvé"
        )
    
    # Vérifier que le client est bien celui connecté
    if booking_data.client_id != str(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez créer des réservations que pour vous-même"
        )
    
    # Créer la réservation
    booking_dict = booking_data.model_dump()
    
    try:
        created_booking = await booking_manager.create_booking(booking_dict)
        created_booking["id"] = str(created_booking["_id"])
        
        return BookingResponse(**created_booking)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la création de la réservation: {str(e)}"
        )

@router.get("/", response_model=List[BookingDetailedResponse])
async def get_all_bookings(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),  # Limite augmentée pour les admins
    booking_status: Optional[BookingStatus] = Query(None, alias="status"),
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Récupère toutes les réservations (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent voir toutes les réservations"
        )
    
    query = {}
    
    # Filtrer par statut si spécifié
    if booking_status:
        query["status"] = booking_status
    
    bookings = await booking_manager.get_bookings_with_details(query, skip, limit)
    
    # Convertir ObjectId en string pour les bookings
    for booking in bookings:
        booking["id"] = str(booking["_id"])
    
    return [BookingDetailedResponse(**booking) for booking in bookings]

@router.get("/my-bookings", response_model=List[BookingDetailedResponse])
async def get_my_bookings(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    booking_status: Optional[BookingStatus] = Query(None, alias="status"),
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Récupère les réservations de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    query = {}
    if user_type == "client":
        query["client_id"] = user_id
    elif user_type == "artisan":
        query["artisan_id"] = user_id
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Type d'utilisateur non supporté"
        )
    
    # Filtrer par statut si spécifié
    if booking_status:
        query["status"] = booking_status
    
    bookings = await booking_manager.get_bookings_with_details(query, skip, limit)
    
    # Convertir ObjectId en string pour les bookings
    for booking in bookings:
        booking["id"] = str(booking["_id"])
    
    return [BookingDetailedResponse(**booking) for booking in bookings]

@router.get("/{booking_id}", response_model=BookingDetailedResponse)
async def get_booking(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Récupère une réservation spécifique
    """
    try:
        # Récupérer directement les détails avec la nouvelle méthode
        detailed_bookings = await booking_manager.get_bookings_with_details(
            {"_id": ObjectId(booking_id)}, 0, 1
        )
        
        if not detailed_bookings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Réservation non trouvée"
            )
        
        detailed_booking = detailed_bookings[0]
        
        # Vérifier les permissions
        user_id = str(current_user["_id"])
        if detailed_booking["client_id"] != user_id and detailed_booking["artisan_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à cette réservation"
            )
        
        # Conversion de l'ID principal
        detailed_booking["id"] = str(detailed_booking["_id"])
        
        return BookingDetailedResponse(**detailed_booking)
        
    except Exception as e:
        print(f"❌ Erreur récupération réservation {booking_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération de la réservation"
        )

@router.put("/{booking_id}", response_model=BookingResponse)
async def update_booking(
    booking_id: str,
    booking_update: BookingUpdate,
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Met à jour une réservation
    - Client: peut modifier description, address, urgency
    - Artisan: peut modifier scheduled_date et status
    - Admin: peut tout modifier
    """
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier les permissions et définir les champs modifiables
    update_data = booking_update.model_dump(exclude_unset=True)
    
    if user_type == "client":
        # Le client ne peut modifier que ses propres réservations
        if booking["client_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous ne pouvez modifier que vos propres réservations"
            )
        
        # Le client ne peut modifier que certains champs
        allowed_fields = ["description", "urgency", "address"]
        update_data = {k: v for k, v in update_data.items() if k in allowed_fields}
        
    elif user_type == "artisan":
        # L'artisan ne peut modifier que ses propres réservations
        if booking["artisan_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous ne pouvez modifier que vos propres réservations"
            )
        
        # L'artisan ne peut modifier que la date et le statut
        allowed_fields = ["scheduled_date", "status"]
        update_data = {k: v for k, v in update_data.items() if k in allowed_fields}
        
    elif user_type == "admin":
        # L'admin peut tout modifier
        pass
        
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Type d'utilisateur non autorisé"
        )
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucune donnée valide fournie pour la mise à jour"
        )
    
    updated_booking = await booking_manager.update_booking(booking_id, update_data)
    if not updated_booking:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour de la réservation"
        )
    
    updated_booking["id"] = str(updated_booking["_id"])
    return BookingResponse(**updated_booking)

# REMPLACEMENT DES ROUTES PATCH PAR PUT AVEC BODY
@router.put("/{booking_id}/schedule")
async def update_booking_schedule(
    booking_id: str,
    scheduled_date: datetime = Body(..., embed=True),
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Met à jour uniquement la date d'une réservation (Artisan seulement)
    """
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    if user_type != "artisan" or booking["artisan_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent modifier la date de leurs réservations"
        )
    
    # Vérification de la date avec gestion du timezone
    if scheduled_date.tzinfo is None:
        scheduled_date = scheduled_date.replace(tzinfo=timezone.utc)
    
    now = datetime.now(timezone.utc)
    if scheduled_date < now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La date de réservation doit être dans le futur"
        )
    
    updated_booking = await booking_manager.update_booking_schedule(booking_id, scheduled_date)
    if not updated_booking:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour de la date"
        )
    
    updated_booking["id"] = str(updated_booking["_id"])
    return {
        "message": "Date de réservation mise à jour avec succès",
        "booking": BookingResponse(**updated_booking)
    }

@router.put("/{booking_id}/status")
async def update_booking_status(
    booking_id: str,
    booking_status: BookingStatus = Body(..., embed=True, alias="status"),
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Met à jour uniquement le statut d'une réservation (Artisan seulement)
    """
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    if user_type != "artisan" or booking["artisan_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent modifier le statut de leurs réservations"
        )
    
    updated_booking = await booking_manager.update_booking_status(booking_id, booking_status)
    if not updated_booking:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour du statut"
        )
    
    updated_booking["id"] = str(updated_booking["_id"])
    return {
        "message": f"Statut de la réservation mis à jour: {booking_status}",
        "booking": BookingResponse(**updated_booking)
    }

@router.delete("/{booking_id}")
async def delete_booking(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Supprime une réservation (Client ou Admin seulement)
    """
    booking = await booking_manager.find_booking_by_id(booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier les permissions
    if user_type == "client":
        if booking["client_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous ne pouvez supprimer que vos propres réservations"
            )
    elif user_type != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients et administrateurs peuvent supprimer des réservations"
        )
    
    success = await booking_manager.delete_booking(booking_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la suppression de la réservation"
        )
    
    return {"message": "Réservation supprimée avec succès"}

@router.get("/stats/me", response_model=BookingStats)
async def get_my_booking_stats(
    current_user: dict = Depends(get_current_user),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Récupère les statistiques de réservation de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    if user_type == "client":
        query = {"client_id": user_id}
    elif user_type == "artisan":
        query = {"artisan_id": user_id}
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Type d'utilisateur non supporté"
        )
    
    # Récupérer toutes les réservations pour calculer les stats
    bookings = await booking_manager.get_bookings_with_details(query, 0, 1000)
    
    stats = {
        "total": len(bookings),
        "pending": 0,
        "confirmed": 0,
        "in_progress": 0,
        "completed": 0,
        "cancelled": 0
    }
    
    for booking in bookings:
        status = booking.get("status")
        if status in stats:
            stats[status] += 1
    
    return BookingStats(**stats)

# Route de debug pour voir les routes disponibles
@router.get("/debug/routes")
async def debug_routes():
    """Affiche toutes les routes disponibles"""
    routes = []
    for route in router.routes:
        route_info = {
            "path": getattr(route, 'path', 'N/A'),
            "name": getattr(route, 'name', 'N/A'),
        }
        if hasattr(route, 'methods'):
            route_info["methods"] = list(route.methods)
        else:
            route_info["methods"] = []
        routes.append(route_info)
    return routes