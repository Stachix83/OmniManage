from flask import Flask, render_template, jsonify
from dotenv import load_dotenv
import requests
import os

load_dotenv()

app = Flask(__name__)

# FastAPI-Backend-URL
API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/api")
SECRET_KEY = os.getenv("SECRET_KEY")

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/devices")
def devices():
    response = requests.get(f"{API_URL}/devices/")
    devices = response.json()
    return render_template("devices.html", devices=devices)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
