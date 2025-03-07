#!/bin/bash

echo "🛑 OmniManage wird deinstalliert..."

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

# Systemd-Dienste neu laden, falls Änderungen vorgenommen wurden
if systemctl list-units --full -all | grep -q "omnimanage"; then
    sudo systemctl daemon-reload
fi

# Benutzer löschen, falls vorhanden
OMNIMANAGE_USER="omnimanage"
if id "$OMNIMANAGE_USER" &>/dev/null; then
    echo "👤 Entferne Benutzer '$OMNIMANAGE_USER'..."
    sudo userdel -r "$OMNIMANAGE_USER"
else
    echo "⚠️ Benutzer '$OMNIMANAGE_USER' existiert nicht, überspringe..."
fi

# Verzeichnisse löschen
echo "🗑️ Entferne OmniManage-Dateien und Verzeichnisse..."
sudo rm -rf /opt/omnimanage
sudo rm -rf /var/log/omnimanage
sudo rm -rf /var/lib/omnimanage
sudo rm -rf /etc/omnimanage

echo "✅ OmniManage wurde erfolgreich deinstalliert!"
echo "👋 Tschüss!"