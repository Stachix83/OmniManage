#!/bin/bash

echo "🔧 OmniManage wird installiert..."

# System-Updates
sudo apt update && sudo apt upgrade -y

# Python & Abhängigkeiten installieren
sudo apt install -y python3 python3-venv python3-pip postgresql postgresql-contrib

# PostgreSQL einrichten
sudo -u postgres psql -c "CREATE DATABASE omnimanage;"
sudo -u postgres psql -c "CREATE USER omnimanage_user WITH PASSWORD 'securepassword';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE omnimanage TO omnimanage_user;"

# Projekt klonen
git clone https://github.com/stachix83/omnimanage.git /opt/omnimanage
cd /opt/omnimanage

# Virtuelle Umgebung erstellen
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Systemd-Dienst erstellen
echo "[Unit]
Description=OmniManage FastAPI Server
After=network.target

[Service]
User=root
WorkingDirectory=/opt/omnimanage
ExecStart=/opt/omnimanage/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/omnimanage.service

# Dienst starten & aktivieren
sudo systemctl daemon-reload
sudo systemctl enable omnimanage.service
sudo systemctl start omnimanage.service

echo "✅ OmniManage wurde erfolgreich installiert!"
echo "🔗 Du kannst OmniManage nun unter http://DEINE_IP:8000 erreichen."