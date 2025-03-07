import os
from dotenv import load_dotenv

# .env Datei laden
load_dotenv()

OAUTH_CLIENT_ID = os.getenv("OAUTH_CLIENT_ID")
OAUTH_CLIENT_SECRET = os.getenv("OAUTH_CLIENT_SECRET")
OAUTH_PROVIDER = os.getenv("OAUTH_PROVIDER")
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./omnimanage.db")
SECRET_KEY = os.getenv("SECRET_KEY")
