import cloudinary.uploader
import cloudinary.exceptions
from fastapi import UploadFile, HTTPException, status
import secrets
import re
from app.core.config import settings

class CloudinaryService:
    # Extensions d'images valides
    VALID_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'}
    
    @staticmethod
    def _is_valid_image_file(filename: str, content_type: str = None) -> bool:
        """
        Vérifie si le fichier est une image valide basé sur l'extension et le content_type
        """
        print(f"🔍 _is_valid_image_file - filename: '{filename}', content_type: '{content_type}'")
        
        # Si on a un content_type valide, on l'accepte
        if content_type and content_type.startswith('image/'):
            print(f"✅ Validation réussie via content_type: {content_type}")
            return True
        
        # Si pas de filename, on ne peut pas valider par extension
        if not filename:
            print(f"❌ Pas de filename fourni")
            return False
        
        # Vérifier l'extension du fichier
        file_extension = '.' + filename.split('.')[-1].lower() if '.' in filename else ''
        print(f"🔍 Extension détectée: '{file_extension}'")
        
        if file_extension not in CloudinaryService.VALID_IMAGE_EXTENSIONS:
            print(f"❌ Extension '{file_extension}' non valide. Extensions valides: {CloudinaryService.VALID_IMAGE_EXTENSIONS}")
            return False
        
        print(f"✅ Validation réussie via extension: {file_extension}")
        return True
    
    @staticmethod
    async def upload_image(file: UploadFile, folder: str = "artisan_platform"):
        """
        Upload une image vers Cloudinary
        """
        try:
            # CORRECTION: Gérer le cas où content_type est None
            content_type = file.content_type or ''
            filename = file.filename or ''
            
            # DEBUG: Afficher les informations du fichier
            print(f"🔍 DEBUG Upload - filename: '{filename}', content_type: '{content_type}'")
            
            # CORRECTION: Lire les bytes du fichier une seule fois
            # Cela fonctionne mieux avec les fichiers venant de Flutter Web
            file_bytes = await file.read()
            
            # Vérifier le type de fichier avec la nouvelle méthode
            is_valid = CloudinaryService._is_valid_image_file(filename, content_type)
            
            if not is_valid:
                print(f"❌ Validation échouée - filename: '{filename}', content_type: '{content_type}'")
                # Si on n'a ni filename ni content_type valide, on essaie de détecter depuis les bytes
                if not filename and not content_type:
                    print("⚠️ Pas de filename ni content_type, tentative de détection depuis les bytes...")
                    
                    # Vérifier les signatures de fichiers (magic numbers)
                    if len(file_bytes) >= 4:
                        # JPEG: FF D8 FF
                        if file_bytes[0] == 0xFF and file_bytes[1] == 0xD8 and file_bytes[2] == 0xFF:
                            print("✅ Détecté comme JPEG depuis les bytes")
                            is_valid = True
                        # PNG: 89 50 4E 47
                        elif file_bytes[0] == 0x89 and file_bytes[1] == 0x50 and file_bytes[2] == 0x4E and file_bytes[3] == 0x47:
                            print("✅ Détecté comme PNG depuis les bytes")
                            is_valid = True
                        # GIF: 47 49 46 38
                        elif file_bytes[0] == 0x47 and file_bytes[1] == 0x49 and file_bytes[2] == 0x46 and file_bytes[3] == 0x38:
                            print("✅ Détecté comme GIF depuis les bytes")
                            is_valid = True
                        # WebP: RIFF...WEBP
                        elif len(file_bytes) >= 12 and file_bytes[0:4] == b'RIFF' and file_bytes[8:12] == b'WEBP':
                            print("✅ Détecté comme WebP depuis les bytes")
                            is_valid = True
                
                if not is_valid:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Le fichier doit être une image (jpg, jpeg, png, gif, bmp, webp, svg). Reçu: filename='{filename}', content_type='{content_type}'"
                    )
            
            print(f"✅ Validation réussie pour '{filename}'")
            
            # Générer un nom de fichier unique
            file_extension = filename.split('.')[-1] if '.' in filename else 'jpg'
            unique_filename = f"{secrets.token_hex(8)}.{file_extension}"
            
            # Upload vers Cloudinary en utilisant les bytes
            result = cloudinary.uploader.upload(
                file_bytes,
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
            
        except HTTPException:
            raise
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
    
    @staticmethod
    def extract_public_id_from_url(url: str) -> str:
        """
        Extrait le public_id d'une URL Cloudinary
        """
        try:
            if not url:
                return None
                
            # Pattern pour extraire le public_id d'une URL Cloudinary
            # Exemple: https://res.cloudinary.com/cloudname/image/upload/v1234567890/folder/filename.jpg
            # Doit retourner: folder/filename
            
            # Supprime le préfixe de l'URL
            patterns = [
                r'https?://res\.cloudinary\.com/[^/]+/image/upload/(?:v\d+/)?(.*?)(?:\.[^/.]+)?$',
                r'https?://res\.cloudinary\.com/[^/]+/image/upload/(.*?)(?:\.[^/.]+)?$'
            ]
            
            for pattern in patterns:
                match = re.search(pattern, url)
                if match:
                    public_id = match.group(1)
                    # Si le public_id se termine par une extension, on la supprime
                    if '.' in public_id:
                        public_id = public_id.rsplit('.', 1)[0]
                    return public_id
            
            # Si les patterns regex ne fonctionnent pas, méthode alternative
            if '/upload/' in url:
                parts = url.split('/upload/')
                if len(parts) > 1:
                    path_part = parts[1]
                    # Supprime le paramètre de version s'il existe
                    if path_part.startswith('v'):
                        path_part = path_part.split('/', 1)[1] if '/' in path_part else ''
                    # Supprime l'extension de fichier
                    if '.' in path_part:
                        path_part = path_part.rsplit('.', 1)[0]
                    return path_part
            
            return None
            
        except Exception as e:
            print(f"Erreur lors de l'extraction du public_id: {str(e)}")
            return None

# Instance globale
cloudinary_service = CloudinaryService()