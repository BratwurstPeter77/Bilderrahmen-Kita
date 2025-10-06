#!/bin/bash
#
# Bilderrahmen-Kita - Automatische Installation mit benutzerdefinierten Gruppen
# Copyright (c) 2025 BratwurstPeter77
# Licensed under the MIT License
#
# GitHub: https://github.com/BratwurstPeter77/Bilderrahmen-Kita
# Installation: curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash
#

set -e  # Bei Fehlern stoppen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Globale Variablen
declare -a GROUP_NAMES=()
GROUP_COUNT=0
SCRIPT_VERSION="1.0.0"
KITA_USERNAME=""
KITA_PASSWORD=""

# Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNUNG]${NC} $1"
}

log_error() {
    echo -e "${RED}[FEHLER]${NC} $1"
}

log_step() {
    echo -e "${CYAN}==>${NC} $1"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Banner anzeigen
show_banner() {
    echo -e "${PURPLE}"
    echo "================================================================"
    echo "🖼️  BILDERRAHMEN-KITA - INSTALLATION v${SCRIPT_VERSION}"
    echo "================================================================"
    echo -e "${NC}"
    echo "🎯 Digitaler Bilderrahmen für Kindergärten"
    echo "📱 Optimiert für 5 Tablets mit automatischer Foto-Sortierung"
    echo "📅 Monatsweise Organisation für einfache Verwaltung"
    echo
}

# Eingabe sanitisieren (keine Umlaute, Sonderzeichen)
sanitize_input() {
    local input="$1"
    # Umlaute und Sonderzeichen entfernen/ersetzen
    local sanitized=$(echo "$input" | \
        sed 's/[äÄ]/ae/g; s/[öÖ]/oe/g; s/[üÜ]/ue/g; s/[ß]/ss/g' | \
        sed 's/[^a-zA-Z0-9]//g' | \
        tr '[:upper:]' '[:lower:]')
    echo "$sanitized"
}

# Prüfen ob Name bereits existiert
name_exists() {
    local name="$1"
    for existing in "${GROUP_NAMES[@]}"; do
        if [[ "$existing" == "$name" ]]; then
            return 0
        fi
    done
    return 1
}

# Benutzer-Anmeldedaten erstellen
create_user_credentials() {
    log_header "👤 BENUTZER-ANMELDEDATEN"
    echo
    echo "Erstelle Benutzername und Passwort für:"
    echo "  📱 Android-App Zugriff"
    echo "  💻 Windows Netzlaufwerk"
    echo "  🌐 Tablet-Browser Verwaltung"
    echo

    # Benutzername eingeben
    while true; do
        read -p "👤 Benutzername eingeben (nur Buchstaben/Zahlen): " username_input

        # Validierung
        if [[ -z "$username_input" ]]; then
            log_error "Benutzername darf nicht leer sein."
            continue
        fi

        # Sanitisieren
        KITA_USERNAME=$(sanitize_input "$username_input")

        if [[ -z "$KITA_USERNAME" ]]; then
            log_error "Ungültiger Benutzername. Nur Buchstaben und Zahlen erlaubt."
            continue
        fi

        if [[ ${#KITA_USERNAME} -lt 3 ]]; then
            log_error "Benutzername muss mindestens 3 Zeichen lang sein."
            continue
        fi

        # Anzeigen was sanitisiert wurde
        if [[ "$username_input" != "$KITA_USERNAME" ]]; then
            log_info "Eingabe: '$username_input' → Verwendet: '$KITA_USERNAME'"
        else
            log_success "Benutzername: '$KITA_USERNAME'"
        fi

        break
    done

    # Passwort eingeben
    while true; do
        echo
        read -s -p "🔑 Passwort eingeben (mindestens 6 Zeichen): " password1
        echo

        if [[ ${#password1} -lt 6 ]]; then
            log_error "Passwort muss mindestens 6 Zeichen lang sein."
            continue
        fi

        read -s -p "🔑 Passwort wiederholen: " password2
        echo

        if [[ "$password1" != "$password2" ]]; then
            log_error "Passwörter stimmen nicht überein."
            continue
        fi

        KITA_PASSWORD="$password1"
        log_success "Passwort erfolgreich gesetzt"
        break
    done

    echo
    log_info "Anmeldedaten für später notieren:"
    echo "   👤 Benutzername: $KITA_USERNAME"
    echo "   🔑 Passwort: $KITA_PASSWORD"
    echo
    read -p "📝 Daten notiert? Weiter mit Enter..."
}

# Gruppennamen validieren und eingeben
get_group_names() {
    log_header "📋 GRUPPEN-KONFIGURATION"
    echo
    echo "Erstelle Kita-Gruppen für die 5 Tablets:"
    echo "  • 🐛 Käfer    • 🐝 Bienen    • 🦋 Schmetterlinge    • 🐸 Frösche    • 🐻 Bären"
    echo
    echo "Jede Gruppe bekommt:"
    echo "  📁 Eigenen Foto-Ordner mit Monats-Unterordnern"
    echo "  📱 Eigene Tablet-URL: bilderrahmen.local/Fotos/GRUPPENNAME"
    echo "  📅 Automatische Sortierung nach Jahr/Monat"
    echo
    echo "⚠️  Regeln für Gruppennamen:"
    echo "   • Nur Buchstaben und Zahlen (a-z, A-Z, 0-9)"
    echo "   • Keine Umlaute (ä→ae, ö→oe, ü→ue) oder Sonderzeichen"
    echo "   • Werden automatisch zu Kleinbuchstaben"
    echo "   • Beispiele: käfer, bienen, schmetterlinge, frösche, mäuse"
    echo

    # Anzahl der Gruppen (Standard 5 für 5 Tablets)
    while true; do
        read -p "🔢 Anzahl Gruppen (empfohlen 5 für 5 Tablets): " GROUP_COUNT

        # Standard setzen wenn leer
        if [[ -z "$GROUP_COUNT" ]]; then
            GROUP_COUNT=5
            log_info "Standard verwendet: 5 Gruppen"
            break
        fi

        # Validierung
        if [[ "$GROUP_COUNT" =~ ^[0-9]+$ ]] && [ "$GROUP_COUNT" -ge 1 ] && [ "$GROUP_COUNT" -le 10 ]; then
            break
        else
            log_error "Bitte Zahl zwischen 1 und 10 eingeben."
        fi
    done

    echo
    log_info "Erstelle $GROUP_COUNT Gruppen..."
    echo

    # Gruppennamen eingeben
    for ((i=1; i<=GROUP_COUNT; i++)); do
        while true; do
            read -p "📝 Name für Gruppe $i/$GROUP_COUNT: " group_input

            # Standard-Namen vorschlagen wenn leer
            if [[ -z "$group_input" ]]; then
                case $i in
                    1) group_input="käfer" ;;
                    2) group_input="bienen" ;;
                    3) group_input="schmetterlinge" ;;
                    4) group_input="frösche" ;;
                    5) group_input="mäuse" ;;
                    *) group_input="gruppe$i" ;;
                esac
                log_info "Standard verwendet: '$group_input'"
            fi

            # Eingabe sanitisieren
            sanitized_name=$(sanitize_input "$group_input")

            # Validierung
            if [[ -z "$sanitized_name" ]] || [[ ${#sanitized_name} -lt 2 ]]; then
                log_error "Name muss mindestens 2 gültige Zeichen haben."
                continue
            fi

            # Duplikat prüfen
            if name_exists "$sanitized_name"; then
                log_error "Name '$sanitized_name' bereits vergeben."
                continue
            fi

            # Name akzeptiert
            GROUP_NAMES+=("$sanitized_name")

            # Änderungen anzeigen
            if [[ "$group_input" != "$sanitized_name" ]]; then
                log_info "Eingabe: '$group_input' → Verwendet: '$sanitized_name'"
            else
                log_success "Gruppe '$sanitized_name' hinzugefügt"
            fi

            break
        done
    done

    # Übersicht
    echo
    log_header "📋 ÜBERSICHT DER GRUPPEN"
    echo
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        local group="${GROUP_NAMES[i]}"
        echo "   📱 Tablet $((i+1)): $group"
        echo "      🌐 URL: http://bilderrahmen.local/Fotos/$group"
        echo "      📁 Pfad: \\\\bilderrahmen.local\\Fotos\\$group"
        echo "      📅 Struktur: $group/2025/10/, $group/2025/11/, ..."
        echo
    done

    # Bestätigung
    while true; do
        read -p "✅ Diese $GROUP_COUNT Gruppen erstellen? (j/n): " confirm
        case $confirm in
            [JjYy]* ) 
                log_success "Gruppen bestätigt!"
                echo
                break
                ;;
            [Nn]* ) 
                log_info "Installation abgebrochen."
                exit 0
                ;;
            * ) 
                echo "Bitte 'j' für Ja oder 'n' für Nein eingeben."
                ;;
        esac
    done
}

# System prüfen
check_system() {
    log_step "System-Kompatibilität prüfen"

    # Root-Check
    if [[ $EUID -eq 0 ]]; then
        log_error "Bitte NICHT als root ausführen!"
        exit 1
    fi

    # Debian/Ubuntu prüfen
    if ! command -v apt &> /dev/null; then
        log_error "Nur auf Debian/Ubuntu/Raspberry Pi OS unterstützt"
        exit 1
    fi

    # Raspberry Pi erkennen
    if grep -q "Raspberry Pi\|BCM" /proc/cpuinfo 2>/dev/null; then
        local pi_model=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | sed 's/^ *//')
        log_success "Raspberry Pi erkannt: $pi_model"
    else
        log_warning "Nicht auf Raspberry Pi - Installation trotzdem möglich"
    fi

    # Speicherplatz prüfen (mindestens 10GB für Fotos)
    local disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_free -lt 10 ]]; then
        log_error "Zu wenig Speicherplatz. Mindestens 10GB erforderlich."
        exit 1
    else
        log_success "Freier Speicherplatz: ${disk_free}GB"
    fi

    echo
}

# Abhängigkeiten installieren
install_dependencies() {
    log_step "System-Pakete installieren"

    sudo apt update -qq

    local packages=(
        "git" "curl" "wget" "unzip"
        "samba" "samba-common-bin" 
        "lighttpd" "php-fpm" "php-cli"
        "avahi-daemon" "avahi-utils"
        "htop" "tree"
    )

    log_info "Installiere: ${packages[*]}"

    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package "; then
            echo -n "  📦 $package ... "
            if sudo apt install -y -qq "$package"; then
                echo "✅"
            else
                echo "❌"
                exit 1
            fi
        else
            echo "  ✅ $package (bereits installiert)"
        fi
    done

    log_success "Alle Pakete installiert"
    echo
}

# Hostname setzen
setup_hostname() {
    log_step "Hostname konfigurieren"

    # bilderrahmen.local einrichten
    local current_hostname=$(hostname)
    local target_hostname="bilderrahmen"

    if [[ "$current_hostname" != "$target_hostname" ]]; then
        log_info "Ändere Hostname von '$current_hostname' zu '$target_hostname'"

        # Hostname setzen
        echo "$target_hostname" | sudo tee /etc/hostname > /dev/null

        # /etc/hosts aktualisieren
        sudo sed -i "s/127.0.1.1.*$current_hostname/127.0.1.1\t$target_hostname/" /etc/hosts

        # Avahi für .local Domain
        sudo systemctl enable avahi-daemon --quiet
        sudo systemctl restart avahi-daemon

        log_success "Hostname gesetzt: $target_hostname.local"
    else
        log_success "Hostname bereits korrekt: $target_hostname.local"
    fi

    echo
}

# Repository herunterladen
download_files() {
    local TEMP_DIR="/tmp/bilderrahmen-install-$$"
    local REPO_URL="https://github.com/BratwurstPeter77/Bilderrahmen-Kita"

    log_step "Dateien herunterladen"

    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # Repository herunterladen
    if curl -sSL "$REPO_URL/archive/refs/heads/main.zip" -o bilderrahmen.zip; then
        log_success "Download erfolgreich"
    else
        log_error "Download fehlgeschlagen"
        exit 1
    fi

    unzip -q bilderrahmen.zip
    cd Bilderrahmen-Kita-main

    # Dateien installieren
    sudo mkdir -p /var/www/html/{Fotos,scripts}
    sudo cp scripts/* /var/www/html/scripts/
    sudo cp config/* /tmp/

    # Berechtigungen
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html

    log_success "Dateien installiert"

    # Aufräumen
    cd /
    rm -rf "$TEMP_DIR"
    echo
}

# Ordnerstruktur für monatsweise Sortierung erstellen
create_monthly_structure() {
    log_step "Monatsweise Ordnerstruktur erstellen"

    # Haupt-Fotos-Ordner
    mkdir -p "$HOME/Fotos"

    # Aktueller Monat
    local current_year=$(date +%Y)
    local current_month=$(date +%m)

    # Für jede Gruppe Ordnerstruktur erstellen
    for group_name in "${GROUP_NAMES[@]}"; do
        # Aktuelles Jahr/Monat
        mkdir -p "$HOME/Fotos/$group_name/$current_year/$current_month"

        # Nächste 3 Monate vorerstellen
        for i in {1..3}; do
            local next_date=$(date -d "+$i month" +%Y/%m)
            mkdir -p "$HOME/Fotos/$group_name/$next_date"
        done

        # Willkommens-Datei
        cat > "$HOME/Fotos/$group_name/README.txt" << EOF
Willkommen bei der $group_name Gruppe!

📅 Monatsweise Sortierung:
   $group_name/$current_year/$current_month/  ← Aktueller Monat
   $group_name/$current_year/$(date -d "+1 month" +%m)/  ← Nächster Monat

📱 Tablet-URL:
   http://bilderrahmen.local/Fotos/$group_name

💻 Windows-Zugriff:
   \\\\bilderrahmen.local\\Fotos\\$group_name

📸 Neue Fotos werden automatisch im aktuellen Monat sortiert!
EOF

        log_success "📁 $group_name (mit Monats-Ordnern)"
    done

    # Webserver-Symlink
    sudo ln -sf "$HOME/Fotos" /var/www/html/Fotos

    # Berechtigungen
    chmod -R 755 "$HOME/Fotos"

    log_success "Monatsweise Struktur für alle ${#GROUP_NAMES[@]} Gruppen erstellt"
    echo
}

# Samba für benutzerdefinierten User konfigurieren
setup_samba() {
    log_step "Samba-Server konfigurieren"

    # Backup
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)

    # Konfiguration erstellen
    {
        echo ""
        echo "# ================================================================"
        echo "# Bilderrahmen-Kita Freigaben ($(date))"
        echo "# ================================================================"
        echo ""
        echo "[Fotos]"
        echo "    comment = Kita Fotos - Alle Gruppen"
        echo "    path = $HOME/Fotos"
        echo "    writeable = yes"
        echo "    browseable = yes"
        echo "    create mask = 0664"
        echo "    directory mask = 0775"
        echo "    public = no"
        echo "    valid users = $KITA_USERNAME"
        echo "    force user = $USER"
        echo "    force group = $USER"
        echo ""

        # Einzelne Gruppen-Freigaben
        for group_name in "${GROUP_NAMES[@]}"; do
            echo "[$group_name]"
            echo "    comment = Kita Gruppe: $group_name"
            echo "    path = $HOME/Fotos/$group_name"
            echo "    writeable = yes"
            echo "    browseable = yes"
            echo "    create mask = 0664"
            echo "    directory mask = 0775"
            echo "    public = no"
            echo "    valid users = $KITA_USERNAME"
            echo "    force user = $USER"
            echo "    force group = $USER"
            echo ""
        done
    } | sudo tee -a /etc/samba/smb.conf > /dev/null

    # Samba-Benutzer erstellen
    log_info "Erstelle Samba-Benutzer '$KITA_USERNAME'..."

    # System-User erstellen falls nicht vorhanden
    if ! id "$KITA_USERNAME" &>/dev/null; then
        sudo useradd -r -s /bin/false "$KITA_USERNAME"
    fi

    # Samba-Passwort setzen
    (echo "$KITA_PASSWORD"; echo "$KITA_PASSWORD") | sudo smbpasswd -s -a "$KITA_USERNAME"

    # Samba starten
    sudo systemctl enable smbd nmbd --quiet
    sudo systemctl restart smbd nmbd

    # Test
    if sudo testparm -s > /dev/null 2>&1; then
        log_success "Samba konfiguriert für Benutzer '$KITA_USERNAME'"
    else
        log_warning "Samba-Konfiguration hat Warnungen (meist unkritisch)"
    fi

    echo
}

# PHP-Script für monatsweise Foto-API
create_photo_api() {
    log_step "Foto-API erstellen"

    # Erlaubte Ordner für PHP
    local allowed_folders=""
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        if [ $i -gt 0 ]; then
            allowed_folders+=", "
        fi
        allowed_folders+="'${GROUP_NAMES[i]}'"
    done

    # PHP-API mit Monats-Unterstützung
    cat > /var/www/html/scripts/get_images.php << EOF
<?php
/*
 * Bilderrahmen-Kita - Foto API mit Monats-Sortierung
 * Copyright (c) 2025 BratwurstPeter77
 * Licensed under the MIT License
 */

header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

\$folder = isset(\$_GET['folder']) ? \$_GET['folder'] : '${GROUP_NAMES[0]}';
\$month = isset(\$_GET['month']) ? \$_GET['month'] : date('Y/m'); // Format: 2025/10

// Erlaubte Ordner
\$allowedFolders = [$allowed_folders];
if (!in_array(\$folder, \$allowedFolders)) {
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'error' => 'Ungültiger Ordner',
        'allowed' => \$allowedFolders
    ]);
    exit;
}

\$basePath = '/home/$USER/Fotos/' . \$folder;

// Wenn spezifischer Monat angefragt
if (\$month && \$month !== 'all') {
    \$basePath .= '/' . \$month;
}

// Ordner existiert?
if (!is_dir(\$basePath)) {
    echo json_encode([
        'success' => false, 
        'error' => 'Ordner nicht gefunden: ' . \$basePath,
        'month' => \$month
    ]);
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
        if (\$file === '.' || \$file === '..') continue;

        \$fullPath = \$dir . '/' . \$file;
        \$relativeFile = \$relativePath ? \$relativePath . '/' . \$file : \$file;

        if (is_dir(\$fullPath)) {
            // Rekursiv in Unterordner (Monate)
            scanImagesRecursive(\$fullPath, \$relativeFile);
        } elseif (is_file(\$fullPath)) {
            \$ext = strtolower(pathinfo(\$file, PATHINFO_EXTENSION));
            if (in_array(\$ext, \$allowedExtensions)) {
                \$images[] = [
                    'name' => \$file,
                    'path' => \$relativeFile,
                    'size' => filesize(\$fullPath),
                    'modified' => filemtime(\$fullPath),
                    'month' => dirname(\$relativeFile) // Jahr/Monat Info
                ];
            }
        }
    }
}

// Bilder scannen
scanImagesRecursive(\$basePath);

// Nach Datum sortieren (neueste zuerst)
usort(\$images, function(\$a, \$b) {
    return \$b['modified'] - \$a['modified'];
});

echo json_encode([
    'success' => true,
    'images' => \$images,
    'count' => count(\$images),
    'folder' => \$folder,
    'month' => \$month,
    'basePath' => \$basePath,
    'generated' => date('Y-m-d H:i:s')
]);
?>
EOF

    # Berechtigungen
    sudo chown www-data:www-data /var/www/html/scripts/get_images.php
    sudo chmod 644 /var/www/html/scripts/get_images.php

    log_success "Foto-API mit Monats-Unterstützung erstellt"
    echo
}

# Webserver konfigurieren
setup_webserver() {
    log_step "Webserver konfigurieren"

    # PHP-FPM aktivieren
    local php_version=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)

    sudo lighttpd-enable-mod fastcgi > /dev/null 2>&1
    sudo lighttpd-enable-mod fastcgi-php > /dev/null 2>&1

    # Webserver starten
    sudo systemctl enable lighttpd php${php_version}-fpm --quiet
    sudo systemctl restart php${php_version}-fpm lighttpd

    # Test
    if curl -s http://localhost/scripts/get_images.php?folder=${GROUP_NAMES[0]} > /dev/null; then
        log_success "Webserver läuft auf http://bilderrahmen.local"
    else
        log_warning "Webserver-Test fehlgeschlagen (möglicherweise noch nicht bereit)"
    fi

    echo
}

# Automatisches Monats-Management Script
create_month_manager() {
    log_step "Monats-Management einrichten"

    # Script für automatische Monats-Ordner-Erstellung
    cat > "$HOME/create_month_folders.sh" << EOF
#!/bin/bash
#
# Automatische Erstellung neuer Monats-Ordner
# Wird monatlich ausgeführt
#

FOTOS_DIR="$HOME/Fotos"
CURRENT_MONTH=\$(date +%Y/%m)
NEXT_MONTH=\$(date -d "+1 month" +%Y/%m)

# Für alle Gruppen
for group in ${GROUP_NAMES[*]}; do
    mkdir -p "\$FOTOS_DIR/\$group/\$CURRENT_MONTH"
    mkdir -p "\$FOTOS_DIR/\$group/\$NEXT_MONTH"

    echo "Ordner erstellt: \$group/\$CURRENT_MONTH und \$group/\$NEXT_MONTH"
done

# Berechtigungen korrigieren
chmod -R 755 "\$FOTOS_DIR"
EOF

    chmod +x "$HOME/create_month_folders.sh"

    # Cronjob für monatliche Ausführung
    (crontab -l 2>/dev/null; echo "0 2 1 * * $HOME/create_month_folders.sh") | crontab -

    log_success "Automatisches Monats-Management eingerichtet"
    echo
}

# IP-Adresse ermitteln
get_ip_address() {
    local IP=$(hostname -I | awk '{print $1}')
    if [[ -z "$IP" ]]; then
        IP="localhost"
    fi
    echo "$IP"
}

# Installation abschließen
finish_installation() {
    local IP=$(get_ip_address)

    echo
    log_header "🎉 INSTALLATION ERFOLGREICH!"
    echo
    echo "================================================================"
    echo "🖼️  BILDERRAHMEN-KITA MIT ${#GROUP_NAMES[@]} GRUPPEN BEREIT!"
    echo "================================================================"
    echo
    echo "🌐 **Verwaltung:** http://bilderrahmen.local"
    echo "📱 **Tablet-URLs:**"
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        local group="${GROUP_NAMES[i]}"
        echo "   Tablet $((i+1)) ($group): http://bilderrahmen.local/Fotos/$group"
    done
    echo
    echo "🔐 **Anmeldedaten für Android/Windows:**"
    echo "   👤 Benutzername: $KITA_USERNAME"
    echo "   🔑 Passwort: $KITA_PASSWORD"
    echo
    echo "💻 **Windows-Zugriff:**"
    echo "   📁 Alle Fotos: \\\\bilderrahmen.local\\Fotos"
    for group in "${GROUP_NAMES[@]}"; do
        echo "   📁 $group: \\\\bilderrahmen.local\\$group"
    done
    echo
    echo "📅 **Monats-Struktur (Beispiel):**"
    echo "   📁 ${GROUP_NAMES[0]}/$(date +%Y/%m)/    ← Aktuelle Fotos"
    echo "   📁 ${GROUP_NAMES[0]}/$(date -d "+1 month" +%Y/%m)/    ← Nächster Monat"
    echo "   📁 ${GROUP_NAMES[0]}/$(date -d "-1 month" +%Y/%m)/    ← Letzter Monat"
    echo
    echo "🚀 **Nächste Schritte:**"
    echo "   1. 🔄 Raspberry Pi neu starten: sudo reboot"
    echo "   2. 📱 Android-Apps konfigurieren (SMBSync2 empfohlen)"
    echo "   3. 🖼️  Testbilder in Gruppen-Ordner kopieren"  
    echo "   4. 📱 Tablet-Browser öffnen und URLs testen"
    echo "   5. 🌐 Verwaltung öffnen: http://bilderrahmen.local"
    echo
    echo "📱 **Android-Apps:**"
    echo "   SMBSync2: https://play.google.com/store/apps/details?id=com.sentaroh.android.SMBSync2"
    echo "   PhotoSync: https://play.google.com/store/apps/details?id=com.touchbyte.photosync"
    echo
    echo "================================================================"
    echo "🎯 Viel Erfolg mit dem Bilderrahmen-System!"
    echo "================================================================"
}

# Hauptinstallation
main() {
    clear
    show_banner
    check_system
    create_user_credentials
    get_group_names
    install_dependencies
    setup_hostname
    download_files
    create_monthly_structure
    setup_samba
    create_photo_api
    setup_webserver
    create_month_manager
    finish_installation
}

# Script ausführen
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'log_error "Installation abgebrochen. Zeile: $LINENO"' ERR
    main "$@"
fi
