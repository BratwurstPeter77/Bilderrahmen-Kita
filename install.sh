#!/bin/bash
#
# Bilderrahmen-Kita - Installation mit USB-Festplatte
# Copyright (c) 2025 BratwurstPeter77
# Licensed under the MIT License
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
    echo "📅 Monatsweise Organisation für einfache Verwaltung"
    echo
}

# System prüfen
check_system() {
    log_step "System-Kompatibilität prüfen"
    
    if [[ $EUID -eq 0 ]]; then
        log_error "Bitte NICHT als root ausführen!"
        exit 1
    fi
    
    if ! command -v apt &> /dev/null; then
        log_error "Nur auf Debian/Ubuntu/Raspberry Pi OS unterstützt"
        exit 1
    fi
    
    if grep -q "Raspberry Pi\|BCM" /proc/cpuinfo 2>/dev/null; then
        local pi_model=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | sed 's/^ *//')
        log_success "Raspberry Pi erkannt: $pi_model"
    fi
    
    local disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_free -lt 10 ]]; then
        log_error "Zu wenig Speicherplatz auf SD-Karte. Mindestens 10GB erforderlich."
        exit 1
    fi
    
    log_success "System-Prüfung erfolgreich"
    echo
}

# USB-Festplatte erkennen und einrichten
setup_usb_disk() {
    log_step "USB-Festplatte einrichten"
    
    echo "Verfügbare USB-Geräte:"
    lsblk | grep -E "(sda|sdb|sdc)" || true
    echo
    
    while true; do
        read -p "USB-Festplatte Gerät (z.B. sda): " device_input
        
        if [[ -z "$device_input" ]]; then
            log_error "Bitte Geräte-Name eingeben (z.B. sda)"
            continue
        fi
        
        USB_DEVICE="/dev/${device_input}"
        
        if [[ ! -b "$USB_DEVICE" ]]; then
            log_error "Gerät $USB_DEVICE nicht gefunden"
            continue
        fi
        
        # Größe anzeigen
        local size=$(lsblk -b -d -n -o SIZE "$USB_DEVICE" 2>/dev/null | awk '{print int($1/1000000000)}')
        log_info "Festplatte: $USB_DEVICE (${size}GB)"
        
        echo "⚠️  WARNUNG: Alle Daten auf $USB_DEVICE werden gelöscht!"
        read -p "Fortfahren? (j/n): " confirm
        
        case $confirm in
            [JjYy]*)
                break
                ;;
            [Nn]*)
                log_info "Installation abgebrochen"
                exit 0
                ;;
            *)
                echo "Bitte 'j' oder 'n' eingeben"
                ;;
        esac
    done
    
    # Festplatte formatieren
    log_info "Formatiere Festplatte..."
    sudo umount ${USB_DEVICE}* 2>/dev/null || true
    
    # Partitionstabelle erstellen
    sudo fdisk "$USB_DEVICE" << EOF
o
n
p
1


w
EOF
    
    # Dateisystem erstellen
    sudo mkfs.ext4 "${USB_DEVICE}1" -L "KitaFotos" -F
    
    # UUID ermitteln
    local uuid=$(sudo blkid "${USB_DEVICE}1" | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
    
    # Mount-Point erstellen
    sudo mkdir -p /mnt/kita-fotos
    
    # In fstab eintragen
    echo "UUID=$uuid /mnt/kita-fotos ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
    
    # Mounten
    sudo mount -a
    
    if df -h | grep -q "/mnt/kita-fotos"; then
        log_success "USB-Festplatte erfolgreich eingerichtet"
    else
        log_error "Fehler beim Mounten der USB-Festplatte"
        exit 1
    fi
    
    # Berechtigungen setzen
    sudo chown -R pi:pi /mnt/kita-fotos
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
    log_header "👤 BENUTZER-ANMELDEDATEN"
    echo
    echo "Erstelle Benutzername und Passwort für:"
    echo "  📱 Android-App Zugriff"
    echo "  💻 Windows Netzlaufwerk"
    echo "  🌐 Tablet-Browser Verwaltung"
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
            continue
        fi
        
        if [[ "$username_input" != "$KITA_USERNAME" ]]; then
            log_info "Eingabe: '$username_input' → Verwendet: '$KITA_USERNAME'"
        fi
        
        break
    done
    
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
        log_success "Anmeldedaten erfolgreich erstellt"
        break
    done
    
    echo
    log_info "Anmeldedaten für später notieren:"
    echo "   👤 Benutzername: $KITA_USERNAME"
    echo "   🔑 Passwort: $KITA_PASSWORD"
    echo
    read -p "📝 Daten notiert? Weiter mit Enter..."
}

# Gruppennamen konfigurieren
get_group_names() {
    log_header "📋 GRUPPEN-KONFIGURATION"
    echo
    echo "Erstelle Kita-Gruppen für die 5 Tablets:"
    echo "  • 🐛 Käfer    • 🐝 Bienen    • 🦋 Schmetterlinge    • 🐸 Frösche    • 🐻 Bären"
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
    for ((i=1; i<=GROUP_COUNT; i++)); do
        while true; do
            read -p "📝 Name für Gruppe $i/$GROUP_COUNT: " group_input
            
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
    log_header "📋 ÜBERSICHT DER GRUPPEN"
    echo
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        local group="${GROUP_NAMES[i]}"
        echo "   📱 Tablet $((i+1)): $group"
        echo "      🌐 URL: http://bilderrahmen.local/Fotos/$group"
        echo
    done
    
    while true; do
        read -p "✅ Diese $GROUP_COUNT Gruppen erstellen? (j/n): " confirm
        case $confirm in
            [JjYy]*) break ;;
            [Nn]*) exit 0 ;;
            *) echo "Bitte 'j' oder 'n' eingeben." ;;
        esac
    done
}

# Abhängigkeiten installieren
install_dependencies() {
    log_step "System-Pakete installieren"
    
    sudo apt update -qq
    sudo apt upgrade -y -qq
    
    local packages=(
        "git" "curl" "wget" "unzip"
        "samba" "samba-common-bin" 
        "lighttpd" "php-fpm" "php-cli"
        "avahi-daemon" "avahi-utils"
        "ufw" "fail2ban"
        "smartmontools"
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

# Hostname konfigurieren
setup_hostname() {
    log_step "Hostname konfigurieren"
    
    local current_hostname=$(hostname)
    local target_hostname="bilderrahmen"
    
    if [[ "$current_hostname" != "$target_hostname" ]]; then
        echo "$target_hostname" | sudo tee /etc/hostname > /dev/null
        sudo sed -i "s/127.0.1.1.*$current_hostname/127.0.1.1\t$target_hostname/" /etc/hosts
        sudo systemctl enable avahi-daemon --quiet
        sudo systemctl restart avahi-daemon
        log_success "Hostname gesetzt: $target_hostname.local"
    else
        log_success "Hostname bereits korrekt: $target_hostname.local"
    fi
    echo
}

# Ordnerstruktur erstellen
create_folder_structure() {
    log_step "Ordnerstruktur mit Monats-Organisation erstellen"
    
    local current_year=$(date +%Y)
    
    for group_name in "${GROUP_NAMES[@]}"; do
        for i in {0..3}; do
            local month_date=$(date -d "+$i month" +%Y/%m)
            mkdir -p "/mnt/kita-fotos/$group_name/$month_date"
        done
        
        cat > "/mnt/kita-fotos/$group_name/README.txt" << EOF
Willkommen bei der $group_name Gruppe!

💾 Gespeichert auf USB-Festplatte für beste Performance
📅 Monatsweise Sortierung: $group_name/$current_year/$(date +%m)/
📱 Tablet-URL: http://bilderrahmen.local/Fotos/$group_name
💻 Windows-Zugriff: \\\\bilderrahmen.local\\Fotos\\$group_name

📊 USB-Festplatte: $(df -h /mnt/kita-fotos | tail -1)
EOF
        
        log_success "📁 $group_name (mit Monats-Ordnern)"
    done
    
    # System-Backup-Ordner
    mkdir -p /mnt/kita-fotos/SYSTEM-BACKUP
    
    # Symlink für einfachen Zugriff
    ln -sf /mnt/kita-fotos $HOME/Fotos
    
    chmod -R 755 /mnt/kita-fotos
    
    log_success "Ordnerstruktur für alle ${#GROUP_NAMES[@]} Gruppen erstellt"
    echo
}

# Samba konfigurieren
setup_samba() {
    log_step "Samba-Server konfigurieren"
    
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    {
        echo ""
        echo "# ================================================================"
        echo "# Bilderrahmen-Kita Freigaben ($(date))"
        echo "# ================================================================"
        echo ""
        echo "[Fotos]"
        echo "    comment = Kita Fotos - Alle Gruppen"
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
        
        for group_name in "${GROUP_NAMES[@]}"; do
            echo "[$group_name]"
            echo "    comment = Kita Gruppe: $group_name"
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
        
        echo "[global]"
        echo "    hosts allow = 192.168.0.0/16 127.0.0.1"
        echo "    hosts deny = ALL"
        echo "    security = user"
        echo "    map to guest = never"
        echo "    server min protocol = SMB2"
        echo "    client min protocol = SMB2"
        echo ""
    } | sudo tee -a /etc/samba/smb.conf > /dev/null
    
    # System-User erstellen
    if ! id "$KITA_USERNAME" &>/dev/null; then
        sudo useradd -r -s /bin/false "$KITA_USERNAME"
    fi
    
    # Samba-Passwort setzen
    (echo "$KITA_PASSWORD"; echo "$KITA_PASSWORD") | sudo smbpasswd -s -a "$KITA_USERNAME"
    
    sudo systemctl enable smbd nmbd --quiet
    sudo systemctl restart smbd nmbd
    
    if sudo testparm -s > /dev/null 2>&1; then
        log_success "Samba konfiguriert für Benutzer '$KITA_USERNAME'"
    else
        log_warning "Samba-Konfiguration hat Warnungen"
    fi
    echo
}

# PHP-API erstellen
create_photo_api() {
    log_step "Foto-API erstellen"
    
    local allowed_folders=""
    for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
        if [ $i -gt 0 ]; then
            allowed_folders+=", "
        fi
        allowed_folders+="'${GROUP_NAMES[i]}'"
    done
    
    sudo mkdir -p /var/www/html/scripts
    
    cat << EOF | sudo tee /var/www/html/scripts/get_images.php > /dev/null
<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

\$folder = isset(\$_GET['folder']) ? \$_GET['folder'] : '${GROUP_NAMES[0]}';
\$month = isset(\$_GET['month']) ? \$_GET['month'] : 'all';

\$allowedFolders = [$allowed_folders];
if (!in_array(\$folder, \$allowedFolders)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Ungültiger Ordner']);
    exit;
}

\$basePath = '/mnt/kita-fotos/' . \$folder;

if (\$month && \$month !== 'all') {
    \$basePath .= '/' . \$month;
}

if (!is_dir(\$basePath)) {
    echo json_encode(['success' => false, 'error' => 'Ordner nicht gefunden']);
    exit;
}

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
    
    log_success "Foto-API erstellt"
    echo
}

# Webserver konfigurieren
setup_webserver() {
    log_step "Webserver konfigurieren"
    
    local php_version=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    sudo lighttpd-enable-mod fastcgi > /dev/null 2>&1
    sudo lighttpd-enable-mod fastcgi-php > /dev/null 2>&1
    
    # Symlink zu Fotos
    sudo ln -sf /mnt/kita-fotos /var/www/html/Fotos
    
    # HTML-Dateien vom Repository herunterladen
    local temp_dir="/tmp/bilderrahmen-install"
    mkdir -p "$temp_dir"
    
    if curl -sSL "https://github.com/BratwurstPeter77/Bilderrahmen-Kita/archive/refs/heads/main.zip" -o "$temp_dir/repo.zip"; then
        cd "$temp_dir"
        unzip -q repo.zip
        sudo cp Bilderrahmen-Kita-main/scripts/slideshow.html /var/www/html/scripts/
        sudo cp Bilderrahmen-Kita-main/scripts/verwaltung.html /var/www/html/scripts/
        
        # Gruppen in HTML anpassen
        local groups_js=""
        for ((i=0; i<${#GROUP_NAMES[@]}; i++)); do
            if [ $i -gt 0 ]; then
                groups_js+=", "
            fi
            groups_js+="'${GROUP_NAMES[i]}'"
        done
        
        sudo sed -i "s/const folders = \[.*\];/const folders = [$groups_js];/" /var/www/html/scripts/verwaltung.html
        
        cd /
        rm -rf "$temp_dir"
    fi
    
    # Index-Weiterleitung
    echo '<meta http-equiv="refresh" content="0; url=/scripts/verwaltung.html">' | sudo tee /var/www/html/index.html > /dev/null
    
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 644 /var/www/html/scripts/*
    
    sudo systemctl enable lighttpd php${php_version}-fpm --quiet
    sudo systemctl restart php${php_version}-fpm lighttpd
    
    log_success "Webserver konfiguriert"
    echo
}

# Sicherheit einrichten
setup_security() {
    log_step "Sicherheit konfigurieren"
    
    # Firewall
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow from 192.168.0.0/16 to any port 80
    sudo ufw allow from 192.168.0.0/16 to any port 445
    sudo ufw allow from 192.168.0.0/16 to any port 22
    sudo ufw allow from 192.168.0.0/16 to any port 5353
    
    # Fail2Ban
    sudo systemctl enable fail2ban --quiet
    sudo systemctl start fail2ban
    
    # Automatische Updates
    sudo apt install -y -qq unattended-upgrades
    echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
    
    log_success "Sicherheit konfiguriert"
    echo
}

# System-Backup erstellen
create_system_backup() {
    log_step "System-Backup erstellen"
    
    local backup_dir="/mnt/kita-fotos/SYSTEM-BACKUP"
    mkdir -p "$backup_dir"
    
    # Backup-Script erstellen
    cat << 'BACKUP_EOF' > /home/pi/backup_sd_card.sh
#!/bin/bash
BACKUP_DIR="/mnt/kita-fotos/SYSTEM-BACKUP"
DATE=$(date '+%Y-%m-%d')

echo "=== SD-KARTEN BACKUP ==="
echo "Datum: $(date)"

mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/scripts"
mkdir -p "$BACKUP_DIR/system"

# Konfigurationsdateien
cp -r /etc/samba "$BACKUP_DIR/config/" 2>/dev/null
cp -r /etc/lighttpd "$BACKUP_DIR/config/" 2>/dev/null
cp /etc/fstab "$BACKUP_DIR/config/" 2>/dev/null
cp /etc/hostname "$BACKUP_DIR/config/" 2>/dev/null
cp /etc/hosts "$BACKUP_DIR/config/" 2>/dev/null

# Web-Dateien
cp -r /var/www/html "$BACKUP_DIR/scripts/" 2>/dev/null

# Home-Verzeichnis (ohne Fotos)
rsync -av --exclude="Fotos*" --exclude="*.jpg" --exclude="*.png" /home/pi/ "$BACKUP_DIR/home-pi/" 2>/dev/null

# System-Info
crontab -l > "$BACKUP_DIR/system/crontab.txt" 2>/dev/null
dpkg --get-selections > "$BACKUP_DIR/system/installed-packages.txt"
uname -a > "$BACKUP_DIR/system/system-info.txt"
lsblk > "$BACKUP_DIR/system/disks.txt"
df -h > "$BACKUP_DIR/system/disk-usage.txt"

cat > "$BACKUP_DIR/RESTORE-ANLEITUNG.txt" << EOL
Wiederherstellung des Kita-Bilderrahmen-Systems
================================================

Bei SD-Karten-Ausfall:

1. NEUE SD-KARTE mit Raspberry Pi OS bespielen
2. Repository neu installieren:
   curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash

3. ODER manuell aus diesem Backup:
   sudo cp -r config/samba/* /etc/samba/
   sudo cp -r config/lighttpd/* /etc/lighttpd/  
   sudo cp -r scripts/html/* /var/www/html/
   sudo cp -r home-pi/* /home/pi/
   
4. USB-Festplatte mounten und Dienste starten

Alle Fotos bleiben auf USB-Festplatte erhalten!
EOL

echo "Backup abgeschlossen: $(du -sh $BACKUP_DIR | cut -f1)"
BACKUP_EOF
    
    chmod +x /home/pi/backup_sd_card.sh
    /home/pi/backup_sd_card.sh
    
    log_success "System-Backup erstellt in: $backup_dir"
    echo
}

# Monats-Management einrichten
setup_monthly_management() {
    log_step "Monats-Management einrichten"
    
    cat << 'MONTHLY_EOF' > /home/pi/create_month_folders.sh
#!/bin/bash
FOTOS_DIR="/mnt/kita-fotos"
CURRENT_MONTH=$(date +%Y/%m)
NEXT_MONTH=$(date -d "+1 month" +%Y/%m)

for group in $(ls $FOTOS_DIR | grep -v SYSTEM-BACKUP); do
    if [ -d "$FOTOS_DIR/$group" ]; then
        mkdir -p "$FOTOS_DIR/$group/$CURRENT_MONTH"
        mkdir -p "$FOTOS_DIR/$group/$NEXT_MONTH"
    fi
done

chmod -R 755 "$FOTOS_DIR"
MONTHLY_EOF
    
    chmod +x /home/pi/create_month_folders.sh
    
    # Cronjob für monatliche Ausführung
    (crontab -l 2>/dev/null; echo "0 2 1 * * /home/pi/create_month_folders.sh") | crontab -
    
    log_success "Monats-Management eingerichtet"
    echo
}

# Installation abschließen
finish_installation() {
    local ip=$(hostname -I | awk '{print $1}' || echo "localhost")
    
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
    echo "💾 **USB-Festplatte:**"
    echo "   📊 Status: $(df -h /mnt/kita-fotos | tail -1)"
    echo "   📀 System-Backup: /mnt/kita-fotos/SYSTEM-BACKUP"
    echo
    echo "💻 **Windows-Zugriff:**"
    echo "   📁 Alle Fotos: \\\\bilderrahmen.local\\Fotos"
    echo
    echo "🚀 **Nächste Schritte:**"
    echo "   1. 🔄 Raspberry Pi neu starten: sudo reboot"
    echo "   2. 📱 Android-Apps konfigurieren (SMBSync2)"
    echo "   3. 🖼️  Testbilder hochladen"  
    echo "   4. 📱 Tablet-URLs testen"
    echo "   5. 🌐 Verwaltung öffnen: http://bilderrahmen.local"
    echo
    echo "📱 **Android-Apps:**"
    echo "   SMBSync2: https://play.google.com/store/apps/details?id=com.sentaroh.android.SMBSync2"
    echo
    echo "🔧 **System-Status prüfen:**"
    echo "   /home/pi/check_backup.sh"
    echo
    echo "================================================================"
    echo "🎯 Viel Erfolg mit dem Bilderrahmen-System!"
    echo "================================================================"
}

# Status-Check-Script erstellen
create_status_script() {
    cat << 'STATUS_EOF' > /home/pi/check_backup.sh
#!/bin/bash
echo "=== BACKUP-STATUS ==="
echo "Datum: $(date)"
echo ""

if [ -d "/mnt/kita-fotos/SYSTEM-BACKUP" ]; then
    echo "✅ System-Backup vorhanden"
    BACKUP_DATE=$(stat -c %y "/mnt/kita-fotos/SYSTEM-BACKUP" | cut -d' ' -f1)
    BACKUP_SIZE=$(du -sh "/mnt/kita-fotos/SYSTEM-BACKUP" | cut -f1)
    echo "   Erstellt: $BACKUP_DATE"
    echo "   Größe: $BACKUP_SIZE"
else
    echo "❌ Kein System-Backup gefunden"
fi

echo ""
echo "USB-Festplatte:"
df -h /mnt/kita-fotos
STATUS_EOF
    
    chmod +x /home/pi/check_backup.sh
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
    create_system_backup
    setup_monthly_management
    create_status_script
    finish_installation
}

# Script ausführen
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'log_error "Installation abgebrochen. Zeile: $LINENO"' ERR
    main "$@"
fi
