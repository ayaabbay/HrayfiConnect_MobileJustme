from fastapi import APIRouter

api_router = APIRouter()

# Import des routers
try:
    from .endpoints.auth import router as auth_router
    from .endpoints.users import router as users_router
    from .endpoints.upload import router as upload_router 
    from .endpoints.bookings import router as bookings_router 
    from .endpoints.reviews import router as reviews_router
    from .endpoints.tickets import router as tickets_router
    from .endpoints.chat import router as chat_router 
    
    api_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
    api_router.include_router(users_router, prefix="/users", tags=["Users"])
    api_router.include_router(upload_router, prefix="/upload", tags=["File Upload"])
    api_router.include_router(bookings_router, prefix="/bookings", tags=["Bookings"])
    api_router.include_router(reviews_router, prefix="/reviews", tags=["Reviews"])
    api_router.include_router(tickets_router, prefix="/tickets", tags=["Support Tickets"])
    api_router.include_router(chat_router, prefix="/chat", tags=["Chat"])

    print("✅ Tous les routers ont été importés avec succès")
    
except ImportError as e:
    print(f"❌ Erreur d'import: {e}")
    
    # Route de test temporaire
    @api_router.get("/auth/test")
    async def auth_test():
        return {"message": "Auth endpoint works!"}