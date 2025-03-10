#!/bin/bash

# Zielverzeichnis
INSTALL_DIR="/opt/omnimanage"
SYSTEMD_DIR="$INSTALL_DIR/system-services"
OMNIMANAGE_USER="omnimanage"

# Datenbank-Variablen (Ändern falls nötig)
DB_NAME="omnimanage_db"
DB_USER="omnimanage_user"
DB_PASS="securepassword"
DB_TYPE="mariadb"  # Ändere auf "postgresql" falls PostgreSQL genutzt wird

# Neuen Benutzer erstellen, falls nicht vorhanden
echo "👤 Erstelle Benutzer '$OMNIMANAGE_USER'..."
if ! id "$OMNIMANAGE_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$OMNIMANAGE_USER"
fi

# Berechtigungen setzen
echo "🔧 Setze Verzeichnisrechte..."
sudo chown -R "$OMNIMANAGE_USER:$OMNIMANAGE_USER" "$INSTALL_DIR"
echo "Setze Exekutierrechte für update.sh & deinstall.sh..."
sudo chmod +x "$INSTALL_DIR/update.sh"
sudo chmod +x "$INSTALL_DIR/deinstall.sh"
sudo chmod +x "$INSTALL_DIR/requirements_update.py"

# Als OmniManage-Benutzer das Setup ausführen
echo "🚀 Starte Installation als '$OMNIMANAGE_USER'..."
sudo -u "$OMNIMANAGE_USER" bash <<EOF

# Virtuelle Umgebung erstellen
echo "🐍 Erstelle virtuelle Umgebung..."
python3 -m venv $INSTALL_DIR/venv

# Virtuelle Umgebung aktivieren
echo "🔄 Aktiviere virtuelle Umgebung..."
source $INSTALL_DIR/venv/bin/activate

# Abhängigkeiten installieren
echo "📦 Installiere Python-Abhängigkeiten..."
pip install --upgrade pip
pip install -r $INSTALL_DIR/requirements.txt
EOF

# Abhängigkeiten aktualisieren und installieren
echo "📦 Aktualisiere und Installiere Python-Abhängigkeiten..."
sudo ./requirements_update.py

# Datenbank erstellen
echo "🗄️ Erstelle Datenbank für OmniManage..."
if [ "$DB_TYPE" == "mariadb" ]; then
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
elif [ "$DB_TYPE" == "postgresql" ]; then
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
else
    echo "⚠️ Unbekannter Datenbanktyp '$DB_TYPE', bitte manuell prüfen."
fi

# Systemdienste konfigurieren und starten
echo "🛠️ Konfiguriere Systemd-Dienste..."
echo "OmniManage Backend wird eingerichtet und gestartet..."
echo "
[Unit]
Description=OmniManage FastAPI Server
After=network.target
StartLimitBurst=5
StartLimitIntervalSec=10

[Service]
User=$OMNIMANAGE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/omnimanage.service

echo "🛠️ Konfiguriere OmniManage WebUI"
echo "
[Unit]
Description=OmniManage Flask WebUI
After=network.target
StartLimitBurst=5
StartLimitIntervalSec=10

[Service]
User=$OMNIMANAGE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python frontend/frontend.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/omnimanage-web.service

# Systemd-Dienste starten
echo "🚀 Starte OmniManage Backend & WebUI..."
sudo chmod 644 /etc/systemd/system/omnimanage.service
sudo chmod 644 /etc/systemd/system/omnimanage-web.service
sudo systemctl daemon-reload
sudo systemctl enable omnimanage-web.service
sudo systemctl enable omnimanage.service
sudo systemctl start omnimanage-web.service
sudo systemctl start omnimanage.service

# Selfcheck: Überprüfen, ob die Dienste laufen
echo "🔍 Selfcheck OmniManage-Dienststatus..."
if systemctl is-active --quiet omnimanage.service; then
    echo "✅ OmniManage Backend läuft erfolgreich!"
else
    echo "❌ Fehler: OmniManage Backend konnte nicht gestartet werden. Bitte überprüfe die Logs mit:"
    echo "      sudo journalctl -u omnimanage.service --no-pager"
    exit 1
fi

if systemctl is-active --quiet omnimanage-web.service; then
    echo "✅ OmniManage WebUI läuft erfolgreich!"
else
    echo "❌ Fehler: OmniManage WebUI konnte nicht gestartet werden. Bitte überprüfe die Logs mit:"
    echo "   sudo journalctl -u omnimanage-web.service --no-pager"
    exit 1
fi

# IP-Adresse abrufen
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "✅ OmniManage wurde erfolgreich installiert!"

echo "🔗 OmniManage Backend ist erreichbar unter: http://$IP_ADDRESS:8000"
echo "🔗 OmniManage WebUI ist erreichbar unter: http://$IP_ADDRESS:5000"
echo "Der Admin-Benutzer lautet: admin"
echo "Das Passwort lautet: adminpassword"
echo "Bitte ändern Sie das Passwort nach dem ersten Login!"
