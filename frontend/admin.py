from flask import Flask, render_template, session
from frontend.auth import auth_bp
from frontend.admin import admin_bp

app = Flask(__name__)
app.secret_key = "supergeheimespasswort"  # Sollte aus `.env` geladen werden

# Blueprints registrieren
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(admin_bp, url_prefix="/admin")

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
