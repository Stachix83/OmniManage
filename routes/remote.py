import os
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException

# .env Datei laden
load_dotenv()

router = APIRouter()

API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/api")
SECRET_KEY = os.getenv("SECRET_KEY")

@router.get("/remote")
async def get_remote():
    return {"message": "Remote management status"}