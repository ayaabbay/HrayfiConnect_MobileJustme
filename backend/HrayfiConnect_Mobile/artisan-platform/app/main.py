import warnings
warnings.filterwarnings("ignore")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Importez le routeur API
from app.api.v1.api import api_router
from app.core.database import connect_to_mongo, close_mongo_connection
from app.core.cloudinary_config import configure_cloudinary

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Démarrage
    await connect_to_mongo()
    configure_cloudinary()
    print("✅ Connexion à MongoDB établie")
    print("✅ Cloudinary configuré")
    yield
    # Arrêt
    await close_mongo_connection()

app = FastAPI(
    title="HrayfiConnect API",
    description="Plateforme de mise en relation entre artisans et clients",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "Bienvenue sur HrayfiConnect API", "status": "online"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}