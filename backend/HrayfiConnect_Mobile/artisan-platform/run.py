import warnings
import urllib3

# Méthode compatible avec toutes les versions d'urllib3
try:
    # Pour les nouvelles versions d'urllib3
    from urllib3.exceptions import NotOpenSSLWarning
    warnings.filterwarnings("ignore", category=NotOpenSSLWarning)
except ImportError:
    # Pour les anciennes versions, ignorer tous les warnings d'urllib3
    warnings.filterwarnings("ignore", category=UserWarning, module="urllib3")
    # Ou simplement ignorer tous les warnings
    # warnings.filterwarnings("ignore")

import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
        ws="websockets"
    )