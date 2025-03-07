from flask import Blueprint, request, redirect, render_template, session, url_for, flash
import requests
import os

auth_bp = Blueprint("auth", __name__)

API_URL = os.getenv("API_URL", "http://127.0.0.1:8000")

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
        response = requests.post(f"{API_URL}/login", json=data)
        if response.status_code == 200:
            token = response.json()["access_token"]
            session["token"] = token
            flash("Erfolgreich angemeldet!", "success")
            return redirect(url_for("index"))
        else:
            flash("Fehlerhafte Anmeldeinformationen", "danger")

    return render_template("login.html")

@auth_bp.route("/logout")
def logout():
    session.pop("token", None)
    flash("Erfolgreich ausgeloggt", "info")
    return redirect(url_for("index"))

@auth_bp.route("/me")
def me():
    token = session.get("token")
    if not token:
        flash("Bitte zuerst anmelden!", "warning")
        return redirect(url_for("auth.login"))

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{API_URL}/me", headers=headers)
    
    if response.status_code == 200:
        return response.json()
    else:
        flash("Fehler beim Abrufen der Benutzerdaten", "danger")
        return redirect(url_for("auth.login"))
