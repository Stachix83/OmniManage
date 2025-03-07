#!/bin/bash

echo "🔄 OmniManage wird aktualisiert..."

# Ins Projektverzeichnis wechseln
cd /opt/omnimanage

# Änderungen aus dem Git-Repo ziehen
git pull origin main

# Virtuelle Umgebung aktivieren & Abhängigkeiten updaten
source venv/bin/activate
pip install -r requirements.txt

# Dienste neustarten
sudo systemctl restart omnimanage.service
sudo systemctl restart omnimanage-web.service

echo "✅ OmniManage wurde erfolgreich aktualisiert!"
