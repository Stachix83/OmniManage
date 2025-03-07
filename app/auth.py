from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2AuthorizationCodeBearer
from authlib.integrations.starlette_client import OAuth
from starlette.requests import Request
from app.config import OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET, OAUTH_PROVIDER
import os

router = APIRouter()

oauth = OAuth()
oauth.register(
    name="oauth",
    client_id=os.getenv("OAUTH_CLIENT_ID"),
    client_secret=os.getenv("OAUTH_CLIENT_SECRET"),
    authorize_url=f"{os.getenv('OAUTH_PROVIDER')}/o/oauth2/auth",
    access_token_url=f"{os.getenv('OAUTH_PROVIDER')}/o/oauth2/token",
    client_kwargs={"scope": "openid email profile"},
)

@router.get("/login")
async def login(request: Request):
    redirect_uri = request.url_for("auth")
    return await oauth.oauth.authorize_redirect(request, redirect_uri)

@router.get("/auth")
async def auth(request: Request):
    token = await oauth.oauth.authorize_access_token(request)
    user_info = await oauth.oauth.parse_id_token(request, token)
    return {"username": user_info["email"], "email": user_info["email"]}  # Speichern in DB
