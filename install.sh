#!/bin/bash
echo "📦 OmniManage Installation beginnt..."

# System aktualisieren & Pakete installieren
sudo apt update && sudo apt install -y python3 python3-venv python3-pip git postgresql postgresql-contrib

# Git-Repository clonen
cd /opt
sudo git clone https://github.com/dein-repo/omnimanage.git
cd omnimanage

# Virtuelle Umgebung erstellen & aktivieren
python3 -m venv venv
source venv/bin/activate

# Anforderungen installieren
pip install -r requirements.txt

# Datenbank einrichten
sudo -u postgres psql -c "CREATE DATABASE omnimanage;"
sudo -u postgres psql -c "CREATE USER omnimanage_user WITH PASSWORD 'sicheres_passwort';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE omnimanage TO omnimanage_user;"

# Migrations ausführen
python manage.py migrate

# Server starten
nohup python manage.py runserver 0.0.0.0:8000 &
echo "✅ OmniManage erfolgreich installiert & gestartet!"
