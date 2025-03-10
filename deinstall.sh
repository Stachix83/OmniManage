#!/bin/bash

echo "🛑 OmniManage wird vollständig deinstalliert..."

# Systemd-Dienste stoppen und entfernen
echo "🔧 Stoppe und entferne Systemd-Dienste..."
if systemctl is-active --quiet omnimanage-web.service; then
    sudo systemctl stop omnimanage-web.service
fi
if systemctl is-active --quiet omnimanage.service; then
    sudo systemctl stop omnimanage.service
fi

sudo systemctl disable omnimanage-web.service
sudo systemctl disable omnimanage.service
sudo rm -f /etc/systemd/system/omnimanage-web.service
sudo rm -f /etc/systemd/system/omnimanage.service

# Systemd-Dienste neu laden
if systemctl list-units --full -all | grep -q "omnimanage"; then
    sudo systemctl daemon-reload
fi

# Virtuelle Umgebung deaktivieren und löschen
VENV_DIR="/opt/omnimanage/venv"
if [ -d "$VENV_DIR" ]; then
    echo "📌 Deaktiviere und lösche virtuelle Umgebung..."
    source "$VENV_DIR/bin/activate"
    deactivate
    sudo rm -rf "$VENV_DIR"
else
    echo "⚠️ Keine virtuelle Umgebung gefunden, überspringe..."
fi

# Benutzer löschen
OMNIMANAGE_USER="omnimanage"
if id "$OMNIMANAGE_USER" &>/dev/null; then
    echo "👤 Entferne Benutzer '$OMNIMANAGE_USER'..."
    sudo userdel -r "$OMNIMANAGE_USER"
else
    echo "⚠️ Benutzer '$OMNIMANAGE_USER' existiert nicht, überspringe..."
fi

# Datenbank löschen
DB_NAME="omnimanage_db"
DB_USER="omnimanage_user"
DB_TYPE="mariadb"  # Ändere auf "postgresql" falls PostgreSQL genutzt wird

echo "🗑️ Lösche Datenbank und Benutzer..."

if [ "$DB_TYPE" == "mariadb" ]; then
    sudo mysql -e "DROP DATABASE IF EXISTS $DB_NAME;"
    sudo mysql -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
elif [ "$DB_TYPE" == "postgresql" ]; then
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
    sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
else
    echo "⚠️ Unbekannter Datenbanktyp '$DB_TYPE', bitte manuell prüfen."
fi

# Verzeichnisse löschen
echo "🗑️ Entferne OmniManage-Dateien und Verzeichnisse..."
sudo rm -rf /opt/omnimanage
sudo rm -rf /var/log/omnimanage
sudo rm -rf /var/lib/omnimanage
sudo rm -rf /etc/omnimanage

echo "✅ OmniManage wurde vollständig deinstalliert!"
echo "👋 Tschüss!"
