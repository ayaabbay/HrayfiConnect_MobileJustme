import cloudinary.uploader
import cloudinary.exceptions
from fastapi import UploadFile, HTTPException, status
import secrets
from app.core.config import settings

class CloudinaryService:
    @staticmethod
    async def upload_image(file: UploadFile, folder: str = "artisan_platform"):
        """
        Upload une image vers Cloudinary
        """
        try:
            # Vérifier le type de fichier
            if not file.content_type.startswith('image/'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Le fichier doit être une image"
                )
            
            # Générer un nom de fichier unique
            file_extension = file.filename.split('.')[-1]
            unique_filename = f"{secrets.token_hex(8)}.{file_extension}"
            
            # Upload vers Cloudinary
            result = cloudinary.uploader.upload(
                file.file,
                public_id=unique_filename,
                folder=folder,
                overwrite=True,
                resource_type="image"
            )
            
            return {
                "url": result["secure_url"],
                "public_id": result["public_id"],
                "format": result["format"],
                "width": result["width"],
                "height": result["height"]
            }
            
        except cloudinary.exceptions.Error as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erreur Cloudinary: {str(e)}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erreur lors de l'upload: {str(e)}"
            )
    
    @staticmethod
    async def delete_image(public_id: str):
        """
        Supprime une image de Cloudinary
        """
        try:
            result = cloudinary.uploader.destroy(public_id)
            return result
        except cloudinary.exceptions.Error as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erreur lors de la suppression: {str(e)}"
            )

# Instance globale
cloudinary_service = CloudinaryService()