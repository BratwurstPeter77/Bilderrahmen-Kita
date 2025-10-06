# 🛠️ Detaillierte Installation - Bilderrahmen-Kita

## Überblick

Diese Anleitung führt Sie Schritt-für-Schritt durch die **manuelle Installation** des Bilderrahmen-Kita Systems. Für die automatische Installation verwenden Sie das [Ein-Zeilen-Script](README.md#installation).

## 📋 Voraussetzungen prüfen

### Hardware-Checkliste
- [ ] **Raspberry Pi** (3B+ oder neuer, empfohlen: Pi 4 mit 4GB RAM)
- [ ] **MicroSD-Karte** (mindestens 32GB, Class 10 oder besser)  
- [ ] **Netzwerkkabel** oder **WLAN-Zugang**
- [ ] **5 Tablets** (Android oder iOS) für Slideshow-Anzeige
- [ ] **Router** mit WLAN im Kita-Netzwerk

### Software-Checkliste  
- [ ] **Raspberry Pi OS** (Bookworm oder neuer)
- [ ] **SSH-Zugang** aktiviert (für Fernwartung)
- [ ] **Android-Geräte** (Erzieher-Handys) mit WLAN

### Netzwerk-Checkliste
- [ ] **Statische IP** oder **DHCP-Reservation** für Raspberry Pi
- [ ] **Port 445** (SMB) im Netzwerk erlaubt
- [ ] **Port 80** (HTTP) für Web-Verwaltung erlaubt
- [ ] **mDNS** im Router aktiviert (für .local Domains)

## 🎯 Schritt 1: Raspberry Pi OS Installation

### SD-Karte vorbereiten

1. **Raspberry Pi Imager** herunterladen:
   ```
   https://www.raspberrypi.com/software/
   ```

2. **SD-Karte einlegen** und Imager starten

3. **OS auswählen:** "Raspberry Pi OS (64-bit)" empfohlen

4. **Erweiterte Optionen** konfigurieren (Zahnrad-Symbol):
   ```
   Hostname: bilderrahmen
   SSH aktivieren: ✓
   Benutzername: pi  
   Passwort: [Sicheres Passwort]
   WLAN konfigurieren: ✓
   WLAN-Name: [Kita-WLAN]
   WLAN-Passwort: [WLAN-Passwort]
   WLAN-Land: DE
   Zeitzone: Europe/Berlin
   ```

5. **"Speichern"** und Installation starten

6. Nach Abschluss: **SD-Karte in Raspberry Pi** einlegen

### Erster Start

1. **Raspberry Pi** mit Strom versorgen (LED sollte blinken)
2. **2-3 Minuten warten** bis vollständig gebootet
3. **SSH-Verbindung** testen:
   ```bash
   ssh pi@bilderrahmen.local
   # oder mit IP-Adresse:
   ssh pi@192.168.1.XXX
   ```

## 🔧 Schritt 2: System aktualisieren

```bash
# System-Pakete aktualisieren
sudo apt update && sudo apt upgrade -y

# Neustart nach Updates
sudo reboot
```

Nach Neustart erneut per SSH verbinden.

## 👤 Schritt 3: Kita-Benutzer erstellen

```bash
# Benutzername und Passwort für Kita-Zugang
read -p "Kita-Benutzername: " KITA_USER
read -s -p "Kita-Passwort: " KITA_PASS
echo

# System-Benutzer erstellen
sudo useradd -r -s /bin/false "$KITA_USER"
```

**Wichtig:** Diese Daten für Android-Apps und Windows notieren!

## 📦 Schritt 4: Benötigte Software installieren

```bash
# Alle benötigten Pakete installieren
sudo apt install -y \
    git curl wget unzip \
    samba samba-common-bin \
    lighttpd php-fpm php-cli \
    avahi-daemon avahi-utils \
    htop tree
```

## 🌐 Schritt 5: Hostname konfigurieren

```bash
# Hostname auf bilderrahmen setzen
echo "bilderrahmen" | sudo tee /etc/hostname

# /etc/hosts aktualisieren  
sudo sed -i 's/127.0.1.1.*raspberrypi/127.0.1.1\tbilderrahmen/' /etc/hosts

# mDNS für .local Domain aktivieren
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
```

## 👥 Schritt 6: Kita-Gruppen konfigurieren

### Gruppen festlegen
```bash
# Beispiel für 5 Gruppen (anpassen nach Bedarf)
GROUPS=("käfer" "bienen" "schmetterlinge" "frösche" "mäuse")

# Oder interaktiv eingeben:
echo "Gib deine Kita-Gruppennamen ein (ohne Umlaute):"
GROUPS=()
for i in {1..5}; do
    read -p "Gruppe $i: " group_name
    # Sanitisieren (Kleinbuchstaben, keine Sonderzeichen)
    clean_name=$(echo "$group_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    GROUPS+=("$clean_name")
done
```

### Ordnerstruktur erstellen
```bash
# Haupt-Fotos-Ordner
mkdir -p ~/Fotos

# Für jede Gruppe Monats-Struktur erstellen
current_year=$(date +%Y)
current_month=$(date +%m)

for group in "${GROUPS[@]}"; do
    echo "Erstelle Struktur für: $group"

    # Aktueller Monat + nächste 3 Monate
    for i in {0..3}; do
        month_date=$(date -d "+$i month" +%Y/%m)
        mkdir -p ~/Fotos/$group/$month_date
    done

    # README-Datei erstellen
    cat > ~/Fotos/$group/README.txt << EOF
Willkommen bei der $group Gruppe!

📅 Monatsweise Sortierung:
   $group/$current_year/$current_month/  ← Aktueller Monat

📱 Tablet-URL:
   http://bilderrahmen.local/Fotos/$group

💻 Windows-Zugriff:
   \\\\bilderrahmen.local\\Fotos\\$group

📸 Neue Fotos werden automatisch sortiert!
EOF
done

# Berechtigungen setzen
chmod -R 755 ~/Fotos
```

## 💾 Schritt 7: Samba-Server konfigurieren

### Samba installieren und konfigurieren
```bash
# Backup der Standard-Konfiguration
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Kita-Konfiguration hinzufügen
sudo tee -a /etc/samba/smb.conf << EOF

# ================================================================
# Bilderrahmen-Kita Freigaben
# ================================================================

[Fotos]
    comment = Kita Fotos - Alle Gruppen
    path = $HOME/Fotos
    writeable = yes
    browseable = yes
    create mask = 0664
    directory mask = 0775
    public = no
    valid users = $KITA_USER
    force user = pi
    force group = pi

EOF

# Einzelne Gruppen-Freigaben
for group in "${GROUPS[@]}"; do
    sudo tee -a /etc/samba/smb.conf << EOF
[$group]
    comment = Kita Gruppe: $group
    path = $HOME/Fotos/$group
    writeable = yes
    browseable = yes  
    create mask = 0664
    directory mask = 0775
    public = no
    valid users = $KITA_USER
    force user = pi
    force group = pi

EOF
done
```

### Samba-Benutzer erstellen
```bash
# Samba-Passwort für Kita-User setzen
echo -e "$KITA_PASS\n$KITA_PASS" | sudo smbpasswd -s -a "$KITA_USER"

# Samba-Dienste aktivieren
sudo systemctl enable smbd nmbd
sudo systemctl restart smbd nmbd

# Konfiguration testen
sudo testparm -s
```

## 🌐 Schritt 8: Webserver einrichten

### Lighttpd und PHP konfigurieren
```bash
# PHP-Version ermitteln
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)

# PHP-FPM für Lighttpd aktivieren
sudo lighttpd-enable-mod fastcgi
sudo lighttpd-enable-mod fastcgi-php

# Web-Verzeichnisse erstellen
sudo mkdir -p /var/www/html/{Fotos,scripts}

# Symlink zu Fotos-Ordner
sudo ln -sf $HOME/Fotos /var/www/html/Fotos

# Berechtigungen setzen
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

### Webserver-Dienste starten
```bash
# PHP-FPM und Lighttpd starten
sudo systemctl enable php${PHP_VERSION}-fpm lighttpd
sudo systemctl restart php${PHP_VERSION}-fpm lighttpd

# Test der Webserver-Funktionalität
curl -I http://localhost
```

## 📱 Schritt 9: Foto-API erstellen

### PHP-Script für Bilderverwaltung
```bash
# Erlaubte Gruppen für PHP (Array erstellen)
ALLOWED_FOLDERS=""
for i in "${!GROUPS[@]}"; do
    if [ $i -gt 0 ]; then
        ALLOWED_FOLDERS+=", "
    fi
    ALLOWED_FOLDERS+="'${GROUPS[i]}'"
done

# get_images.php erstellen
sudo tee /var/www/html/scripts/get_images.php << EOF
<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

\$folder = isset(\$_GET['folder']) ? \$_GET['folder'] : '${GROUPS[0]}';
\$month = isset(\$_GET['month']) ? \$_GET['month'] : 'all';

// Erlaubte Ordner
\$allowedFolders = [$ALLOWED_FOLDERS];
if (!in_array(\$folder, \$allowedFolders)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Ungültiger Ordner']);
    exit;
}

\$basePath = '$HOME/Fotos/' . \$folder;

// Spezifischer Monat
if (\$month && \$month !== 'all') {
    \$basePath .= '/' . \$month;
}

if (!is_dir(\$basePath)) {
    echo json_encode(['success' => false, 'error' => 'Ordner nicht gefunden']);
    exit;
}

// Bilder sammeln
\$images = [];
\$allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

function scanImagesRecursive(\$dir, \$relativePath = '') {
    global \$images, \$allowedExtensions;

    \$files = scandir(\$dir);
    if (\$files === false) return;

    foreach (\$files as \$file) {
        if (\$file === '.' || \$file === '..' || \$file === 'README.txt') continue;

        \$fullPath = \$dir . '/' . \$file;
        \$relativeFile = \$relativePath ? \$relativePath . '/' . \$file : \$file;

        if (is_dir(\$fullPath)) {
            scanImagesRecursive(\$fullPath, \$relativeFile);
        } elseif (is_file(\$fullPath)) {
            \$ext = strtolower(pathinfo(\$file, PATHINFO_EXTENSION));
            if (in_array(\$ext, \$allowedExtensions)) {
                \$monthPath = dirname(\$relativeFile);
                if (\$monthPath === '.') \$monthPath = 'ungrouped';

                \$images[] = [
                    'name' => \$file,
                    'path' => \$relativeFile,
                    'size' => filesize(\$fullPath),
                    'modified' => filemtime(\$fullPath),
                    'month' => \$monthPath
                ];
            }
        }
    }
}

scanImagesRecursive(\$basePath);

// Nach Datum sortieren
usort(\$images, function(\$a, \$b) {
    return \$b['modified'] - \$a['modified'];
});

echo json_encode([
    'success' => true,
    'images' => \$images,
    'count' => count(\$images),
    'folder' => \$folder,
    'month' => \$month,
    'generated' => date('Y-m-d H:i:s')
]);
?>
EOF
```

## 📅 Schritt 10: Automatisches Monats-Management

### Script für monatliche Ordner-Erstellung
```bash
# Monats-Management-Script erstellen
tee ~/create_month_folders.sh << EOF
#!/bin/bash
# Automatische Monats-Ordner-Erstellung

FOTOS_DIR="$HOME/Fotos"
CURRENT_MONTH=\$(date +%Y/%m)
NEXT_MONTH=\$(date -d "+1 month" +%Y/%m)

# Für alle Gruppen
for group in ${GROUPS[*]}; do
    mkdir -p "\$FOTOS_DIR/\$group/\$CURRENT_MONTH"
    mkdir -p "\$FOTOS_DIR/\$group/\$NEXT_MONTH"
    echo "Ordner erstellt: \$group/\$CURRENT_MONTH und \$group/\$NEXT_MONTH"
done

# Berechtigungen korrigieren
chmod -R 755 "\$FOTOS_DIR"
EOF

chmod +x ~/create_month_folders.sh

# Cronjob für monatliche Ausführung (1. Tag des Monats, 2 Uhr)
(crontab -l 2>/dev/null; echo "0 2 1 * * $HOME/create_month_folders.sh") | crontab -
```

## 📋 Schritt 11: Web-Dateien installieren

### HTML-Dateien vom Repository herunterladen
```bash
# Temporäres Verzeichnis
TEMP_DIR="/tmp/bilderrahmen-install"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Repository herunterladen
curl -sSL "https://github.com/BratwurstPeter77/Bilderrahmen-Kita/archive/refs/heads/main.zip" -o bilderrahmen.zip
unzip -q bilderrahmen.zip
cd Bilderrahmen-Kita-main

# HTML-Dateien kopieren
sudo cp scripts/slideshow.html /var/www/html/scripts/
sudo cp scripts/verwaltung.html /var/www/html/scripts/

# Verwaltungs-HTML für deine Gruppen anpassen
GROUPS_JS=""
for i in "${!GROUPS[@]}"; do
    if [ $i -gt 0 ]; then
        GROUPS_JS+=", "
    fi
    GROUPS_JS+="'${GROUPS[i]}'"
done

sudo sed -i "s/const folders = \[.*\];/const folders = [$GROUPS_JS];/" /var/www/html/scripts/verwaltung.html

# Berechtigungen setzen
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 644 /var/www/html/scripts/*.html

# Aufräumen
cd /
rm -rf "$TEMP_DIR"
```

### Index-Seite erstellen (Weiterleitung zur Verwaltung)
```bash
sudo tee /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=/scripts/verwaltung.html">
    <title>Bilderrahmen-Kita</title>
</head>
<body>
    <p>Weiterleitung zur <a href="/scripts/verwaltung.html">Verwaltung</a>...</p>
</body>
</html>
EOF
```

## ✅ Schritt 12: Installation testen

### Funktionalitäts-Tests
```bash
# 1. Hostname-Test
ping -c 3 bilderrahmen.local

# 2. Samba-Test
smbclient -L bilderrahmen.local -U "$KITA_USER"

# 3. Webserver-Test
curl -s http://bilderrahmen.local | head

# 4. PHP-API-Test
curl -s "http://bilderrahmen.local/scripts/get_images.php?folder=${GROUPS[0]}" | head

# 5. Ordner-Struktur prüfen
tree ~/Fotos -L 3
```

### Netzwerk-Erreichbarkeit testen
```bash
# IP-Adresse anzeigen
hostname -I

# Netzwerk-Services prüfen
sudo systemctl status smbd lighttpd avahi-daemon
```

## 📱 Schritt 13: Tablets konfigurieren

### Für jedes der 5 Tablets

1. **WLAN** mit Kita-Netzwerk verbinden
2. **Browser öffnen** (Chrome, Firefox, Safari)
3. **Slideshow-URL eingeben:**
   ```
   Tablet 1: http://bilderrahmen.local/Fotos/käfer
   Tablet 2: http://bilderrahmen.local/Fotos/bienen  
   Tablet 3: http://bilderrahmen.local/Fotos/schmetterlinge
   Tablet 4: http://bilderrahmen.local/Fotos/frösche
   Tablet 5: http://bilderrahmen.local/Fotos/mäuse
   ```

4. **Vollbild aktivieren** (meist F11 oder Browser-Menü)
5. **Lesezeichen setzen** für schnellen Zugriff
6. **Auto-Refresh deaktivieren** falls störend

### Tablet-Einstellungen optimieren
- **Bildschirmhelligkeit** auf 70-80% (Stromsparen)
- **Auto-Lock deaktivieren** oder auf 30 Minuten
- **Benachrichtigungen stumm** während Slideshow
- **WLAN-Schlaf deaktivieren** (Einstellungen → WLAN → Erweitert)

## 🔧 Schritt 14: Finale Konfiguration

### Firewall-Einstellungen (optional)
```bash
# UFW Firewall aktivieren und Ports öffnen
sudo ufw enable
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 445/tcp   # SMB
sudo ufw allow 5353/udp  # mDNS
sudo ufw allow ssh       # SSH für Wartung
```

### Automatische Updates (optional aber empfohlen)
```bash
# Unattended-upgrades für Sicherheits-Updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Wöchentlicher Neustart (Sonntag 3 Uhr)
(crontab -l 2>/dev/null; echo "0 3 * * 0 sudo reboot") | crontab -
```

### System-Monitoring einrichten
```bash
# Log-Rotation für Samba
sudo tee /etc/logrotate.d/samba-kita << EOF
/var/log/samba/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
```

## 🏁 Installation abgeschlossen!

### Zugriffs-URLs notieren:
```
🌐 Web-Verwaltung:    http://bilderrahmen.local
📱 Slideshow Käfer:   http://bilderrahmen.local/Fotos/käfer
📱 Slideshow Bienen:  http://bilderrahmen.local/Fotos/bienen
💻 Windows-Zugriff:   \\bilderrahmen.local\Fotos
👤 Benutzername:      [Dein erstellter Kita-User]
🔑 Passwort:          [Dein erstelltes Kita-Passwort]
```

### Nächste Schritte:
1. **Android-Apps konfigurieren** (siehe [SMBSync2-Anleitung](SMBSync2-Anleitung.md))
2. **Testbilder hochladen** über Windows oder Android
3. **Tablets aufstellen** und Slideshows testen
4. **Erzieher schulen** in der Bedienung

## 🛠️ Fehlerbehebung

### Häufige Probleme nach Installation:

**"bilderrahmen.local nicht erreichbar"**
```bash
# mDNS-Status prüfen
sudo systemctl status avahi-daemon

# Hostname prüfen
hostname
cat /etc/hostname

# Router-Einstellungen prüfen (mDNS aktiviert?)
```

**"Samba-Verbindung fehlgeschlagen"**
```bash
# Samba-Status prüfen
sudo systemctl status smbd

# Benutzer-Liste anzeigen
sudo pdbedit -L

# Konfiguration testen
sudo testparm -s
```

**"PHP-Script gibt Fehler"**
```bash
# PHP-Logs prüfen
sudo tail -f /var/log/lighttpd/error.log

# PHP-FPM Status
sudo systemctl status php*-fpm

# Datei-Berechtigungen prüfen
ls -la /var/www/html/scripts/
```

**"Fotos werden nicht angezeigt"**
```bash
# Ordner-Berechtigungen prüfen
ls -la ~/Fotos/

# Symlink prüfen
ls -la /var/www/html/Fotos

# Bildformate prüfen
file ~/Fotos/käfer/2025/10/*
```

Bei weiteren Problemen: **Log-Dateien sammeln** und Support kontaktieren:
```bash
# System-Informationen sammeln
sudo journalctl --since "1 hour ago" > ~/system.log
sudo tail -100 /var/log/samba/log.smbd > ~/samba.log
sudo tail -100 /var/log/lighttpd/error.log > ~/web.log
```

---

**Support:** Bei Problemen Screenshots und Log-Dateien an die IT-Verwaltung senden.
