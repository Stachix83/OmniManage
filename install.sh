#!/bin/bash

# Zielverzeichnis
INSTALL_DIR="/opt/omnimanage"
SYSTEMD_DIR="$INSTALL_DIR/system-services"

# Installationsskript
# System-Updates durchführen
echo "🔄 System wird aktualisiert..."
sudo apt update && sudo apt upgrade -y

# Abhängigkeiten prüfen
dependencies=("python3" "python3-venv" "python3-pip" "postgresql" "postgresql-contrib" "git")
echo "📦 Prüfe erforderliche Pakete..."
for package in "${dependencies[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package"; then
        echo "⚠️  $package fehlt. Wird installiert..."
        sudo apt install -y $package
    else
        echo "✅ $package ist bereits installiert."
    fi
done

# PostgreSQL-Status prüfen
if ! systemctl is-active --quiet postgresql; then
    echo "⚠️  PostgreSQL läuft nicht. Starte PostgreSQL..."
    sudo systemctl start postgresql
fi

# Datenbankprüfung und -erstellung
read -p "Gib den Namen der Datenbank ein (Standard: omnimanage): " DB_NAME
DB_NAME=${DB_NAME:-omnimanage}
read -p "Gib den Benutzernamen für die Datenbank ein (Standard: omnimanage_user): " DB_USER
DB_USER=${DB_USER:-omnimanage_user}
read -sp "Gib das Passwort für den Benutzer $DB_USER ein: " DB_PASS
echo ""

# Prüfen, ob die Datenbank existiert
DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
if [ "$DB_EXISTS" == "1" ]; then
    echo "✅ Datenbank $DB_NAME existiert bereits."
else
    echo "🛠️  Erstelle Datenbank $DB_NAME..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    echo "✅ Datenbank $DB_NAME wurde erstellt und Benutzer $DB_USER hinzugefügt."
fi

# Virtuelle Umgebung erstellen
echo "🐍 Erstelle virtuelle Umgebung..."
python3 -m venv $INSTALL_DIR/venv
chown -R $(whoami):$(whoami) $INSTALL_DIR  # Richtige Berechtigungen setzen

# Virtuelle Umgebung aktivieren
echo "🔄 Aktiviere virtuelle Umgebung..."
source $INSTALL_DIR/venv/bin/activate

# Abhängigkeiten installieren
echo "📦 Installiere Python-Abhängigkeiten..."
pip install --upgrade pip
pip install -r $INSTALL_DIR/requirements.txt

# Flask WebUI installieren
echo "🌐 Installiere Flask WebUI..."
pip install flask flask-cors

# Systemd-Dienste kopieren
echo "📂 Kopiere Systemd-Dienste nach /etc/systemd/system/..."
sudo cp "$SYSTEMD_DIR/omnimanage.service" /etc/systemd/system/
sudo cp "$SYSTEMD_DIR/omnimanage-web.service" /etc/systemd/system/

# Dienste starten & aktivieren
echo "🚀 Starte OmniManage Backend & WebUI..."
sudo systemctl daemon-reload
sudo systemctl enable omnimanage.service omnimanage-web.service
sudo systemctl start omnimanage.service omnimanage-web.service

# Selfcheck: Überprüfen, ob die Dienste laufen
echo "🔍 Überprüfe OmniManage-Dienststatus..."
if systemctl is-active --quiet omnimanage.service; then
    echo "✅ OmniManage Backend läuft erfolgreich!"
else
    echo "❌ Fehler: OmniManage Backend konnte nicht gestartet werden. Bitte überprüfe die Logs mit:"
    echo "   sudo journalctl -u omnimanage.service --no-pager"
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
