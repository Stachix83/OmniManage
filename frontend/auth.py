from flask import Blueprint, redirect, request, session, url_for
import requests
import os

auth_bp = Blueprint("auth", __name__)

API_URL = "http://127.0.0.1:8000/api"

@auth_bp.route("/login")
def login():
    return redirect(f"{API_URL}/login")

@auth_bp.route("/logout")
def logout():
    session.pop("user", None)
    return redirect(url_for("index"))

@auth_bp.route("/auth")
def auth():
    token = request.args.get("token")
    user_info = requests.get(f"{API_URL}/auth", headers={"Authorization": f"Bearer {token}"}).json()
    session["user"] = user_info
    return redirect(url_for("index"))
