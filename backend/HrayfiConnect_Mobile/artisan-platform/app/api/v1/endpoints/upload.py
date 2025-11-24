from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from typing import List
from datetime import datetime

from app.utils.cloudinary_service import cloudinary_service
from app.models.user_models import UserManager
from app.api.v1.endpoints.auth import get_current_user
from app.core.database import get_database
from app.schemas.user_schemas import (
    UploadResponse, PortfolioUploadResponse, DeleteImageResponse,
    IdentityDocumentUploadResponse, IdentityDocumentsResponse
)

router = APIRouter()

def get_user_manager():
    database = get_database()
    return UserManager(database)

@router.post("/profile-picture", response_model=UploadResponse)
async def upload_profile_picture(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Upload une photo de profil pour l'utilisateur connecté
    """
    # Vérifier la taille du fichier (max 5MB)
    if hasattr(file, 'size') and file.size > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'image ne doit pas dépasser 5MB"
        )
    
    # Upload vers Cloudinary
    folder = f"artisan_platform/users/{current_user['_id']}/profile"
    upload_result = await cloudinary_service.upload_image(file, folder)
    
    # Si l'utilisateur a déjà une photo de profil, supprimer l'ancienne de Cloudinary
    old_profile_picture = current_user.get("profile_picture")
    if old_profile_picture:
        old_public_id = cloudinary_service.extract_public_id_from_url(old_profile_picture)
        if old_public_id:
            await cloudinary_service.delete_image(old_public_id)
    
    # Mettre à jour l'utilisateur avec la nouvelle photo
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"profile_picture": upload_result["url"]}
    )
    
    return UploadResponse(
        message="Photo de profil mise à jour avec succès",
        **upload_result
    )

@router.delete("/profile-picture")
async def delete_profile_picture(
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Supprime la photo de profil de l'utilisateur connecté
    """
    current_profile_picture = current_user.get("profile_picture")
    
    if not current_profile_picture:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucune photo de profil trouvée"
        )
    
    # Supprimer l'image de Cloudinary
    public_id = cloudinary_service.extract_public_id_from_url(current_profile_picture)
    deleted_from_cloudinary = False
    
    if public_id:
        try:
            delete_result = await cloudinary_service.delete_image(public_id)
            deleted_from_cloudinary = delete_result.get("result") == "ok"
        except Exception as e:
            # Log l'erreur mais continue avec la suppression en base de données
            print(f"Erreur lors de la suppression Cloudinary: {str(e)}")
    else:
        print(f"Impossible d'extraire le public_id de l'URL: {current_profile_picture}")
    
    # Mettre à jour l'utilisateur (supprimer la photo en base de données même si Cloudinary échoue)
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"profile_picture": None}
    )
    
    return {
        "message": "Photo de profil supprimée avec succès",
        "deleted_from_cloudinary": deleted_from_cloudinary,
        "public_id": public_id
    } 

# NOUVEAU: Upload des documents d'identité pour les artisans
@router.post("/artisans/identity-documents/{document_type}", response_model=IdentityDocumentUploadResponse)
async def upload_identity_document(
    document_type: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Upload un document d'identité pour un artisan
    Types de documents: cin_recto, cin_verso, photo
    """
    # Vérifier que l'utilisateur est un artisan
    if current_user.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent uploader des documents d'identité"
        )
    
    # Vérifier le type de document
    valid_document_types = ["cin_recto", "cin_verso", "photo"]
    if document_type not in valid_document_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Type de document invalide. Types valides: {', '.join(valid_document_types)}"
        )
    
    # Vérifier la taille du fichier (max 5MB)
    if hasattr(file, 'size') and file.size > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le document ne doit pas dépasser 5MB"
        )
    
    # Upload vers Cloudinary
    folder = f"artisan_platform/artisans/{current_user['_id']}/identity_documents"
    upload_result = await cloudinary_service.upload_image(file, folder)
    
    # Récupérer l'artisan actuel
    artisan = await user_manager.find_user_by_id(str(current_user["_id"]))
    
    # CORRECTION: Initialiser identity_document comme un dictionnaire vide s'il est None
    identity_document = artisan.get("identity_document", {})
    if identity_document is None:
        identity_document = {}
    
    # Mettre à jour le document spécifique
    identity_document[document_type] = upload_result["url"]
    
    # Mettre à jour l'artisan
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"identity_document": identity_document}
    )
    
    return IdentityDocumentUploadResponse(
        message=f"Document {document_type} uploadé avec succès",
        document_type=document_type,
        url=upload_result["url"],
        public_id=upload_result["public_id"]
    )

# NOUVEAU: Récupérer les documents d'identité (Admin seulement)
@router.get("/artisans/{artisan_id}/identity-documents", response_model=IdentityDocumentsResponse)
async def get_identity_documents(
    artisan_id: str,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Récupère les documents d'identité d'un artisan (Admin seulement)
    """
    # Vérifier que l'utilisateur est un admin
    if current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent accéder aux documents d'identité"
        )
    
    # Récupérer l'artisan
    artisan = await user_manager.find_user_by_id(artisan_id)
    if not artisan or artisan.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artisan non trouvé"
        )
    
    # CORRECTION: Gérer le cas où identity_document est None
    identity_document = artisan.get("identity_document", {})
    if identity_document is None:
        identity_document = {}
    
    return IdentityDocumentsResponse(
        cin_recto=identity_document.get("cin_recto"),
        cin_verso=identity_document.get("cin_verso"),
        photo=identity_document.get("photo")
    )

@router.post("/artisans/portfolio", response_model=PortfolioUploadResponse)
async def upload_portfolio_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Upload une image dans le portfolio d'un artisan
    """
    # Vérifier que l'utilisateur est un artisan
    if current_user.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent uploader des images de portfolio"
        )
    
    # Vérifier la taille du fichier (max 5MB)
    if hasattr(file, 'size') and file.size > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'image ne doit pas dépasser 5MB"
        )
    
    # Upload vers Cloudinary
    folder = f"artisan_platform/artisans/{current_user['_id']}/portfolio"
    upload_result = await cloudinary_service.upload_image(file, folder)
    
    # Récupérer l'artisan actuel
    artisan = await user_manager.find_user_by_id(str(current_user["_id"]))
    portfolio = artisan.get("portfolio", [])
    
    # Ajouter la nouvelle image au portfolio
    portfolio.append({
        "url": upload_result["url"],
        "public_id": upload_result["public_id"],
        "uploaded_at": datetime.utcnow().isoformat()
    })
    
    # Mettre à jour l'artisan
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"portfolio": portfolio}
    )
    
    return PortfolioUploadResponse(
        message="Image ajoutée au portfolio avec succès",
        url=upload_result["url"],
        public_id=upload_result["public_id"],
        portfolio_count=len(portfolio)
    )

@router.delete("/artisans/portfolio/{image_index}", response_model=DeleteImageResponse)
async def delete_portfolio_image(
    image_index: int,
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Supprime une image du portfolio d'un artisan par son index
    """
    if current_user.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent supprimer des images de portfolio"
        )
    
    # Récupérer l'artisan
    artisan = await user_manager.find_user_by_id(str(current_user["_id"]))
    portfolio = artisan.get("portfolio", [])
    
    # Vérifier si l'index est valide
    if image_index < 0 or image_index >= len(portfolio):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image non trouvée dans le portfolio"
        )
    
    # Récupérer les informations de l'image à supprimer
    image_to_delete = portfolio[image_index]
    image_url = image_to_delete.get("url")
    public_id = image_to_delete.get("public_id")
    
    # Supprimer l'image de Cloudinary
    deleted_from_cloudinary = False
    if public_id:
        delete_result = await cloudinary_service.delete_image(public_id)
        deleted_from_cloudinary = delete_result.get("result") == "ok"
    
    # Supprimer l'image du portfolio
    portfolio.pop(image_index)
    
    # Mettre à jour l'artisan
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"portfolio": portfolio}
    )
    
    return DeleteImageResponse(
        message="Image supprimée du portfolio avec succès",
        deleted_from_cloudinary=deleted_from_cloudinary,
        portfolio_count=len(portfolio)
    )

@router.post("/artisans/portfolio/multiple")
async def upload_multiple_portfolio_images(
    files: List[UploadFile] = File(None),
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Upload plusieurs images dans le portfolio d'un artisan
    """
    if current_user.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent uploader des images de portfolio"
        )
    
    if not files:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun fichier fourni"
        )
    
    uploaded_images = []
    artisan = await user_manager.find_user_by_id(str(current_user["_id"]))
    portfolio = artisan.get("portfolio", [])
    
    for file in files:
        # Vérifier la taille de chaque fichier
        if hasattr(file, 'size') and file.size > 5 * 1024 * 1024:
            continue  # Ignorer les fichiers trop gros
        
        # Upload vers Cloudinary
        folder = f"artisan_platform/artisans/{current_user['_id']}/portfolio"
        upload_result = await cloudinary_service.upload_image(file, folder)
        
        # Ajouter au portfolio
        portfolio.append({
            "url": upload_result["url"],
            "public_id": upload_result["public_id"],
            "uploaded_at": datetime.utcnow().isoformat()
        })
        uploaded_images.append(upload_result)
    
    # Mettre à jour l'artisan
    await user_manager.update_user(
        str(current_user["_id"]), 
        {"portfolio": portfolio}
    )
    
    return {
        "message": f"{len(uploaded_images)} images ajoutées au portfolio",
        "uploaded_images": uploaded_images,
        "total_portfolio_count": len(portfolio)
    }

@router.get("/artisans/portfolio")
async def get_portfolio(
    current_user: dict = Depends(get_current_user),
    user_manager: UserManager = Depends(get_user_manager)
):
    """
    Récupère le portfolio de l'artisan connecté
    """
    if current_user.get("user_type") != "artisan":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les artisans peuvent accéder au portfolio"
        )
    
    artisan = await user_manager.find_user_by_id(str(current_user["_id"]))
    portfolio = artisan.get("portfolio", [])
    
    return {
        "portfolio": portfolio,
        "count": len(portfolio)
    }