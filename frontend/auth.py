from flask import Blueprint, request, redirect, render_template, session, url_for, flash
import requests
import os

auth_bp = Blueprint("auth", __name__)

API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/api")

@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        data = {
            "username": request.form["username"],
            "email": request.form["email"],
            "password": request.form["password"]
        }
        response = requests.post(f"{API_URL}/register", json=data)
        if response.status_code == 200:
            flash("Registrierung erfolgreich! Melde dich jetzt an.", "success")
            return redirect(url_for("auth.login"))
        else:
            flash(response.json().get("detail", "Fehler bei der Registrierung"), "danger")
    
    return render_template("register.html")


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        data = {
            "username": request.form["username"],
            "password": request.form["password"]
        }
        response = requests.post(f"{API_URL}/login", data=data)
        if response.status_code == 200:
            session["token"] = response.json()["access_token"]
            flash("Erfolgreich angemeldet!", "success")
            return redirect(url_for("index"))
        else:
            flash("Fehlerhafte Anmeldeinformationen", "danger")

    return render_template("login.html")

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
