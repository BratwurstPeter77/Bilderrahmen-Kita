#!/bin/bash
#
# Bilderrahmen-Kita - Installation mit USB-Festplatte und automatischer Foto-Sortierung
# Copyright (c) 2025 BratwurstPeter77
# Licensed under the MIT License
#
# GitHub: https://github.com/BratwurstPeter77/Bilderrahmen-Kita
# Installation: curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash
#

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Globale Variablen
declare -a GROUP_NAMES=()
GROUP_COUNT=0
SCRIPT_VERSION="1.0.0"
KITA_USERNAME=""
KITA_PASSWORD=""
USB_DEVICE=""

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
    echo "📱 Optimiert für 5 Tablets mit USB-Festplatte"
    echo "📅 Monatsweise Organisation mit automatischer Sortierung"
    echo "🕐 Tägliche Foto-Sortierung um 20:00 Uhr"
    echo
}

# System prüfen
check_system() {
    log_step "System-Kompatibilität prüfen"
    
    if [[ $EUID -eq 0 ]]; then
        log_error "Bitte NICHT als root ausführen!"
        log_error "Verwende: bash <(curl -sSL ...)"
        log_error "NICHT: sudo bash <(curl -sSL ...)"
        exit 1
    fi
    
    if ! command -v apt &> /dev/null; then
        log_error "Nur auf Debian/Ubuntu/Raspberry Pi OS unterstützt"
        exit 1
    fi
    
    if grep -q "Raspberry Pi\|BCM" /proc/cpuinfo 2>/dev/null; then
        local pi_model=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | sed 's/^ *//')
        log_success "Raspberry Pi erkannt: $pi_model"
    else
        log_warning "Nicht auf Raspberry Pi erkannt - Installation trotzdem möglich"
    fi
    
    local disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_free -lt 10 ]]; then
        log_error "Zu wenig Speicherplatz auf SD-Karte. Mindestens 10GB erforderlich."
        exit 1
    fi
    
    local ram_mb=$(free -m | awk '/^Mem:/ {print $2}')
    if [[ $ram_mb -lt 500 ]]; then
        log_warning "Wenig RAM erkannt (${ram_mb}MB). Mindestens 1GB empfohlen."
    fi
    
    log_success "System-Prüfung erfolgreich (SD: ${disk_free}GB, RAM: ${ram_mb}MB)"
    echo
}

# USB-Festplatte erkennen und einrichten
setup_usb_disk() {
    log_step "USB-Festplatte einrichten"
    
    echo "Verfügbare USB-Speichergeräte:"
    lsblk | grep -E "(sda|sdb|sdc|nvme)" | grep -v "part" || echo "Keine USB-Geräte erkannt"
    echo
    
    log_warning "WICHTIG: Alle Daten auf der USB-Festplatte werden gelöscht!"
    echo
    
    while true; do
        read -p "USB-Festplatte Gerät eingeben (z.B. sda): " device_input
        
        if [[ -z "$device_input" ]]; then
            log_error "Bitte Geräte-Name eingeben (z.B. sda)"
            continue
        fi
        
        USB_DEVICE="/dev/${device_input}"
        
        if [[ ! -b "$USB_DEVICE" ]]; then
            log_error "Gerät $USB_DEVICE nicht gefunden"
            echo "Verfügbare Geräte:"
            lsblk | grep -E "(sd[a-z]|nvme)" | head -5
            continue
        fi
        
        # Größe anzeigen
        local size=$(lsblk -b -d -n -o SIZE "$USB_DEVICE" 2>/dev/null | awk '{print int($1/1000000000)}')
        if [[ $size -lt 50 ]]; then
            log_warning "Festplatte sehr klein (${size}GB). Mindestens 100GB empfohlen."
        fi
        
        log_info "Gewählte Festplatte: $USB_DEVICE (${size}GB)"
        echo
        echo "⚠️  LETZTE WARNUNG: Alle Daten auf $USB_DEVICE werden unwiderruflich gelöscht!"
        read -p "Wirklich fortfahren? (JA/nein): " final_confirm
        
        case $final_confirm in
            "JA") break ;;
            *) 
                log_info "Installation abgebrochen - keine Daten gelöscht"
                exit 0
                ;;
        esac
    done
    
    # Festplatte formatieren
    log_info "Formatiere USB-Festplatte..."
    
    # Alle Partitionen unmounten
    sudo umount ${USB_DEVICE}* 2>/dev/null || true
    
    # Neue Partitionstabelle erstellen
    sudo fdisk "$USB_DEVICE" << EOF > /dev/null 2>&1
o
n
p
1


w
EOF
    
    sleep 2
    
    # Dateisystem erstellen
    log_info "Erstelle Dateisystem..."
    sudo mkfs.ext4 "${USB_DEVICE}1" -L "KitaFotos" -F > /dev/null 2>&1
    
    # UUID ermitteln (REPARIERT - nur erste UUID, saubere Ausgabe)
    sleep 2
    local uuid=$(sudo blkid -s UUID -o value "${USB_DEVICE}1" 2>/dev/null | head -1 | tr -d '[:space:]')
    
    if [[ -z "$uuid" ]]; then
        log_error "Konnte UUID der Festplatte nicht ermitteln"
        exit 1
    fi
    
    log_info "UUID erkannt: $uuid"
    
    # Mount-Point erstellen
    sudo mkdir -p /mnt/kita-fotos
    
    # REPARIERT: Alte kita-fotos Einträge aus fstab ENTFERNEN bevor neu hinzugefügt wird
    sudo sed -i '/kita-fotos/d' /etc/fstab
    
    # Neuen sauberen Eintrag hinzufügen
    echo "UUID=$uuid /mnt/kita-fotos ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab > /dev/null
    
    log_info "fstab aktualisiert"
    
    # Mounten
    sudo mount -a
    
    if df -h | grep -q "/mnt/kita-fotos"; then
        local mounted_size=$(df -h /mnt/kita-fotos | tail -1 | awk '{print $2}')
        log_success "USB-Festplatte erfolgreich eingerichtet ($mounted_size verfügbar)"
    else
        log_error "Fehler beim Mounten der USB-Festplatte"
        exit 1
    fi
    
    # Berechtigungen setzen (REPARIERT: $USER statt hardcoded pi)
    sudo chown -R $USER:$USER /mnt/kita-fotos
    chmod -R 755 /mnt/kita-fotos
    
    echo
}

# Eingabe sanitisieren
sanitize_input() {
    local input="$1"
    local sanitized=$(echo "$input" | \
        sed 's/[äÄ]/ae/g; s/[öÖ]/oe/g; s/[üÜ]/ue/g; s/[ß]/ss/g' | \
        sed 's/[^a-zA-Z0-9]//g' | \
        tr '[:upper:]' '[:lower:]')
    echo "$sanitized"
}

# Benutzer-Anmeldedaten erstellen
create_user_credentials() {
    log_header "👤 BENUTZER-ANMELDEDATEN ERSTELLEN"
    echo
    echo "Erstelle sichere Anmeldedaten für:"
    echo "  📱 Android-App Zugriff (SMBSync2)"
    echo "  💻 Windows Netzlaufwerk"
    echo "  🔐 Samba-Server Authentifizierung"
    echo
    
    while true; do
        read -p "👤 Benutzername eingeben (nur Buchstaben/Zahlen): " username_input
        
        if [[ -z "$username_input" ]]; then
            log_error "Benutzername darf nicht leer sein."
            continue
        fi
        
        KITA_USERNAME=$(sanitize_input "$username_input")
        
        if [[ -z "$KITA_USERNAME" ]] || [[ ${#KITA_USERNAME} -lt 3 ]]; then
            log_error "Benutzername muss mindestens 3 gültige Zeichen haben."
            log_error "Erlaubt: a-z, A-Z, 0-9 (Umlaute werden konvertiert)"
            continue
        fi
        
        if [[ "$username_input" != "$KITA_USERNAME" ]]; then
            log_info "Eingabe: '$username_input' → Verwendet: '$KITA_USERNAME'"
        fi
        
        log_success "Benutzername: '$KITA_USERNAME'"
        break
    done
    
    while true; do
        echo
        read -s -p "🔑 Passwort eingeben (mindestens 8 Zeichen): " password1
        echo
        
        if [[ ${#password1} -lt 8 ]]; then
            log_error "Passwort muss mindestens 8 Zeichen lang sein."
            continue
        fi
        
        read -s -p "🔑 Passwort wiederholen: " password2
        echo
        
        if [[ "$password1" != "$password2" ]]; then
            log_error "Passwörter stimmen nicht überein."
            continue
        fi
        
        KITA_PASSWORD="$password1"
        log_success "Passwort erfolgreich gesetzt (${#KITA_PASSWORD} Zeichen)"
        break
    done
    
    echo
    log_warning "WICHTIG: Diese Anmeldedaten für später notieren!"
    echo "   👤 Benutzername: $KITA_USERNAME"
    echo "   🔑 Passwort: $KITA_PASSWORD"
    echo
    read -p "📝 Daten sicher notiert? Weiter mit Enter..."
}


# Gruppennamen konfigurieren
get_group_names() {
    log_header "📋 KITA-GRUPPEN KONFIGURIEREN"
    echo
    echo "Erstelle individuelle Gruppen für eure Kita:"
    echo "  🐛 Käfer    🐝 Bienen    🦋 Schmetterlinge    🐸 Frösche    🐻 Bären"
    echo "  🦔 Igel     🐰 Hasen     🐭 Mäuse           🦁 Löwen      🐘 Elefanten"
    echo
    echo "Jede Gruppe bekommt:"
    echo "  📱 Eigene Tablet-URL und Slideshow"
    echo "  📁 Automatische Monats-Ordner (2025/01, 2025/02, ...)"
    echo "  💾 Separate Samba-Freigabe für Android/Windows"
    echo
    
    while true; do
        read -p "🔢 Anzahl Gruppen (empfohlen 5 für 5 Tablets): " GROUP_COUNT
        
        if [[ -z "$GROUP_COUNT" ]]; then
            GROUP_COUNT=5
            log_info "Standard verwendet: 5 Gruppen"
            break
        fi
        
        if [[ "$GROUP_COUNT" =~ ^[0-9]+$ ]] && [ "$GROUP_COUNT" -ge 1 ] && [ "$GROUP_COUNT" -le 10 ]; then
            break
        else
            log_error "Bitte Zahl zwischen 1 und 10 eingeben."
        fi
    done
    
    echo
    log_info "Erstelle $GROUP_COUNT Gruppen (Umlaute werden automatisch konvertiert):"
    echo
    
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
            
            sanitized_name=$(sanitize_input "$group_input")
            
            if [[ -z "$sanitized_name" ]] || [[ ${#sanitized_name} -lt 2 ]]; then
                log_error "Name muss mindestens 2 gültige Zeichen haben."
                continue
            fi
            
            # Duplikat prüfen
            local exists=false
            for existing in "${GROUP_NAMES[@]}"; do
                if [[ "$existing" == "$sanitized_name" ]]; then
                    exists=true
                    break
                fi
            done
            
            if $exists; then
                log_error "Name '$sanitized_name' bereits vergeben."
                continue
            fi
            
            GROUP_NAMES+=("$sanitized_name")
            
            if [[ "$group_input" != "$sanitized_name" ]]; then
                log_info "Eingabe: '$group_input' → Verwendet: '$sanitized_name'"
            else
                log_success "Gruppe '$sanitized_name' hinzugefügt"
            fi
            
            break
        done
    done
    
    echo
    log_header "📋 ÜBERSICHT DER KITA-GRUPPEN"
    echo
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        local group="${GROUP_NAMES[i]}"
        echo "   📱 Tablet $((i+1)): $group"
        echo "      🌐 URL: http://bilderrahmen.local/Fotos/$group"
        echo "      📁 Samba: \\\\bilderrahmen.local\\$group"
        echo "      📅 Struktur: $group/2025/$(date +%m)/, $group/2025/$(date -d "+1 month" +%m)/, ..."
        echo
    done
    
    while true; do
        read -p "✅ Diese $GROUP_COUNT Gruppen erstellen? (j/n): " confirm
        case $confirm in
            [JjYy]*) 
                log_success "Gruppen bestätigt! Installation wird fortgesetzt..."
                echo
                break
                ;;
            [Nn]*) 
                log_info "Installation abgebrochen."
                exit 0
                ;;
            *) 
                echo "Bitte 'j' für Ja oder 'n' für Nein eingeben."
                ;;
        esac
    done
}

# Abhängigkeiten installieren
install_dependencies() {
    log_step "System-Pakete installieren"
    echo "Dies kann 5-15 Minuten dauern..."
    echo
    
    # System aktualisieren
    log_info "Aktualisiere System-Pakete..."
    sudo apt update -qq
    sudo apt upgrade -y -qq
    
    # Benötigte Pakete
    local packages=(
        "git" "curl" "wget" "unzip"
        "samba" "samba-common-bin" 
        "lighttpd" "php-fpm" "php-cli"
        "avahi-daemon" "avahi-utils"
        "ufw" "fail2ban"
        "smartmontools" "libimage-exiftool-perl"
        "htop" "tree" "rsync"
    )
    
    log_info "Installiere Pakete: ${packages[*]}"
    echo
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package "; then
            echo -n "  📦 $package ... "
            if sudo apt install -y -qq "$package" 2>/dev/null; then
                echo "✅"
            else
                echo "❌"
                log_error "Installation von $package fehlgeschlagen"
                exit 1
            fi
        else
            echo "  ✅ $package (bereits installiert)"
        fi
    done
    
    log_success "Alle Pakete erfolgreich installiert"
    echo
}

# Hostname konfigurieren
setup_hostname() {
    log_step "Hostname auf 'bilderrahmen' setzen"
    
    local current_hostname=$(hostname)
    local target_hostname="bilderrahmen"
    
    if [[ "$current_hostname" != "$target_hostname" ]]; then
        log_info "Ändere Hostname von '$current_hostname' zu '$target_hostname'"
        
        echo "$target_hostname" | sudo tee /etc/hostname > /dev/null
        
        # /etc/hosts aktualisieren (sichere Methode)
        sudo cp /etc/hosts /etc/hosts.backup
        sudo sed -i "s/127\.0\.1\.1.*$current_hostname/127.0.1.1\t$target_hostname/" /etc/hosts
        
        # Avahi für .local Domain
        sudo systemctl enable avahi-daemon --quiet
        sudo systemctl restart avahi-daemon
        
        log_success "Hostname gesetzt: $target_hostname.local"
        log_info "Nach Neustart erreichbar unter: http://bilderrahmen.local"
    else
        log_success "Hostname bereits korrekt: $target_hostname.local"
    fi
    
    echo
}

# Ordnerstruktur mit Monats-Organisation erstellen
create_folder_structure() {
    log_step "Ordnerstruktur mit automatischer Monats-Sortierung erstellen"
    
    local current_year=$(date +%Y)
    local current_month=$(date +%m)
    
    # Für jede Gruppe Ordnerstruktur erstellen
    for group_name in "${GROUP_NAMES[@]}"; do
        # Haupt-Upload-Ordner (hier laden Erzieher direkt hoch)
        mkdir -p "/mnt/kita-fotos/$group_name"
        
        # Aktuelle und nächste 3 Monate vorbereiten
        for i in {0..3}; do
            local month_date=$(date -d "+$i month" +%Y/%m)
            mkdir -p "/mnt/kita-fotos/$group_name/$month_date"
        done
        
        # Informations-Datei erstellen
        cat > "/mnt/kita-fotos/$group_name/README.txt" << EOF
Willkommen bei der $group_name Gruppe!

💾 USB-Festplatte für beste Performance
📱 Tablet-URL: http://bilderrahmen.local/Fotos/$group_name
💻 Windows: \\\\bilderrahmen.local\\$group_name
📅 Upload-Ordner: \\\\bilderrahmen.local\\$group_name\\ (Hauptordner)

🤖 Automatische Sortierung:
   - Fotos hier hochladen → werden täglich um 20 Uhr sortiert
   - Sortierung nach Foto-Datum in: $group_name/Jahr/Monat/
   - Beispiel: $group_name/$current_year/$current_month/

📊 USB-Festplatte: $(df -h /mnt/kita-fotos | tail -1)

Erstellt: $(date)
EOF
        
        log_success "📁 $group_name (Upload + Monats-Ordner)"
    done
    
    # System-Backup-Ordner
    mkdir -p /mnt/kita-fotos/SYSTEM-BACKUP
    
    # Symlink für einfachen Zugriff
    ln -sf /mnt/kita-fotos $HOME/Fotos
    
    # Berechtigungen setzen
    sudo chown -R $USER:$USER /mnt/kita-fotos
    chmod -R 755 /mnt/kita-fotos
    
    log_success "Ordnerstruktur für alle ${#GROUP_NAMES[@]} Gruppen erstellt"
    echo
}

# Samba für Windows/Android-Zugriff konfigurieren
setup_samba() {
    log_step "Samba-Server für Windows/Android konfigurieren"
    
    # Backup der Original-Konfiguration
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Kita-spezifische Samba-Konfiguration hinzufügen
    {
        echo ""
        echo "# ================================================================"
        echo "# Bilderrahmen-Kita Freigaben (automatisch generiert $(date))"
        echo "# ================================================================"
        echo ""
        
        # Haupt-Fotos-Freigabe (für Verwaltung)
        echo "[Fotos]"
        echo "    comment = Kita Fotos - Alle Gruppen (Verwaltung)"
        echo "    path = /mnt/kita-fotos"
        echo "    writeable = yes"
        echo "    browseable = yes"
        echo "    create mask = 0664"
        echo "    directory mask = 0775"
        echo "    public = no"
        echo "    valid users = $KITA_USERNAME"
        echo "    force user = $USER"
        echo "    force group = $USER"
        echo ""
        
        # Einzelne Gruppen-Freigaben (für Android-Upload)
        for group_name in "${GROUP_NAMES[@]}"; do
            echo "[$group_name]"
            echo "    comment = Kita Gruppe: $group_name (Android Upload)"
            echo "    path = /mnt/kita-fotos/$group_name"
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
        
        # Globale Sicherheits-Einstellungen
        echo "# Sicherheits-Konfiguration"
        echo "[global]"
        echo "    hosts allow = 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.1"
        echo "    hosts deny = ALL"
        echo "    security = user"
        echo "    map to guest = never"
        echo "    server min protocol = SMB2"
        echo "    client min protocol = SMB2"
        echo "    log level = 1"
        echo "    log file = /var/log/samba/%m.log"
        echo "    max log size = 50"
        echo ""
    } | sudo tee -a /etc/samba/smb.conf > /dev/null
    
    # System-Benutzer für Samba erstellen falls nicht vorhanden
    if ! id "$KITA_USERNAME" &>/dev/null; then
        sudo useradd -r -s /bin/false "$KITA_USERNAME" -c "Kita Bilderrahmen User"
    fi
    
    # Samba-Passwort setzen
    log_info "Erstelle Samba-Benutzer '$KITA_USERNAME'..."
    (echo "$KITA_PASSWORD"; echo "$KITA_PASSWORD") | sudo smbpasswd -s -a "$KITA_USERNAME" 2>/dev/null
    
    # Samba-Dienste aktivieren und starten
    sudo systemctl enable smbd nmbd --quiet
    sudo systemctl restart smbd nmbd
    
    # Konfiguration testen
    if sudo testparm -s > /dev/null 2>&1; then
        log_success "Samba-Server erfolgreich konfiguriert"
    else
        log_warning "Samba-Konfiguration hat Warnungen (meist nicht kritisch)"
    fi
    
    log_info "Samba-Freigaben verfügbar:"
    echo "  📁 Alle Fotos: \\\\bilderrahmen.local\\Fotos"
    for group in "${GROUP_NAMES[@]}"; do
        echo "  📁 $group: \\\\bilderrahmen.local\\$group"
    done
    
    echo
}

# PHP-API für Bilderdaten erstellen
create_photo_api() {
    log_step "PHP-API für Tablet-Bilderdaten erstellen"
    
    # Erlaubte Ordner Array für PHP generieren
    local allowed_folders=""
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        if [ $i -gt 0 ]; then
            allowed_folders+=", "
        fi
        allowed_folders+="'${GROUP_NAMES[i]}'"
    done
    
    sudo mkdir -p /var/www/html/scripts
    
    # PHP-API mit Monats-Unterstützung erstellen
    cat << EOF | sudo tee /var/www/html/scripts/get_images.php > /dev/null
<?php
/*
 * Bilderrahmen-Kita - Foto API mit automatischer Monats-Sortierung
 * Automatisch generiert am $(date)
 */

header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

\$folder = isset(\$_GET['folder']) ? \$_GET['folder'] : '${GROUP_NAMES[0]}';
\$month = isset(\$_GET['month']) ? \$_GET['month'] : 'all';

// Erlaubte Ordner (automatisch generiert)
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

\$basePath = '/mnt/kita-fotos/' . \$folder;

// Spezifischer Monat gewünscht
if (\$month && \$month !== 'all') {
    \$basePath .= '/' . \$month;
}

if (!is_dir(\$basePath)) {
    echo json_encode([
        'success' => false, 
        'error' => 'Ordner nicht gefunden: ' . \$basePath,
        'folder' => \$folder,
        'month' => \$month
    ]);
    exit;
}

// Bilder sammeln
\$images = [];
\$allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

function scanImagesRecursive(\$dir, \$relativePath = '') {
    global \$images, \$allowedExtensions;
    
    \$files = @scandir(\$dir);
    if (\$files === false) return;
    
    foreach (\$files as \$file) {
        if (\$file === '.' || \$file === '..' || \$file === 'README.txt') continue;
        
        \$fullPath = \$dir . '/' . \$file;
        \$relativeFile = \$relativePath ? \$relativePath . '/' . \$file : \$file;
        
        if (is_dir(\$fullPath)) {
            // Rekursiv in Monats-Unterordner
            scanImagesRecursive(\$fullPath, \$relativeFile);
        } elseif (is_file(\$fullPath)) {
            \$ext = strtolower(pathinfo(\$file, PATHINFO_EXTENSION));
            if (in_array(\$ext, \$allowedExtensions)) {
                \$monthPath = dirname(\$relativeFile);
                if (\$monthPath === '.') \$monthPath = 'unsortiert';
                
                \$images[] = [
                    'name' => \$file,
                    'path' => \$relativeFile,
                    'size' => filesize(\$fullPath),
                    'modified' => filemtime(\$fullPath),
                    'month' => \$monthPath,
                    'date' => date('Y-m-d H:i:s', filemtime(\$fullPath))
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

// Monats-Statistiken
\$monthStats = [];
foreach (\$images as \$img) {
    \$month = \$img['month'];
    if (!isset(\$monthStats[\$month])) {
        \$monthStats[\$month] = 0;
    }
    \$monthStats[\$month]++;
}

echo json_encode([
    'success' => true,
    'images' => \$images,
    'count' => count(\$images),
    'folder' => \$folder,
    'month' => \$month,
    'monthStats' => \$monthStats,
    'basePath' => \$basePath,
    'generated' => date('Y-m-d H:i:s'),
    'version' => 'Bilderrahmen-Kita v1.0'
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
EOF
    
    log_success "PHP-API erstellt mit Unterstützung für ${#GROUP_NAMES[@]} Gruppen"
    echo
}

# Webserver konfigurieren
setup_webserver() {
    log_step "Webserver (Lighttpd + PHP) konfigurieren"
    
    # PHP-Version ermitteln
    local php_version=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    log_info "PHP Version: $php_version"
    
    # PHP-FPM für Lighttpd aktivieren
    sudo lighttpd-enable-mod fastcgi > /dev/null 2>&1
    sudo lighttpd-disable-mod fastcgi-php 2>/dev/null || true
    sudo lighttpd-enable-mod fastcgi-php-fpm > /dev/null 2>&1
    
    # Symlink zu USB-Fotos erstellen
    sudo ln -sf /mnt/kita-fotos /var/www/html/Fotos
    
    # HTML-Dateien vom Repository herunterladen
    log_info "Lade Web-Interface von GitHub..."
    local temp_dir="/tmp/bilderrahmen-install-$$"
    mkdir -p "$temp_dir"
    
    if curl -sSL "https://github.com/BratwurstPeter77/Bilderrahmen-Kita/archive/refs/heads/main.zip" -o "$temp_dir/repo.zip" 2>/dev/null; then
        cd "$temp_dir"
        unzip -q repo.zip 2>/dev/null
        
        if [ -f "Bilderrahmen-Kita-main/scripts/slideshow.html" ]; then
            sudo cp Bilderrahmen-Kita-main/scripts/slideshow.html /var/www/html/scripts/
            sudo cp Bilderrahmen-Kita-main/scripts/verwaltung.html /var/www/html/scripts/
            
            # Gruppen in Verwaltungs-HTML einsetzen
            local groups_js=""
            for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
                if [ $i -gt 0 ]; then
                    groups_js+=", "
                fi
                groups_js+="'${GROUP_NAMES[i]}'"
            done
            
            sudo sed -i "s/const folders = \\[.*\\];/const folders = [$groups_js];/" /var/www/html/scripts/verwaltung.html
            
            log_success "Web-Interface erfolgreich installiert"
        else
            log_warning "Repository-Dateien nicht gefunden - verwende Fallback"
        fi
        
        cd /
        rm -rf "$temp_dir"
    else
        log_warning "GitHub-Download fehlgeschlagen - Web-Interface wird später verfügbar"
    fi
    
    # Index-Weiterleitung zur Verwaltung
    cat << 'EOF' | sudo tee /var/www/html/index.html > /dev/null
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=/scripts/verwaltung.html">
    <title>Bilderrahmen-Kita</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖼️ Bilderrahmen-Kita</h1>
        <p>Weiterleitung zur <a href="/scripts/verwaltung.html">Verwaltung</a>...</p>
        <p>Falls die Weiterleitung nicht funktioniert:</p>
        <p><a href="/scripts/verwaltung.html" style="font-size: 18px;">→ Zur Verwaltung</a></p>
    </div>
</body>
</html>
EOF
    
    # Berechtigungen setzen
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 644 /var/www/html/scripts/*
    sudo chmod 755 /var/www/html/scripts
    
    # Webserver-Dienste aktivieren und starten
    sudo systemctl enable lighttpd php${php_version}-fpm --quiet
    sudo systemctl restart php${php_version}-fpm lighttpd
    
    # Test der Webserver-Funktionalität
    sleep 2
    if curl -s http://localhost > /dev/null 2>&1; then
        log_success "Webserver erfolgreich gestartet"
    else
        log_warning "Webserver-Test fehlgeschlagen (möglicherweise noch nicht bereit)"
    fi
    
    echo
}

# Sicherheit konfigurieren
setup_security() {
    log_step "Sicherheit und Firewall konfigurieren"

    # UFW Firewall aktivieren
    sudo ufw --force enable > /dev/null 2>&1
    sudo ufw default deny incoming > /dev/null 2>&1
    sudo ufw default allow outgoing > /dev/null 2>&1
    
    # Nur lokale Netzwerke erlauben
    sudo ufw allow from 192.168.0.0/16 to any port 80 > /dev/null 2>&1    # HTTP
    sudo ufw allow from 192.168.0.0/16 to any port 445 > /dev/null 2>&1   # SMB
    sudo ufw allow from 192.168.0.0/16 to any port 22 > /dev/null 2>&1    # SSH
    sudo ufw allow from 192.168.0.0/16 to any port 5353 > /dev/null 2>&1  # mDNS
    sudo ufw allow from 172.16.0.0/12 to any port 80 > /dev/null 2>&1
    sudo ufw allow from 172.16.0.0/12 to any port 445 > /dev/null 2>&1
    sudo ufw allow from 172.16.0.0/12 to any port 22 > /dev/null 2>&1
    sudo ufw allow from 172.16.0.0/12 to any port 5353 > /dev/null 2>&1
    sudo ufw allow from 10.0.0.0/8 to any port 80 > /dev/null 2>&1
    sudo ufw allow from 10.0.0.0/8 to any port 445 > /dev/null 2>&1
    sudo ufw allow from 10.0.0.0/8 to any port 22 > /dev/null 2>&1
    sudo ufw allow from 10.0.0.0/8 to any port 5353 > /dev/null 2>&1
    
    # Fail2Ban konfigurieren
    cat << 'EOF' | sudo tee /etc/fail2ban/jail.local > /dev/null
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5

[samba]
enabled = true
port = 445
logpath = /var/log/samba/*.log
maxretry = 3
EOF
    
    sudo systemctl enable fail2ban --quiet
    sudo systemctl restart fail2ban
    
    # Automatische Sicherheits-Updates
    echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null 2>&1
    sudo systemctl enable unattended-upgrades --quiet
    
    log_success "Sicherheit aktiviert (Firewall + Fail2Ban + Auto-Updates)"
    echo
}

# Automatische Foto-Sortierung einrichten
setup_daily_photo_sort() {
    log_step "Automatische Foto-Sortierung einrichten (täglich 20 Uhr)"
    
    # Foto-Sortier-Script erstellen
    cat << 'SORT_EOF' > $HOME/auto_sort_photos.sh
#!/bin/bash
#
# Tägliche Foto-Sortierung um 20 Uhr
# Sortiert alle neuen Fotos nach Datum in Monats-Ordner
#

LOG_FILE="/var/log/photo-sort.log"
FOTOS_BASE="/mnt/kita-fotos"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

create_month_folder() {
    local group="$1"
    local year_month="$2"
    local folder_path="$FOTOS_BASE/$group/$year_month"
    
    if [ ! -d "$folder_path" ]; then
        mkdir -p "$folder_path"
        chmod 755 "$folder_path"
        log_message "Neuer Monats-Ordner erstellt: $folder_path"
    fi
}

get_photo_date() {
    local file="$1"
    local photo_date=""
    
    # EXIF-Datum versuchen (präzise)
    if command -v exiftool >/dev/null 2>&1; then
        photo_date=$(exiftool -d "%Y/%m" -DateTimeOriginal -S -s "$file" 2>/dev/null)
    fi
    
    # Fallback: Datei-Änderungsdatum
    if [ -z "$photo_date" ]; then
        photo_date=$(date -r "$file" '+%Y/%m' 2>/dev/null)
    fi
    
    # Letzter Fallback: Aktueller Monat
    if [ -z "$photo_date" ]; then
        photo_date=$(date '+%Y/%m')
    fi
    
    echo "$photo_date"
}

sort_single_photo() {
    local source_file="$1"
    local group="$2"
    
    if [ ! -f "$source_file" ]; then
        return 1
    fi
    
    local year_month=$(get_photo_date "$source_file")
    local filename=$(basename "$source_file")
    
    create_month_folder "$group" "$year_month"
    
    local dest_path="$FOTOS_BASE/$group/$year_month/$filename"
    
    # Bei Namenskonflikt: Zeitstempel anhängen
    if [ -f "$dest_path" ]; then
        local basename="${filename%.*}"
        local extension="${filename##*.}"
        local timestamp=$(date '+%H%M%S')
        dest_path="$FOTOS_BASE/$group/$year_month/${basename}_${timestamp}.${extension}"
    fi
    
    if mv "$source_file" "$dest_path" 2>/dev/null; then
        log_message "✓ Sortiert: $filename → $group/$year_month/"
        return 0
    else
        log_message "✗ FEHLER beim Sortieren: $filename"
        return 1
    fi
}

create_next_month_folders() {
    local next_month=$(date -d "+1 month" '+%Y/%m')
    local created=0
    
    for group_dir in "$FOTOS_BASE"/*; do
        if [ -d "$group_dir" ] && [ "$(basename "$group_dir")" != "SYSTEM-BACKUP" ]; then
            local group_name=$(basename "$group_dir")
            if [ ! -d "$FOTOS_BASE/$group_name/$next_month" ]; then
                mkdir -p "$FOTOS_BASE/$group_name/$next_month"
                chmod 755 "$FOTOS_BASE/$group_name/$next_month"
                ((created++))
            fi
        fi
    done
    
    if [ $created -gt 0 ]; then
        log_message "→ Vorbereitet für nächsten Monat: $next_month ($created Ordner)"
    fi
}

# Hauptfunktion
main_daily_sort() {
    log_message "=== TÄGLICHE FOTO-SORTIERUNG GESTARTET ==="
    
    if [ ! -d "$FOTOS_BASE" ]; then
        log_message "FEHLER: USB-Festplatte nicht verfügbar: $FOTOS_BASE"
        exit 1
    fi
    
    local total_sorted=0
    local total_errors=0
    
    # Alle Gruppen durchgehen
    for group_dir in "$FOTOS_BASE"/*; do
        if [ ! -d "$group_dir" ] || [ "$(basename "$group_dir")" = "SYSTEM-BACKUP" ]; then
            continue
        fi
        
        local group_name=$(basename "$group_dir")
        local group_sorted=0
        
        # Nur unsorierte Dateien im Haupt-Gruppen-Ordner (maxdepth 1)
        while IFS= read -r -d '' photo_file; do
            if sort_single_photo "$photo_file" "$group_name"; then
                ((group_sorted++))
                ((total_sorted++))
            else
                ((total_errors++))
            fi
        done < <(find "$group_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.bmp" \) -print0 2>/dev/null)
        
        if [ $group_sorted -gt 0 ]; then
            log_message "→ Gruppe '$group_name': $group_sorted Fotos sortiert"
        fi
    done
    
    # Nächste Monats-Ordner vorbereiten
    create_next_month_folders
    
    log_message "=== SORTIERUNG ABGESCHLOSSEN: $total_sorted sortiert, $total_errors Fehler ==="
    
    # E-Mail-Benachrichtigung (falls konfiguriert)
    if [ $total_sorted -gt 0 ] && command -v mail >/dev/null 2>&1; then
        echo "Kita Foto-Sortierung: $total_sorted Fotos automatisch sortiert" | \
        mail -s "Bilderrahmen-Kita Sortierung" root 2>/dev/null || true
    fi
}

# Log-Rotation (wöchentlich sonntags)
if [ $(date +%u) -eq 7 ] && [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]; then
    cp "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d)"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log rotiert - neue Woche" > "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

# Script ausführen
main_daily_sort
SORT_EOF
    
    chmod +x $HOME/auto_sort_photos.sh
    
    # Täglicher Cronjob um 20 Uhr
    (crontab -l 2>/dev/null; echo "0 20 * * * $HOME/auto_sort_photos.sh") | crontab -
    
    # Test-Script für manuelle Ausführung
    cat << 'TEST_EOF' > /home/pi/test_photo_sort.sh
#!/bin/bash
echo "=== FOTO-SORTIERUNG TEST ==="
echo "Führe Sortierung manuell aus..."
$HOME/auto_sort_photos.sh
echo ""
echo "Letzte Log-Einträge:"
tail -10 /var/log/photo-sort.log 2>/dev/null || echo "Noch keine Logs vorhanden"
TEST_EOF
    
    chmod +x /home/pi/test_photo_sort.sh
    
    log_success "Automatische Foto-Sortierung aktiviert (täglich 20:00 Uhr)"
    log_info "Manueller Test: /home/pi/test_photo_sort.sh"
    echo
}

# System-Backup auf USB-Festplatte erstellen
create_system_backup() {
    log_step "System-Backup auf USB-Festplatte erstellen"
    
    local backup_dir="/mnt/kita-fotos/SYSTEM-BACKUP"
    mkdir -p "$backup_dir"
    
    # Backup-Script erstellen
    cat << 'BACKUP_EOF' > /home/pi/create_system_backup.sh
#!/bin/bash
BACKUP_DIR="/mnt/kita-fotos/SYSTEM-BACKUP"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')

echo "=== SYSTEM-BACKUP ERSTELLEN ==="
echo "Datum: $(date)"
echo "Ziel: $BACKUP_DIR"

# Backup-Ordner vorbereiten
mkdir -p "$BACKUP_DIR"/{config,scripts,system,home-backup}

echo "Sichere Konfigurationsdateien..."
# System-Konfigurationen
cp -r /etc/samba "$BACKUP_DIR/config/" 2>/dev/null || true
cp -r /etc/lighttpd "$BACKUP_DIR/config/" 2>/dev/null || true
cp /etc/fstab "$BACKUP_DIR/config/" 2>/dev/null || true
cp /etc/hostname "$BACKUP_DIR/config/" 2>/dev/null || true
cp /etc/hosts "$BACKUP_DIR/config/" 2>/dev/null || true
cp -r /etc/fail2ban "$BACKUP_DIR/config/" 2>/dev/null || true

echo "Sichere Web-Dateien..."
# Web-Interface
cp -r /var/www/html "$BACKUP_DIR/scripts/" 2>/dev/null || true

echo "Sichere Benutzer-Daten..."
# Home-Verzeichnis ohne Fotos
rsync -av --exclude="Fotos*" --exclude="*.jpg" --exclude="*.png" --exclude="*.gif" /home/pi/ "$BACKUP_DIR/home-backup/" 2>/dev/null || true

echo "Erstelle System-Informationen..."
# System-Status
crontab -l > "$BACKUP_DIR/system/crontab-pi.txt" 2>/dev/null || echo "Keine Crontab" > "$BACKUP_DIR/system/crontab-pi.txt"
dpkg --get-selections > "$BACKUP_DIR/system/installed-packages.txt"
systemctl list-unit-files --state=enabled > "$BACKUP_DIR/system/enabled-services.txt"
uname -a > "$BACKUP_DIR/system/system-info.txt"
lsblk -f > "$BACKUP_DIR/system/disks-detailed.txt"
df -h > "$BACKUP_DIR/system/disk-usage.txt"
mount > "$BACKUP_DIR/system/mounts.txt"

# Netzwerk-Konfiguration
ip addr show > "$BACKUP_DIR/system/network-interfaces.txt"
cat /etc/dhcpcd.conf > "$BACKUP_DIR/system/dhcpcd.conf" 2>/dev/null || true

# Git-Repository für Updates
echo "Sichere Original-Repository..."
if command -v git >/dev/null && [ ! -d "$BACKUP_DIR/original-repo" ]; then
    git clone https://github.com/BratwurstPeter77/Bilderrahmen-Kita.git "$BACKUP_DIR/original-repo" 2>/dev/null || echo "Git-Clone fehlgeschlagen"
fi

# Haupt-Informationsdatei
cat > "$BACKUP_DIR/BACKUP-INFO.txt" << EOL
Bilderrahmen-Kita - System-Backup
==================================
Backup erstellt: $(date)
Backup-Version: $DATE

System-Information:
Hostname: $(hostname)
Kernel: $(uname -r)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Raspberry Pi: $(grep Model /proc/cpuinfo | cut -d':' -f2 | sed 's/^ *//' || echo "Unbekannt")
RAM: $(free -h | grep Mem: | awk '{print $2}')

Storage:
SD-Karte: $(df -h / | tail -1 | awk '{print $2 " (" $5 " verwendet)"}')
USB-Festplatte: $(df -h /mnt/kita-fotos | tail -1 | awk '{print $2 " (" $5 " verwendet)"}')

Konfigurierte Gruppen:
$(ls -la /mnt/kita-fotos/ | grep -v SYSTEM-BACKUP | grep "^d" | awk '{print $9}' | grep -v "^$" | sort)

Installierte Kita-Services:
- Samba Server (Dateifreigaben)
- Lighttpd Webserver + PHP
- Avahi mDNS (bilderrahmen.local)
- UFW Firewall + Fail2Ban
- Automatische Foto-Sortierung (Cronjob)

Backup-Inhalt:
- config/: Alle System-Konfigurationen
- scripts/: Web-Interface und PHP-Scripte
- home-backup/: Benutzer-Daten und Scripts
- system/: Paket-Listen und System-Status
- original-repo/: GitHub-Repository für Neuinstallation

Wiederherstellung:
Siehe RESTORE-ANLEITUNG.txt für detaillierte Schritte
EOL

# Detaillierte Wiederherstellungs-Anleitung
cat > "$BACKUP_DIR/RESTORE-ANLEITUNG.txt" << EOL
Wiederherstellung des Bilderrahmen-Kita Systems
===============================================

WICHTIG: Alle Fotos sind auf der USB-Festplatte sicher!

SCHNELLE WIEDERHERSTELLUNG (Empfohlen):
=========================================

1. NEUE SD-KARTE VORBEREITEN:
   - Raspberry Pi OS (32GB) mit Raspberry Pi Imager installieren
   - SSH aktivieren, WLAN konfigurieren
   - Boot und SSH-Verbindung herstellen

2. AUTOMATISCHE NEUINSTALLATION:
   curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash
   
   → Gleiche Einstellungen wie vorher verwenden
   → USB-Festplatte wird automatisch erkannt
   → Alle Fotos bleiben erhalten!

3. SYSTEM TESTEN:
   - Web-Interface: http://bilderrahmen.local
   - Tablet-URLs testen
   - Samba-Zugriff prüfen

MANUELLE WIEDERHERSTELLUNG (Bei Problemen):
===========================================

1. GRUNDSYSTEM INSTALLIEREN:
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y samba lighttpd php-fpm avahi-daemon git

2. USB-FESTPLATTE MOUNTEN:
   # UUID aus system/mounts.txt ablesen
   sudo mkdir -p /mnt/kita-fotos  
   sudo mount [USB-DEVICE] /mnt/kita-fotos
   # In /etc/fstab eintragen für permanentes Mounting

3. KONFIGURATIONEN WIEDERHERSTELLEN:
   sudo cp -r config/samba/* /etc/samba/
   sudo cp -r config/lighttpd/* /etc/lighttpd/
   sudo cp config/hostname /etc/hostname
   sudo cp config/hosts /etc/hosts
   sudo cp config/fstab /etc/fstab

4. WEB-INTERFACE WIEDERHERSTELLEN:
   sudo cp -r scripts/html/* /var/www/html/
   sudo ln -sf /mnt/kita-fotos /var/www/html/Fotos
   sudo chown -R www-data:www-data /var/www/html

5. BENUTZER-DATEN WIEDERHERSTELLEN:
   cp -r home-backup/* /home/pi/
   crontab system/crontab-pi.txt

6. DIENSTE STARTEN:
   sudo systemctl enable smbd nmbd lighttpd avahi-daemon
   sudo systemctl restart smbd nmbd lighttpd avahi-daemon

7. SAMBA-BENUTZER ERSTELLEN:
   # Benutzername und Passwort aus der ursprünglichen Installation verwenden
   sudo smbpasswd -a [KITA-USERNAME]

KONFIGURATION PRÜFEN:
====================

# System-Status
sudo systemctl status smbd lighttpd avahi-daemon

# Netzwerk-Test  
ping bilderrahmen.local

# Web-Test
curl http://localhost

# Samba-Test
smbclient -L localhost -U [KITA-USERNAME]

# USB-Festplatte
df -h /mnt/kita-fotos

NOTFALL-KONTAKT:
===============
GitHub: https://github.com/BratwurstPeter77/Bilderrahmen-Kita/issues

Backup erstellt: $(date)
System-Version: Bilderrahmen-Kita v1.0
EOL

# Backup-Größe ermitteln
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)

echo ""
echo "=== BACKUP ABGESCHLOSSEN ==="
echo "Speicherort: $BACKUP_DIR"
echo "Größe: $BACKUP_SIZE"
echo "Dateien: $FILE_COUNT"
echo "Status: Erfolgreich"

# Backup-Log
echo "[$(date)] System-Backup erstellt: $BACKUP_SIZE, $FILE_COUNT Dateien" >> /var/log/system-backup.log
BACKUP_EOF
    
    chmod +x /home/pi/create_system_backup.sh
    
    # Backup ausführen
    log_info "Erstelle initiales System-Backup..."
    /home/pi/create_system_backup.sh > /dev/null 2>&1
    
    if [ -f "$backup_dir/BACKUP-INFO.txt" ]; then
        local backup_size=$(du -sh "$backup_dir" | cut -f1)
        log_success "System-Backup erstellt: $backup_size in $backup_dir"
    else
        log_warning "System-Backup möglicherweise unvollständig"
    fi
    
    echo
}

# Status-Check-Script erstellen
create_status_scripts() {
    log_step "Status-Check-Scripts erstellen"
    
    # Backup-Status-Script
    cat << 'STATUS_EOF' > /home/pi/check_system_status.sh
#!/bin/bash
echo "=== BILDERRAHMEN-KITA SYSTEM-STATUS ==="
echo "Datum: $(date)"
echo ""

# System-Informationen
echo "💻 System:"
echo "   Hostname: $(hostname)"
echo "   Uptime: $(uptime | cut -d',' -f1 | sed 's/^.*up //')"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "   Temperatur: $(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 || echo "N/A")"
echo ""

# USB-Festplatte
echo "💾 USB-Festplatte:"
if [ -d "/mnt/kita-fotos" ]; then
    df -h /mnt/kita-fotos | tail -1
    TOTAL_PHOTOS=$(find /mnt/kita-fotos -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) 2>/dev/null | wc -l)
    echo "   📸 Gesamte Fotos: $TOTAL_PHOTOS"
    
    echo ""
    echo "📁 Gruppen-Übersicht:"
    for group in $(ls /mnt/kita-fotos 2>/dev/null | grep -v SYSTEM-BACKUP); do
        if [ -d "/mnt/kita-fotos/$group" ]; then
            GROUP_PHOTOS=$(find "/mnt/kita-fotos/$group" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) 2>/dev/null | wc -l)
            GROUP_SIZE=$(du -sh "/mnt/kita-fotos/$group" 2>/dev/null | cut -f1)
            echo "   📱 $group: $GROUP_PHOTOS Fotos ($GROUP_SIZE)"
        fi
    done
else
    echo "   ❌ USB-Festplatte nicht gemountet"
fi
echo ""

# System-Backup
echo "📀 System-Backup:"
if [ -d "/mnt/kita-fotos/SYSTEM-BACKUP" ]; then
    BACKUP_SIZE=$(du -sh "/mnt/kita-fotos/SYSTEM-BACKUP" 2>/dev/null | cut -f1)
    BACKUP_DATE=$(stat -c %y "/mnt/kita-fotos/SYSTEM-BACKUP" 2>/dev/null | cut -d' ' -f1)
    echo "   ✅ Vorhanden: $BACKUP_SIZE (erstellt: $BACKUP_DATE)"
    echo "   📋 Anleitung: /mnt/kita-fotos/SYSTEM-BACKUP/RESTORE-ANLEITUNG.txt"
else
    echo "   ❌ Kein System-Backup gefunden"
fi
echo ""

# Dienste
echo "🔧 Dienste-Status:"
for service in smbd lighttpd avahi-daemon fail2ban; do
    if systemctl is-active --quiet $service; then
        echo "   ✅ $service: Läuft"
    else
        echo "   ❌ $service: Gestoppt"
    fi
done
echo ""

# Netzwerk
echo "🌐 Netzwerk:"
IP=$(hostname -I | awk '{print $1}' | head -1)
echo "   IP-Adresse: $IP"
echo "   Hostname: $(hostname).local"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "   Internet: ✅ Verbunden"
else
    echo "   Internet: ❌ Nicht erreichbar"
fi
echo ""

# Letzte Foto-Sortierung
echo "🕐 Letzte Foto-Sortierung:"
if [ -f "/var/log/photo-sort.log" ]; then
    LAST_SORT=$(tail -1 /var/log/photo-sort.log 2>/dev/null)
    echo "   $LAST_SORT"
else
    echo "   Noch keine Sortierung durchgeführt"
fi
echo ""

# Cronjobs
echo "⏰ Geplante Aufgaben:"
echo "   📅 Foto-Sortierung: Täglich 20:00 Uhr"
crontab -l | grep -v "^#" | while read line; do
    if [ -n "$line" ]; then
        echo "   ⚙️  $line"
    fi
done
echo ""

echo "=== STATUS-CHECK BEENDET ==="
STATUS_EOF
    
    chmod +x /home/pi/check_system_status.sh
    
    # Einfacher Backup-Check
    cat << 'BACKUP_CHECK_EOF' > /home/pi/check_backup.sh
#!/bin/bash
echo "=== BACKUP-STATUS ==="
if [ -d "/mnt/kita-fotos/SYSTEM-BACKUP" ]; then
    echo "✅ System-Backup vorhanden"
    echo "   Größe: $(du -sh /mnt/kita-fotos/SYSTEM-BACKUP | cut -f1)"
    echo "   Erstellt: $(stat -c %y /mnt/kita-fotos/SYSTEM-BACKUP | cut -d' ' -f1)"
    echo "   Anleitung: /mnt/kita-fotos/SYSTEM-BACKUP/RESTORE-ANLEITUNG.txt"
else
    echo "❌ Kein Backup gefunden"
    echo "   Backup erstellen: /home/pi/create_system_backup.sh"
fi
BACKUP_CHECK_EOF
    
    chmod +x /home/pi/check_backup.sh
    
    log_success "Status-Check-Scripts erstellt:"
    log_info "/home/pi/check_system_status.sh - Komplett-Status"
    log_info "/home/pi/check_backup.sh - Backup-Status"
    echo
}

# Installation abschließen
finish_installation() {
    local ip=$(hostname -I | awk '{print $1}' | head -1 || echo "localhost")
    
    # Abschließende Tests
    log_step "Abschließende System-Tests"
    
    local tests_passed=0
    local tests_total=5
    
    # Test 1: USB-Festplatte
    if df -h | grep -q "/mnt/kita-fotos"; then
        ((tests_passed++))
        log_success "✅ USB-Festplatte gemountet"
    else
        log_error "❌ USB-Festplatte nicht verfügbar"
    fi
    
    # Test 2: Samba
    if systemctl is-active --quiet smbd; then
        ((tests_passed++))
        log_success "✅ Samba-Server läuft"
    else
        log_error "❌ Samba-Server nicht aktiv"
    fi
    
    # Test 3: Webserver
    if systemctl is-active --quiet lighttpd; then
        ((tests_passed++))
        log_success "✅ Webserver läuft"
    else
        log_error "❌ Webserver nicht aktiv"
    fi
    
    # Test 4: PHP-API
    if curl -s <http://localhost/scripts/get_images.php?folder=${GROUP_NAMES>[0]} 2>/dev/null | grep -q "success"; then
        ((tests_passed++))
        log_success "✅ PHP-API funktioniert"
    else
        log_warning "⚠️ PHP-API Test fehlgeschlagen"
    fi
    
    # Test 5: Cronjob
    if crontab -l | grep -q "auto_sort_photos"; then
        ((tests_passed++))
        log_success "✅ Foto-Sortierung geplant"
    else
        log_error "❌ Cronjob nicht aktiv"
    fi
    
    echo
    log_info "System-Tests: $tests_passed/$tests_total erfolgreich"
    echo
    
    # Erfolgsmeldung
    echo
    log_header "🎉 INSTALLATION ERFOLGREICH ABGESCHLOSSEN!"
    echo
    echo "================================================================"
    echo "🖼️  BILDERRAHMEN-KITA MIT ${#GROUP_NAMES[@]} GRUPPEN IST BEREIT!"
    echo "================================================================"
    echo
    echo "🌐 **Sofort verfügbar unter:**"
    echo "   http://bilderrahmen.local (empfohlen)"
    echo "   http://$ip (IP-Adresse)"
    echo
    echo "📱 **Tablet-URLs für eure ${#GROUP_NAMES[@]} Gruppen:**"
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        local group="${GROUP_NAMES[i]}"
        local display_name=$(echo "$group" | sed 's/./\U&/')
        echo "   Tablet $((i+1)) ($display_name): http://bilderrahmen.local/Fotos/$group"
    done
    echo
    echo "🔐 **Anmeldedaten für Android/Windows:**"
    echo "   👤 Benutzername: $KITA_USERNAME"
    echo "   🔑 Passwort: $KITA_PASSWORD"
    echo "   💡 Diese Daten für SMBSync2 und Windows verwenden!"
    echo
    echo "💾 **USB-Festplatte ($(df -h /mnt/kita-fotos | tail -1 | awk '{print $2}')):**"
    echo "   📊 Status: $(df -h /mnt/kita-fotos | tail -1)"
    echo "   📀 System-Backup: /mnt/kita-fotos/SYSTEM-BACKUP/"
    echo "   🕐 Foto-Sortierung: Täglich 20:00 Uhr automatisch"
    echo
    echo "💻 **Windows-Zugriff (Kita-Verwaltung):**"
    echo "   📁 Alle Gruppen: \\\\bilderrahmen.local\\Fotos"
    for group in "${GROUP_NAMES[@]}"; do
        echo "   📁 $group: \\\\bilderrahmen.local\\$group"
    done
    echo
    echo "📱 **Upload-Workflow für Erzieher:**"
    echo "   1. SMBSync2 installieren und konfigurieren"
    echo "   2. Fotos direkt in Gruppen-Hauptordner hochladen"
    echo "   3. System sortiert automatisch um 20 Uhr in Monats-Ordner"
    echo "   4. Tablets zeigen sofort alle Fotos (unsortiert + sortiert)"
    echo
    echo "🚀 **Nächste Schritte:**"
    echo "   1. 🔄 Raspberry Pi neu starten: sudo reboot"
    echo "   2. 📱 SMBSync2 auf Erzieher-Handys konfigurieren"
    echo "   3. 🖼️  Testbilder hochladen und Sortierung testen"  
    echo "   4. 📱 Alle 5 Tablet-URLs in Browsern öffnen"
    echo "   5. 🌐 Web-Verwaltung testen: http://bilderrahmen.local"
    echo
    echo "🔧 **System-Verwaltung:**"
    echo "   Status prüfen: /home/pi/check_system_status.sh"
    echo "   Backup prüfen: /home/pi/check_backup.sh"
    echo "   Sortierung testen: /home/pi/test_photo_sort.sh"
    echo "   System-Backup: /home/pi/create_system_backup.sh"
    echo
    echo "📱 **Android-Apps herunterladen:**"
    echo "   SMBSync2: https://play.google.com/store/apps/details?id=com.sentaroh.android.SMBSync2"
    echo "   PhotoSync: https://play.google.com/store/apps/details?id=com.touchbyte.photosync"
    echo
    echo "📚 **Dokumentation:**"
    echo "   GitHub: https://github.com/BratwurstPeter77/Bilderrahmen-Kita"
    echo "   Android-Setup: Siehe SMBSync2-Anleitung.md im Repository"
    echo
    if [ $tests_passed -lt $tests_total ]; then
        echo "⚠️  **Hinweis:** Einige Tests fehlgeschlagen ($tests_passed/$tests_total)"
        echo "   System sollte trotzdem funktionieren - prüfe nach Neustart"
    fi
    echo "================================================================"
    echo "🎯 Viel Erfolg mit eurem Bilderrahmen-System!"
    echo "   Bei Problemen: GitHub Issues oder System-Status prüfen"
    echo "================================================================"
    
    # Finale Hinweise
    echo
    log_warning "WICHTIG vor dem ersten Gebrauch:"
    echo "1. Raspberry Pi NEUSTART durchführen: sudo reboot"
    echo "2. Nach Neustart Web-Interface testen: http://bilderrahmen.local"
    echo "3. Android-Apps mit obigen Anmeldedaten konfigurieren"
    echo
}

# Hauptinstallation
main() {
    clear
    show_banner
    check_system
    create_user_credentials
    setup_usb_disk
    get_group_names
    install_dependencies
    setup_hostname
    create_folder_structure
    setup_samba
    create_photo_api
    setup_webserver
    setup_security
    setup_daily_photo_sort
    create_system_backup
    create_status_scripts
    finish_installation
}

# Script ausführen mit Fehlerbehandlung
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'log_error "Installation durch unerwarteten Fehler abgebrochen (Zeile: $LINENO)"' ERR
    main "$@"
fi
