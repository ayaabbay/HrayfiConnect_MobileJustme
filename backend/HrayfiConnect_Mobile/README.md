# HrayfiConnect_Mobile
une application mobile Android qui met en relation des artisans et des clients, facilite la recherche et la réservation de services, et fournit des outils de gestion et de support

artisan-platform/  
├── venv/                 
├── .env                   
├── requirements.txt    
├── run.py             
└── app/  
    ├── __init__.py
    ├── __pycache__
    │   ├── main.cpython-312.pyc
    │   └── main.cpython-313.pyc
    ├── api
    │   ├── __init__.py
    │   ├── __pycache__
    │   │   └── __init__.cpython-312.pyc
    │   └── v1
    │       ├── __init__.py
    │       ├── __pycache__
    │       │   ├── __init__.cpython-312.pyc
    │       │   └── api.cpython-312.pyc
    │       ├── api.py
    │       ├── endpoints
    │       │   ├── __init__.py
    │       │   ├── __pycache__
    │       │   │   ├── __init__.cpython-312.pyc
    │       │   │   └── auth.cpython-312.pyc
    │       │   ├── auth.py
    │       │   ├── bookings.py
    │       │   ├── chat.py
    │       │   ├── reviews.py
    │       │   ├── tickets.py
    │       │   ├── upload.py
    │       │   └── users.py
    │       └── websockets
    │           └── chat.py
    ├── core
    │   ├── __init__.py
    │   ├── cloudinary_config.py
    │   ├── config.py
    │   ├── database.py
    │   └── security.py
    ├── main.py
    ├── models
    │   ├── __init__.py
    │   ├── booking_models.py
    │   ├── chat_models.py
    │   ├── review_models.py
    │   ├── ticket_models.py
    │   └── user_models.py
    ├── schemas
    │   ├── __init__.py
    │   ├── booking_schemas.py
    │   ├── chat_schemas.py
    │   ├── review_schemas.py
    │   ├── ticket_schemas.py
    │   └── user_schemas.py
    ├── services
    │   ├── __init__.py
    │   ├── auth_service.py
    │   ├── booking_service.py
    │   └── notification_service.py
    └── utils
        ├── __init__.py
        ├── cloudinary_service.py
        └── email_service.py