from flask import Flask, render_template, session
import sys
sys.path.append("/opt/omnimanage/frontend")
from frontend.auth import auth_bp

app = Flask(__name__)
app.secret_key = "supergeheimespasswort"  # Sollte aus `.env` geladen werden

# Blueprint für Authentifizierung registrieren
app.register_blueprint(auth_bp, url_prefix="/auth")

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
