import os
from dotenv import load_dotenv

# .env Datei laden
load_dotenv()

API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/api")
SECRET_KEY = os.getenv("SECRET_KEY")
