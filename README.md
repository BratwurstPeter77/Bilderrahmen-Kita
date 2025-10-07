# 🖼️ Bilderrahmen-Kita

**Digitales Bilderrahmen-System für Kindergärten mit automatischer Foto-Synchronisation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)]()

## ⚡ Ein-Zeilen-Installation

```bash
curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash
```


## 🎯 Über das Projekt

Der **Bilderrahmen-Kita** ist ein speziell für Kindergärten entwickeltes System, das automatisch Fotos von verschiedenen Gruppen sammelt und als Slideshow auf Tablets anzeigt. Die Fotos werden auf einer USB-Festplatte gespeichert und automatisch nach Monaten sortiert.

**Entwickelt für:**
- 🏫 Kindergärten und Kitas
- 👨‍👩‍👧‍👦 Familienzentren  
- 🎓 Grundschulen
- 👵 Seniorenheime
- 🏠 Private Haushalte

## 🚀 Features

### 💾 **USB-Festplatte für maximale Performance**
- **Kein SD-Karten-Verschleiß:** Fotos auf USB 3.0 Festplatte
- **Hohe Geschwindigkeit:** 5 Tablets gleichzeitig ohne Ruckler
- **Viel Speicherplatz:** 1-4TB für jahrelange Fotos
- **Automatisches System-Backup:** Einmaliges SD-Karten-Backup bei Installation

### 📱 **Automatische Foto-Synchronisation**
- Upload von Erzieher-Handys via WLAN
- Verschiedene Apps unterstützt (SMBSync2, PhotoSync)
- Automatische Sortierung nach Gruppen und Monaten

### 📅 **Monatsweise Organisation**
- Fotos werden automatisch nach Jahr/Monat sortiert
- Einfaches Löschen ganzer Monate
- Struktur: `Gruppenname/2025/01/`, `Gruppenname/2025/02/`, etc.
- Automatische Erstellung neuer Monats-Ordner

### 🎨 **Flexible Gruppenverwaltung**  
- 1-10 individuelle Gruppen (Käfer, Bienen, Schmetterlinge, etc.)
- Benutzerdefinierte Gruppennamen ohne Umlaute
- Separate Slideshows für jede Gruppe

### 📱 **Tablet-optimiert**
- Responsive Design für 5 Tablets gleichzeitig
- Vollbild-Slideshows mit sanften Übergängen
- Touch-Steuerung und automatischer Start
- Apple-Style Design mit modernen Übergängen

### 🌐 **Einfache Verwaltung**
- Web-Interface unter `bilderrahmen.local`
- Bildvorschauen nach Monaten sortiert
- Tablet-Links für alle Gruppen
- System-Backup-Status einsehbar

### 💾 **Windows-Integration**
- Netzlaufwerke für einfache Bilderverwaltung
- Drag & Drop von Fotos direkt in Monats-Ordner
- Zugriff vom Büro-PC der Kita-Leitung

### 🔒 **Sicherheit & DSGVO**
- DSGVO-konform (lokale Speicherung)
- Firewall-Schutz (nur lokales Netzwerk)
- Fail2Ban gegen Brute-Force-Angriffe
- Automatische Security-Updates

## 📋 Voraussetzungen

### Hardware (empfohlen)
- **Raspberry Pi**: 4B mit 4GB RAM
- **USB-Festplatte**: 1-4TB, USB 3.0 für beste Performance
- **Tablets**: 5 Android/iOS Tablets für Slideshow-Anzeige
- **Netzwerk**: Stabiles WLAN im Kita-Bereich
- **SD-Karte**: 32GB (nur für Betriebssystem)

### Empfohlene USB-Festplatten
**Preis-Leistung (HDD):**
- Western Digital Elements 2TB (~60€)
- Seagate Expansion 4TB (~90€)
- Toshiba Canvio Basics 2TB (~55€)

**Maximale Performance (SSD):**
- Samsung T7 1TB (~90€)
- SanDisk Extreme Portable 1TB (~110€)
- Crucial X6 2TB (~150€)

### Software
- **Raspberry Pi OS**: Bookworm oder neuer
- **Android-Geräte**: Erzieher-Handys mit WLAN-Zugang

## 🎮 Installation

**Das Installationsscript führt Sie durch:**

1. **📦 System-Setup**: Alle benötigten Programme installieren
2. **👤 Benutzer erstellen**: Benutzername und Passwort für Netzwerkzugriff
3. **💾 USB-Festplatte**: Automatische Erkennung, Formatierung und Einrichtung
4. **👥 Gruppen konfigurieren**: Eingabe der Kita-Gruppennamen
5. **📁 Ordner erstellen**: Monatsweise Struktur für alle Gruppen
6. **🌐 Webserver einrichten**: Management-Interface unter `bilderrahmen.local`
7. **💾 Netzwerkfreigaben**: Windows/Android-Zugriff konfigurieren
8. **🔒 Sicherheit**: Firewall und Fail2Ban aktivieren
9. **📀 System-Backup**: Einmaliges Backup der SD-Karte auf USB-Festplatte

### Manuelle Installation

Siehe [INSTALLATION.md](docs/INSTALLATION.md) für detaillierte Schritt-für-Schritt-Anweisungen.

## 🏫 Kita-spezifische Nutzung

### Typische Gruppennamen
käfer, bienen, schmetterlinge, marienkäfer, raupen,
frösche, mäuse, bären, löwen, elefanten, hasen, igel

text

### Automatische Ordnerstruktur
USB-Festplatte (/mnt/kita-fotos/):
├── SYSTEM-BACKUP/ → SD-Karten-Backup
│ ├── RESTORE-ANLEITUNG.txt → Wiederherstellungs-Guide
│ ├── config/ → Samba, Lighttpd Configs
│ ├── scripts/ → Web-Interface Backup
│ └── system/ → System-Informationen
├── käfer/
│ ├── 2025/
│ │ ├── 01/ → Januar 2025
│ │ ├── 02/ → Februar 2025
│ │ └── 03/ → März 2025
│ └── README.txt
├── bienen/
│ └── 2025/01/
└── weitere-gruppen.../

text

### Foto-Workflow für Erzieher

1. **📱 Fotos aufnehmen** mit dem Handy während Aktivitäten
2. **🔄 Automatischer Upload** wenn im Kita-WLAN (SMBSync2)
3. **📅 Automatische Sortierung** in aktuellen Monats-Ordner
4. **📱 Sofortige Anzeige** auf allen 5 Tablets
5. **👪 Eltern sehen** die neuen Fotos beim Abholen

### System-Backup & Wiederherstellung

**Bei der Installation wird automatisch erstellt:**
- **Speicherort:** `/mnt/kita-fotos/SYSTEM-BACKUP/`
- **Inhalt:** Komplette SD-Karten-Konfiguration, Web-Files, Einstellungen
- **Wiederherstellung:** Detaillierte Anleitung in `RESTORE-ANLEITUNG.txt`
- **Sicherheit:** Bei SD-Karten-Ausfall bleibt alles wiederherstellbar

**Status prüfen:**
/home/pi/check_backup.sh

text

## 📱 Tablet-Setup

### Slideshow-URLs für 5 Tablets:

Tablet 1 (Käfer): http://bilderrahmen.local/Fotos/käfer
Tablet 2 (Bienen): http://bilderrahmen.local/Fotos/bienen
Tablet 3 (Frösche): http://bilderrahmen.local/Fotos/frösche
Tablet 4 (Mäuse): http://bilderrahmen.local/Fotos/mäuse
Tablet 5 (Bären): http://bilderrahmen.local/Fotos/bären

text

### Tablet-Konfiguration:
1. **Browser öffnen** (Chrome, Firefox, Safari)
2. **URL eingeben**: `http://bilderrahmen.local/Fotos/GRUPPENNAME`
3. **Vollbild aktivieren** (meist F11 oder Browser-Menü)
4. **Lesezeichen setzen** für schnellen Zugriff
5. **Tablet befestigen** im Gruppenraum

### URL-Parameter für Anpassungen:
- `?delay=5000` - Anzeigedauer pro Bild (5 Sekunden)
- `&shuffle=true` - Zufällige Reihenfolge
- `&month=2025-01` - Nur Januar 2025 anzeigen
- `&autostart=true` - Automatischer Slideshow-Start

## 📱 Android-Apps für Erzieher

### SMBSync2 (kostenlos, empfohlen)
- **Automatische Synchronisation** bei WLAN-Verbindung
- **Separates Profil** für jede Kita-Gruppe
- **Batterie-schonend**: Upload nur beim Laden
- **Zuverlässig**: Bewährt in vielen Kitas

### PhotoSync (Premium-Features)
- **Erweiterte Automatisierung** mit mehr Optionen
- **Foto-Auswahl** vor Upload möglich
- **Terminierte Synchronisation** zu bestimmten Uhrzeiten

**Download-Links:**
- [SMBSync2 bei Google Play](https://play.google.com/store/apps/details?id=com.sentaroh.android.SMBSync2)
- [PhotoSync bei Google Play](https://play.google.com/store/apps/details?id=com.touchbyte.photosync)

**Detaillierte Konfiguration:** Siehe [SMBSync2-Anleitung.md](android/SMBSync2-Anleitung.md)

## 🌐 Web-Verwaltung

**Zugriff nach der Installation:**
http://bilderrahmen.local

text

### Features für Kita-Personal:
- **📱 Tablet-Links** für alle 5 Slideshows auf einen Blick
- **📁 Monats-Übersicht** aller Gruppen mit Bildanzahl
- **🖼️ Bildvorschau** der letzten hochgeladenen Fotos
- **▶️ Slideshow-Start** für jede Gruppe einzeln testbar
- **💾 System-Status** und USB-Festplatten-Informationen
- **📊 Speicherplatz-Übersicht** pro Gruppe und Monat

## 💻 Zugriff vom Büro-PC (Windows)

### Netzlaufwerk einrichten:
1. **Windows Explorer** öffnen (Windows + E)
2. **Netzwerk-Adresse eingeben**: `\\bilderrahmen.local\Fotos`
3. **Anmelden** mit bei Installation erstellten Daten:
   - Benutzername: [Ihr gewählter Benutzername]
   - Passwort: [Ihr gewähltes Passwort]
4. **Als Netzlaufwerk verbinden** für permanenten Zugriff
5. **Fotos verwalten**: Drag & Drop wie bei normalem Ordner

### Beispiel-Pfade für direkte Monats-Zugriffe:
\bilderrahmen.local\Fotos\käfer\2025\01\ → Käfer Januar 2025
\bilderrahmen.local\Fotos\bienen\2025\01\ → Bienen Januar 2025
\bilderrahmen.local\Fotos\frösche\2025\02\ → Frösche Februar 2025

text

### Monats-Verwaltung über Windows:
- **Alte Monate löschen**: Kompletten Monats-Ordner löschen
- **Neue Monate**: Werden automatisch vom System erstellt
- **Archivierung**: Komplette Monats-Ordner auf USB-Stick kopieren

## 🛠️ Fehlerbehebung

### Häufige Probleme und Lösungen:

**"Keine Bilder gefunden"**
- ✅ **Prüfen**: USB-Festplatte angeschlossen? `df -h | grep kita`
- ✅ **Prüfen**: Sind Fotos im richtigen Monats-Ordner?
- ✅ **Lösung**: Web-Verwaltung unter `bilderrahmen.local` öffnen

**"bilderrahmen.local nicht erreichbar"**  
- ✅ **Prüfen**: Gerät im gleichen WLAN wie Raspberry Pi?
- ✅ **Alternative**: IP-Adresse verwenden: `http://192.168.1.XXX`
- ✅ **Lösung**: Router neu starten oder mDNS aktivieren

**"Tablet zeigt veraltete Fotos"**
- ✅ **Lösung 1**: Browser-Cache leeren (Strg+F5 oder Cmd+Shift+R)
- ✅ **Lösung 2**: Tablet neu starten
- ✅ **Lösung 3**: Slideshow-URL komplett neu laden

**"Android kann nicht hochladen"**
- ✅ **Prüfen**: Richtiger Benutzername/Passwort in SMBSync2?
- ✅ **Prüfen**: WLAN-Verbindung stabil und im gleichen Netz?
- ✅ **Lösung**: Samba neu starten: `sudo systemctl restart smbd`

**"USB-Festplatte wird nicht erkannt"**
- ✅ **Prüfen**: USB-Kabel und Stromversorgung der Festplatte
- ✅ **Diagnose**: `lsblk` und `df -h` im Terminal ausführen
- ✅ **Lösung**: Festplatte neu mounten: `sudo mount -a`

**"System nach Stromausfall nicht erreichbar"**
- ✅ **Warten**: 5-10 Minuten bis vollständiger Start
- ✅ **Prüfen**: SD-Karte beschädigt? → System-Backup verwenden
- ✅ **Lösung**: Neustart: `sudo reboot`

### System-Wiederherstellung bei SD-Karten-Ausfall:

**Die Fotos sind sicher** - sie liegen auf der USB-Festplatte!

1. **Neue SD-Karte** mit Raspberry Pi OS bespielen
2. **USB-Festplatte** anschließen (alle Fotos bleiben erhalten!)
3. **Backup-Ordner** mounten und öffnen: `/mnt/kita-fotos/SYSTEM-BACKUP/`
4. **Anleitung befolgen**: Datei `RESTORE-ANLEITUNG.txt` öffnen
5. **Automatische Wiederherstellung**: Repository neu installieren oder manuell
6. **System testen**: Tablets und Web-Verwaltung prüfen

### Erweiterte Diagnose:

System-Status komplett prüfen
sudo systemctl status smbd lighttpd avahi-daemon

USB-Festplatten-Gesundheit
sudo smartctl -a /dev/sda

Netzwerk-Konnektivität
ping bilderrahmen.local

Backup-Status
/home/pi/check_backup.sh

Log-Dateien einsehen
journalctl -f

text

## 📊 Performance-Optimierung

### USB-Festplatte vs. SD-Karte:

| Aspekt | SD-Karte | USB 3.0 HDD | USB 3.0 SSD |
|--------|----------|-------------|-------------|
| **Geschwindigkeit** | 10-40 MB/s | 100-150 MB/s | 200-400 MB/s |
| **5 Tablets gleichzeitig** | ⚠️ Grenzwertig | ✅ Problemlos | ✅ Butterweich |
| **Lebensdauer** | ⚠️ Verschleiß | ✅ Robust | ✅ Sehr robust |
| **Speicherplatz** | 32-128 GB | 1-4 TB | 500 GB-2 TB |
| **Kosten** | ~20€ | ~60€ | ~90€ |

### Automatische Optimierungen im System:
- **Bild-Caching**: Häufig aufgerufene Bilder werden zwischengespeichert
- **Lazy Loading**: Tablets laden Bilder nur bei Bedarf
- **Komprimierung**: Automatische Größenoptimierung für Web-Anzeige
- **Monats-Indexierung**: Schnelle Suche durch intelligente Ordnerstruktur

## 📄 Lizenz

Dieses Projekt steht unter der **MIT-Lizenz** - siehe [LICENSE](LICENSE) für Details.

**Das bedeutet für Kitas:**
- ✅ **Kostenlose Nutzung** (auch kommerziell)
- ✅ **Änderungen erlaubt** für eigene Bedürfnisse
- ✅ **Weitergabe** an andere Kitas möglich
- ✅ **Keine Lizenzgebühren** oder versteckte Kosten
- ⚠️ **Keine Gewährleistung** 

---
### Automatische Installation (empfohlen)

