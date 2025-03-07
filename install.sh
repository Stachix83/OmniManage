#!/bin/bash

# Zielverzeichnis
INSTALL_DIR="/opt/omnimanage"
SYSTEMD_DIR="$INSTALL_DIR/system-services"
OMNIMANAGE_USER="omnimanage"

# Neuen Benutzer erstellen, falls nicht vorhanden
if ! id "$OMNIMANAGE_USER" &>/dev/null; then
    echo "👤 Erstelle Benutzer '$OMNIMANAGE_USER'..."
    sudo useradd -m -s /bin/bash "$OMNIMANAGE_USER"
fi

# Berechtigungen setzen
echo "🔧 Setze Verzeichnisrechte..."
sudo chown -R "$OMNIMANAGE_USER:$OMNIMANAGE_USER" "$INSTALL_DIR"

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
pip install flask flask-cors

EOF

# Systemd-Dienste kopieren und Benutzer ändern
echo "📂 Kopiere Systemd-Dienste nach /etc/systemd/system/..."
sudo cp "$SYSTEMD_DIR/omnimanage.service" /etc/systemd/system/
sudo cp "$SYSTEMD_DIR/omnimanageweb.service" /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/omnimanage.service
sudo chmod 644 /etc/systemd/system/omnimanage-web.service

# Systemd-Dienst anpassen, damit er unter 'omnimanage' läuft
echo "🛠️ Konfiguriere Systemd-Dienste..."
sudo sed -i "s|User=root|User=$OMNIMANAGE_USER|g" /etc/systemd/system/omnimanage.service
sudo sed -i "s|User=root|User=$OMNIMANAGE_USER|g" /etc/systemd/system/omnimanage-web.service

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
    echo " ❌  Fehler: OmniManage Backend konnte nicht gestartet werden. Bitte überprüfe die Logs mit:"
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
