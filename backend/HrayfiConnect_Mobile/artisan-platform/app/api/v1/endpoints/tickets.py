from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId

from app.models.ticket_models import TicketManager, TicketStatus, TicketPriority, TicketCategory
from app.models.user_models import UserManager
from app.schemas.ticket_schemas import (
    TicketCreate, TicketUpdate, TicketStatusUpdate, TicketResponseCreate,
    TicketResponse, TicketDetailedResponse, TicketStats
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_database

router = APIRouter()

def get_ticket_manager():
    database = get_database()
    return TicketManager(database)

def get_user_manager():
    database = get_database()
    return UserManager(database)

@router.post("/", response_model=TicketResponse)
async def create_ticket(
    ticket_data: TicketCreate,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Crée un nouveau ticket (Client ou Artisan seulement)
    """
    user_type = current_user.get("user_type")
    if user_type not in ["client", "artisan"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les clients et artisans peuvent créer des tickets"
        )
    
    # Vérifier que l'utilisateur est bien celui connecté
    if ticket_data.user_id != str(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez créer des tickets que pour vous-même"
        )
    
    # Créer le ticket
    ticket_dict = ticket_data.model_dump()
    
    try:
        created_ticket = await ticket_manager.create_ticket(ticket_dict)
        created_ticket["id"] = str(created_ticket["_id"])
        
        return TicketResponse(**created_ticket)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la création du ticket: {str(e)}"
        )

@router.get("/my-tickets", response_model=List[TicketDetailedResponse])
async def get_my_tickets(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status: Optional[TicketStatus] = None,
    category: Optional[TicketCategory] = None,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Récupère les tickets de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    
    query = {"user_id": user_id}
    
    # Filtrer par statut si spécifié
    if status:
        query["status"] = status
    
    # Filtrer par catégorie si spécifié
    if category:
        query["category"] = category
    
    tickets = await ticket_manager.get_tickets_with_details(query, skip, limit)
    
    # Convertir ObjectId en string
    for ticket in tickets:
        ticket["id"] = str(ticket["_id"])
    
    return [TicketDetailedResponse(**ticket) for ticket in tickets]

@router.get("/", response_model=List[TicketDetailedResponse])
async def get_all_tickets(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    ticket_status: Optional[TicketStatus] = Query(None, alias="status"),
    category: Optional[TicketCategory] = None,
    priority: Optional[TicketPriority] = None,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Récupère tous les tickets (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent voir tous les tickets"
        )
    
    query = {}
    
    # Filtrer par statut si spécifié
    if ticket_status:
        query["status"] = ticket_status
    
    # Filtrer par catégorie si spécifié
    if category:
        query["category"] = category
    
    # Filtrer par priorité si spécifié
    if priority:
        query["priority"] = priority
    
    tickets = await ticket_manager.get_tickets_with_details(query, skip, limit)
    
    # Convertir ObjectId en string
    for ticket in tickets:
        ticket["id"] = str(ticket["_id"])
    
    return [TicketDetailedResponse(**ticket) for ticket in tickets]

@router.get("/{ticket_id}", response_model=TicketDetailedResponse)
async def get_ticket(
    ticket_id: str,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Récupère un ticket spécifique
    """
    tickets = await ticket_manager.get_tickets_with_details(
        {"_id": ObjectId(ticket_id)}, 0, 1
    )
    
    if not tickets:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket non trouvé"
        )
    
    ticket = tickets[0]
    
    # Vérifier les permissions
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    if user_type != "admin" and ticket["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à ce ticket"
        )
    
    ticket["id"] = str(ticket["_id"])
    
    return TicketDetailedResponse(**ticket)

@router.put("/{ticket_id}", response_model=TicketResponse)
async def update_ticket(
    ticket_id: str,
    ticket_update: TicketUpdate,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Met à jour un ticket (Propriétaire seulement)
    """
    ticket = await ticket_manager.find_ticket_by_id(ticket_id)
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket non trouvé"
        )
    
    # Vérifier que l'utilisateur est le propriétaire du ticket
    if ticket["user_id"] != str(current_user["_id"]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez modifier que vos propres tickets"
        )
    
    # Empêcher la modification si le ticket est résolu ou fermé
    if ticket["status"] in [TicketStatus.RESOLVED, TicketStatus.CLOSED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Impossible de modifier un ticket résolu ou fermé"
        )
    
    update_data = ticket_update.model_dump(exclude_unset=True)
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucune donnée valide fournie pour la mise à jour"
        )
    
    updated_ticket = await ticket_manager.update_ticket(ticket_id, update_data)
    if not updated_ticket:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour du ticket"
        )
    
    updated_ticket["id"] = str(updated_ticket["_id"])
    return TicketResponse(**updated_ticket)

@router.put("/{ticket_id}/status", response_model=TicketResponse)
async def update_ticket_status(
    ticket_id: str,
    status_update: TicketStatusUpdate,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Met à jour le statut d'un ticket (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent modifier le statut des tickets"
        )
    
    ticket = await ticket_manager.find_ticket_by_id(ticket_id)
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket non trouvé"
        )
    
    update_data = status_update.model_dump(exclude_unset=True)
    
    updated_ticket = await ticket_manager.update_ticket_status(
        ticket_id, 
        status_update.status, 
        status_update.admin_notes
    )
    
    if not updated_ticket:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour du statut"
        )
    
    updated_ticket["id"] = str(updated_ticket["_id"])
    return TicketResponse(**updated_ticket)

@router.post("/{ticket_id}/responses")
async def add_ticket_response(
    ticket_id: str,
    response_data: TicketResponseCreate,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Ajoute une réponse à un ticket
    """
    ticket = await ticket_manager.find_ticket_by_id(ticket_id)
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket non trouvé"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier les permissions
    if user_type != "admin" and ticket["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez répondre qu'à vos propres tickets"
        )
    
    # Préparer les données de réponse
    response_dict = response_data.model_dump()
    response_dict["user_id"] = user_id
    response_dict["user_type"] = user_type
    response_dict["user_name"] = f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}".strip()
    
    success = await ticket_manager.add_ticket_response(ticket_id, response_dict)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'ajout de la réponse"
        )
    
    return {"message": "Réponse ajoutée avec succès"}

@router.delete("/{ticket_id}")
async def delete_ticket(
    ticket_id: str,
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Supprime un ticket (Propriétaire ou Admin)
    """
    ticket = await ticket_manager.find_ticket_by_id(ticket_id)
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket non trouvé"
        )
    
    user_id = str(current_user["_id"])
    user_type = current_user.get("user_type")
    
    # Vérifier les permissions
    if user_type == "admin" or ticket["user_id"] == user_id:
        success = await ticket_manager.delete_ticket(ticket_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erreur lors de la suppression du ticket"
            )
        
        return {"message": "Ticket supprimé avec succès"}
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez supprimer que vos propres tickets"
        )

@router.get("/stats/overview", response_model=TicketStats)
async def get_ticket_stats(
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Récupère les statistiques des tickets (Admin seulement)
    """
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent voir les statistiques"
        )
    
    stats = await ticket_manager.get_ticket_stats()
    return TicketStats(**stats)

@router.get("/stats/my-stats")
async def get_my_ticket_stats(
    current_user: dict = Depends(get_current_user),
    ticket_manager: TicketManager = Depends(get_ticket_manager)
):
    """
    Récupère les statistiques des tickets de l'utilisateur connecté
    """
    user_id = str(current_user["_id"])
    
    # Récupérer tous les tickets de l'utilisateur
    tickets = await ticket_manager.find_tickets_by_user(user_id, 0, 1000)
    
    stats = {
        "total": len(tickets),
        "open": 0,
        "in_progress": 0,
        "resolved": 0,
        "closed": 0
    }
    
    for ticket in tickets:
        status = ticket.get("status")
        if status in stats:
            stats[status] += 1
    
    return stats