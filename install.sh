#!/bin/bash

# Zielverzeichnis
INSTALL_DIR="/opt/omnimanage"
SYSTEMD_DIR="$INSTALL_DIR/system-services"
OMNIMANAGE_USER="omnimanage"

# Datenbank-Variablen
DB_NAME="omnimanage_db"
DB_USER="omnimanage_user"
DB_PASS="securepassword"

# Prüfen, ob eine Datenbank bereits installiert ist
DB_TYPE=""
if command -v mysql &>/dev/null; then
    DB_TYPE="mariadb"
elif command -v psql &>/dev/null; then
    DB_TYPE="postgresql"
fi

# Falls keine Datenbank gefunden wurde, Benutzer zur Auswahl auffordern
if [ -z "$DB_TYPE" ]; then
    echo "⚠️ Kein Datenbanksystem gefunden!"
    echo "Welche Datenbank soll installiert werden?"
    echo "1) MySQL/MariaDB"
    echo "2) PostgreSQL"
    echo "3) Abbrechen"
    read -p "Bitte wählen (1/2/3): " db_choice

    case "$db_choice" in
        1)
            DB_TYPE="mariadb"
            echo "🔧 Installiere MySQL/MariaDB..."
            sudo apt update
            sudo apt install -y mariadb-server mariadb-client
            ;;
        2)
            DB_TYPE="postgresql"
            echo "🔧 Installiere PostgreSQL..."
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
            ;;
        3)
            echo "❌ Installation abgebrochen."
            exit 1
            ;;
        *)
            echo "❌ Ungültige Eingabe. Installation abgebrochen."
            exit 1
            ;;
    esac
else
    echo "✅ Gefundene Datenbank: $DB_TYPE"
fi

# Neuen Benutzer erstellen, falls nicht vorhanden
echo "👤 Erstelle Benutzer '$OMNIMANAGE_USER'..."
if ! id "$OMNIMANAGE_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$OMNIMANAGE_USER"
fi

# Berechtigungen setzen
echo "🔧 Setze Verzeichnisrechte..."
sudo chown -R "$OMNIMANAGE_USER:$OMNIMANAGE_USER" "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/update.sh" "$INSTALL_DIR/deinstall.sh" "$INSTALL_DIR/requirements_update.py"

# Virtuelle Umgebung erstellen
echo "🐍 Erstelle virtuelle Umgebung..."
sudo -u "$OMNIMANAGE_USER" bash <<EOF
python3 -m venv $INSTALL_DIR/venv
source $INSTALL_DIR/venv/bin/activate
pip install --upgrade pip
pip install -r $INSTALL_DIR/requirements.txt
EOF

# Abhängigkeiten aktualisieren
echo "📦 Aktualisiere Python-Abhängigkeiten..."
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
fi

# Datenbankschema initialisieren
echo "🔧 Initialisiere Datenbankschema..."
sudo -u "$OMNIMANAGE_USER" bash <<EOF
source $INSTALL_DIR/venv/bin/activate
cd $INSTALL_DIR
alembic upgrade head
EOF

# Systemdienste konfigurieren
echo "🛠️ Konfiguriere Systemd-Dienste..."
echo "
[Unit]
Description=OmniManage FastAPI Server
After=network.target
[Service]
User=$OMNIMANAGE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/omnimanage.service

echo "
[Unit]
Description=OmniManage Flask WebUI
After=network.target
[Service]
User=$OMNIMANAGE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python frontend/frontend.py
Restart=always
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/omnimanage-web.service

# Systemd-Dienste starten
echo "🚀 Starte OmniManage Backend & WebUI..."
sudo systemctl daemon-reload
sudo systemctl enable --now omnimanage-web.service
sudo systemctl enable --now omnimanage.service

# Selfcheck: Überprüfen, ob die Dienste laufen
if systemctl is-active --quiet omnimanage.service; then
    echo "✅ OmniManage Backend läuft erfolgreich!"
else
    echo "❌ Fehler: OmniManage Backend konnte nicht gestartet werden."
    exit 1
fi

if systemctl is-active --quiet omnimanage-web.service; then
    echo "✅ OmniManage WebUI läuft erfolgreich!"
else
    echo "❌ Fehler: OmniManage WebUI konnte nicht gestartet werden."
    exit 1
fi

# IP-Adresse abrufen
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "✅ OmniManage wurde erfolgreich installiert!"
echo "🔗 OmniManage Backend: http://$IP_ADDRESS:8000"
echo "🔗 OmniManage WebUI: http://$IP_ADDRESS:5000"
