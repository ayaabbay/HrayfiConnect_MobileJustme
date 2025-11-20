import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings
import random
import string
import asyncio

class EmailService:
    def __init__(self):
        self.smtp_server = settings.SMTP_SERVER
        self.smtp_port = settings.SMTP_PORT
        self.smtp_user = settings.SMTP_USER
        self.smtp_password = settings.SMTP_PASSWORD
    
    def generate_reset_code(self, length=6):
        """Génère un code numérique de sécurité"""
        return ''.join(random.choices(string.digits, k=length))
    
    async def send_reset_code(self, to_email: str, reset_code: str):
        """Envoie le code de réinitialisation par email (version asynchrone)"""
        try:
            # Exécuter l'envoi d'email dans un thread séparé pour ne pas bloquer
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, 
                self._send_email_sync, 
                to_email, 
                reset_code
            )
            return result
        except Exception as e:
            print(f"❌ Erreur envoi email asynchrone: {e}")
            return False
    
    def _send_email_sync(self, to_email: str, reset_code: str):
        """Version synchrone pour l'envoi d'email"""
        try:
            # Création du message
            message = MIMEMultipart()
            message["From"] = self.smtp_user
            message["To"] = to_email
            message["Subject"] = "Code de réinitialisation de mot de passe - HrayfiConnect"
            
            # Corps du message HTML
            html_body = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: #2563eb; color: white; padding: 20px; text-align: center; }}
                    .code {{ font-size: 32px; letter-spacing: 8px; text-align: center; margin: 30px 0; 
                            color: #2563eb; font-weight: bold; }}
                    .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; 
                             color: #666; font-size: 14px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>HrayfiConnect</h1>
                    </div>
                    
                    <h2>Réinitialisation de votre mot de passe</h2>
                    <p>Bonjour,</p>
                    <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
                    <p>Voici votre code de sécurité :</p>
                    
                    <div class="code">{reset_code}</div>
                    
                    <p><strong>⚠️ Ce code expirera dans 2 minutes.</strong></p>
                    <p>Si vous n'avez pas fait cette demande, veuillez ignorer cet email.</p>
                    
                    <div class="footer">
                        <p>Cordialement,<br>L'équipe HrayfiConnect</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # Version texte simple pour les clients email qui ne supportent pas HTML
            text_body = f"""
            Réinitialisation de mot de passe - HrayfiConnect
            
            Bonjour,
            
            Vous avez demandé la réinitialisation de votre mot de passe.
            Voici votre code de sécurité : {reset_code}
            
            Ce code expirera dans 2 minutes.
            
            Si vous n'avez pas fait cette demande, veuillez ignorer cet email.
            
            Cordialement,
            L'équipe HrayfiConnect
            """
            
            # Attacher les deux versions (HTML et texte)
            #message.attach(MIMEText(text_body, "plain"))
            message.attach(MIMEText(html_body, "html"))
            
            # Connexion et envoi
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()  # Sécurise la connexion
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(message)
            
            print(f"✅ Code de réinitialisation envoyé à {to_email}")
            return True
            
        except smtplib.SMTPAuthenticationError:
            print("❌ Erreur d'authentification SMTP - Vérifiez les identifiants")
            return False
        except smtplib.SMTPException as e:
            print(f"❌ Erreur SMTP: {e}")
            return False
        except Exception as e:
            print(f"❌ Erreur inattendue lors de l'envoi d'email: {e}")
            return False

# Instance globale
email_service = EmailService()