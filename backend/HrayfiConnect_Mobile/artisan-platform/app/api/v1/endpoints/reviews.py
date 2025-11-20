from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId

from app.models.review_models import ReviewManager
from app.models.booking_models import BookingManager
from app.models.user_models import UserManager
from app.schemas.review_schemas import (
    ReviewCreate, ReviewUpdate, ReviewResponse, 
    ReviewDetailedResponse, RatingStats
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_database

router = APIRouter()

def get_review_manager():
    database = get_database()
    return ReviewManager(database)

def get_booking_manager():
    database = get_database()
    return BookingManager(database)

def get_user_manager():
    database = get_database()
    return UserManager(database)

@router.post("/", response_model=ReviewResponse)
async def create_review(
    review_data: ReviewCreate,
    current_user: dict = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager),
    booking_manager: BookingManager = Depends(get_booking_manager)
):
    """
    Crée un nouvel avis (Client seulement)
    Conditions:
    - Le client doit avoir une réservation COMPLÉTÉE avec l'artisan
    - Le client ne peut laisser qu'un seul avis par réservation
    """
    if current_user.get("user_type") != "client":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients peuvent créer des avis"
        )
    
    # Vérifier que le client est bien celui connecté
    if review_data.client_id != str(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez créer des avis que pour vous-même"
        )
    
    # Vérifier que la réservation existe et est complétée
    booking = await booking_manager.find_booking_by_id(review_data.booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Réservation non trouvée"
        )
    
    if booking.get("status") != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vous ne pouvez laisser un avis que pour les réservations complétées"
        )
    
    if booking.get("client_id") != review_data.client_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cette réservation ne vous appartient pas"
        )
    
    if booking.get("artisan_id") != review_data.artisan_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'artisan spécifié ne correspond pas à la réservation"
        )
    
    # Créer l'avis
    review_dict = review_data.model_dump()
    
    try:
        created_review = await review_manager.create_review(review_dict)
        created_review["id"] = str(created_review["_id"])
        
        return ReviewResponse(**created_review)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la création de l'avis: {str(e)}"
        )

@router.get("/artisans/{artisan_id}", response_model=List[ReviewDetailedResponse])
async def get_artisan_reviews(
    artisan_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    min_rating: Optional[int] = Query(None, ge=0, le=5),
    max_rating: Optional[int] = Query(None, ge=0, le=5),
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Récupère tous les avis d'un artisan
    """
    query = {"artisan_id": artisan_id}
    
    # Filtrer par note si spécifié
    if min_rating is not None or max_rating is not None:
        query["rating"] = {}
        if min_rating is not None:
            query["rating"]["$gte"] = min_rating
        if max_rating is not None:
            query["rating"]["$lte"] = max_rating
    
    reviews = await review_manager.get_reviews_with_details(query, skip, limit)
    
    # Convertir ObjectId en string
    for review in reviews:
        review["id"] = str(review["_id"])
    
    return [ReviewDetailedResponse(**review) for review in reviews]

@router.get("/my-reviews", response_model=List[ReviewDetailedResponse])
async def get_my_reviews(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Récupère les avis de l'utilisateur connecté
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
    
    reviews = await review_manager.get_reviews_with_details(query, skip, limit)
    
    # Convertir ObjectId en string
    for review in reviews:
        review["id"] = str(review["_id"])
    
    return [ReviewDetailedResponse(**review) for review in reviews]

@router.get("/{review_id}", response_model=ReviewDetailedResponse)
async def get_review(
    review_id: str,
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Récupère un avis spécifique
    """
    reviews = await review_manager.get_reviews_with_details(
        {"_id": ObjectId(review_id)}, 0, 1
    )
    
    if not reviews:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Avis non trouvé"
        )
    
    review = reviews[0]
    review["id"] = str(review["_id"])
    
    return ReviewDetailedResponse(**review)

@router.put("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: str,
    review_update: ReviewUpdate,
    current_user: dict = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Met à jour un avis (Client propriétaire seulement)
    """
    review = await review_manager.find_review_by_id(review_id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Avis non trouvé"
        )
    
    # Vérifier que l'utilisateur est le propriétaire de l'avis
    if review["client_id"] != str(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez modifier que vos propres avis"
        )
    
    update_data = review_update.model_dump(exclude_unset=True)
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucune donnée valide fournie pour la mise à jour"
        )
    
    updated_review = await review_manager.update_review(review_id, update_data)
    if not updated_review:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour de l'avis"
        )
    
    updated_review["id"] = str(updated_review["_id"])
    return ReviewResponse(**updated_review)

@router.delete("/{review_id}")
async def delete_review(
    review_id: str,
    current_user: dict = Depends(get_current_user),
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Supprime un avis (Client propriétaire ou Admin)
    """
    review = await review_manager.find_review_by_id(review_id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Avis non trouvé"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier les permissions
    if user_type == "client":
        if review["client_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous ne pouvez supprimer que vos propres avis"
            )
    elif user_type != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients et administrateurs peuvent supprimer des avis"
        )
    
    success = await review_manager.delete_review(review_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la suppression de l'avis"
        )
    
    return {"message": "Avis supprimé avec succès"}

@router.get("/artisans/{artisan_id}/stats", response_model=RatingStats)
async def get_artisan_rating_stats(
    artisan_id: str,
    review_manager: ReviewManager = Depends(get_review_manager)
):
    """
    Récupère les statistiques de notation d'un artisan
    """
    stats = await review_manager.get_artisan_rating_stats(artisan_id)
    return RatingStats(**stats)