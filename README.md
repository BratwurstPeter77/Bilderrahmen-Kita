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

Der **Bilderrahmen-Kita** ist ein speziell für Kindergärten entwickeltes System, das automatisch Fotos von verschiedenen Gruppen sammelt und als Slideshow auf Tablets anzeigt. Die Fotos werden automatisch nach Monaten sortiert für einfache Verwaltung.

**Entwickelt für:**
- 🏫 Kindergärten und Kitas
- 👨‍👩‍👧‍👦 Familienzentren  
- 🎓 Grundschulen
- 👵 Seniorenheime
- 🏠 Private Haushalte

## 🚀 Features

### 📱 **Automatische Foto-Synchronisation**
- Upload von Erzieher-Handys via WLAN
- Verschiedene Android-Apps unterstützt
- Automatische Sortierung nach Gruppen und Monaten

### 📅 **Monatsweise Organisation**
- Fotos werden automatisch nach Jahr/Monat sortiert
- Einfaches Löschen ganzer Monate
- Struktur: `Gruppenname/2025/01/`, `Gruppenname/2025/02/`, etc.

### 🎨 **Flexible Gruppenverwaltung**
- 1-10 individuelle Gruppen (Käfer, Bienen, Schmetterlinge, etc.)
- Benutzerdefinierte Gruppennamen ohne Umlaute
- Separate Slideshows für jede Gruppe

### 📱 **Tablet-optimiert**
- Responsive Design für 5 Tablets gleichzeitig
- Vollbild-Slideshows mit sanften Übergängen
- Apple-Style Design
- Anpassbare Anzeigedauer pro Bild

### 🌐 **Einfache Verwaltung**
- Web-Interface unter `bilderrahmen.local`
- Bildvorschauen nach Monaten
- Einfache Verwaltung ohne technische Kenntnisse

### 💾 **Windows-Integration**
- Netzlaufwerke für einfache Bilderverwaltung
- Drag & Drop von Fotos
- Zugriff vom Büro-PC der Leitung

## 📋 Voraussetzungen

### Hardware
- **Raspberry Pi**: 3B+ oder neuer (empfohlen: Pi 4 mit 4GB RAM)
- **Tablets**: 5 Android/iOS Tablets für Slideshow-Anzeige
- **Netzwerk**: WLAN oder Ethernet im Kita-Netzwerk
- **SD-Karte**: Mindestens 32GB (Class 10)

### Software
- **Raspberry Pi OS**: Bookworm oder neuer
- **Android-Geräte**: Erzieher-Handys mit WLAN-Zugang

### Kita-spezifische Anforderungen
- ✅ DSGVO-konform (lokale Speicherung)
- ✅ Keine Cloud-Verbindung erforderlich
- ✅ Einfache Bedienung für pädagogisches Personal
- ✅ Robuster Betrieb im Kita-Alltag

## 🎮 Installation

### Automatische Installation (empfohlen)

```bash
curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/install.sh | bash
```

Das Installationsscript führt Sie durch:

1. **📦 System-Setup**: Alle benötigten Programme werden installiert
2. **👤 Benutzer erstellen**: Eingabe von Benutzername und Passwort für Netzwerkzugriff
3. **👥 Gruppen konfigurieren**: Eingabe der Kita-Gruppennamen (z.B. "käfer", "bienen", "schmetterlinge")
4. **📁 Ordner erstellen**: Automatische Struktur für alle Gruppen mit Monats-Ordnern
5. **🌐 Webserver einrichten**: Management-Interface unter `bilderrahmen.local`
6. **💾 Netzwerkfreigaben**: Windows-Zugriff vom Büro-PC

### Manuelle Installation

Siehe [INSTALLATION.md](docs/INSTALLATION.md) für detaillierte Anweisungen.

## 🏫 Kita-spezifische Nutzung

### Typische Gruppennamen
```
käfer, bienen, schmetterlinge, marienkäfer, raupen,
frösche, mäuse, bären, löwen, elefanten, hasen, igel
```

### Ordnerstruktur (automatisch erstellt)
```
/Fotos/
├── käfer/
│   ├── 2025/
│   │   ├── 01/         → Januar 2025
│   │   ├── 02/         → Februar 2025
│   │   └── 03/         → März 2025
│   └── 2024/
│       └── 12/         → Dezember 2024
├── bienen/
│   └── 2025/
│       └── 01/
└── frösche/
    └── 2025/
        └── 01/
```

### Foto-Workflow für Erzieher

1. **📱 Fotos aufnehmen** mit dem Handy während Aktivitäten
2. **🔄 Automatischer Upload** wenn im Kita-WLAN
3. **📅 Automatische Sortierung** nach aktueller Jahr/Monat
4. **📱 Sofortige Anzeige** auf allen 5 Tablets
5. **👪 Eltern sehen** die Fotos beim Abholen

### Monats-Management

**Fotos löschen:**
- Ganzer Monat: Ordner `käfer/2024/12/` löschen
- Einzelne Fotos: In entsprechendem Monats-Ordner löschen

**Archivierung:**
- Alte Monate auf USB-Stick sichern
- Dann vom Raspberry Pi löschen

## 📱 Tablet-Setup

### Slideshow-URLs für 5 Tablets:

```
Tablet 1 (Käfer):     http://bilderrahmen.local/Fotos/käfer
Tablet 2 (Bienen):    http://bilderrahmen.local/Fotos/bienen
Tablet 3 (Frösche):   http://bilderrahmen.local/Fotos/frösche
Tablet 4 (Mäuse):     http://bilderrahmen.local/Fotos/mäuse
Tablet 5 (Bären):     http://bilderrahmen.local/Fotos/bären
```

### Tablet-Konfiguration:
1. **Browser öffnen** (Chrome, Firefox, Safari)
2. **URL eingeben**: `http://bilderrahmen.local/Fotos/GRUPPENNAME`
3. **Vollbild aktivieren** (F11 oder Browser-Menü)
4. **Tablet befestigen** im Gruppenraum/Eingangsbereich

### Slideshow-Parameter:
- `?delay=5000` - Anzeigedauer pro Bild (5 Sekunden)
- `&shuffle=true` - Zufällige Reihenfolge
- `&month=2025-01` - Nur Januar 2025 anzeigen
- `&autostart=true` - Automatischer Start

## 📱 Android-Apps für Erzieher

### SMBSync2 (kostenlos, empfohlen)
- Automatische Synchronisation bei WLAN-Verbindung
- Separates Profil für jede Gruppe
- Upload nur bei Handy-Ladung (Batterie-schonend)

### PhotoSync (Premium-Features)
- Erweiterte Automatisierung
- Foto-Auswahl vor Upload
- Terminierte Synchronisation

**Download-Links:**
- [SMBSync2 bei Google Play](https://play.google.com/store/apps/details?id=com.sentaroh.android.SMBSync2)
- [PhotoSync bei Google Play](https://play.google.com/store/apps/details?id=com.touchbyte.photosync)

## 🌐 Web-Verwaltung

Nach der Installation verfügbar unter:
```
http://bilderrahmen.local
```

### Features für Erzieher:
- 📁 **Monats-Übersicht** aller Gruppen
- 🖼️ **Bildvorschau** nach Monaten sortiert
- ▶️ **Slideshow-Links** für jede Gruppe
- 🗑️ **Monats-Verwaltung** (Ganze Monate löschen)
- 📊 **Speicherplatz-Übersicht**

## 💻 Zugriff vom Büro-PC (Windows)

### Netzlaufwerk einrichten:
1. **Windows Explorer** öffnen (Windows + E)
2. **Adresse eingeben**: `\\bilderrahmen.local\Fotos`
3. **Anmelden**: Mit erstelltem Benutzername + Passwort
4. **Fotos verwalten**: Drag & Drop wie bei normalem Ordner

### Beispiel-Pfade:
```
\\bilderrahmen.local\Fotos\käfer\2025\01\     → Käfer Januar 2025
\\bilderrahmen.local\Fotos\bienen\2025\01\    → Bienen Januar 2025  
\\bilderrahmen.local\Fotos\frösche\2025\01\   → Frösche Januar 2025
```

## 🛠️ Fehlerbehebung

### Häufige Probleme:

**"Keine Bilder gefunden"**
- Prüfen: Sind Fotos im richtigen Monats-Ordner?
- Prüfen: Haben Dateien die richtige Endung? (.jpg, .png)
- Lösung: Web-Verwaltung unter `bilderrahmen.local` öffnen

**"bilderrahmen.local nicht erreichbar"**  
- Prüfen: Ist das Gerät im gleichen WLAN?
- Prüfen: IP-Adresse verwenden: `http://192.168.1.XXX`
- Lösung: Router neu starten oder mDNS aktivieren

**"Tablet zeigt alte Fotos"**
- Browser-Cache leeren (Strg+F5)
- Tablet neu starten
- Slideshow-URL neu laden

**"Android kann nicht uploaden"**
- Prüfen: Richtiger Benutzername/Passwort?
- Prüfen: WLAN-Verbindung stabil?
- Lösung: Samba-Dienst neu starten: `sudo systemctl restart smbd`

## 📅 Monats-Verwaltung

### Automatische Sortierung
Neue Fotos werden automatisch in den aktuellen Monats-Ordner sortiert:
```
Upload heute → käfer/2025/10/   (Oktober 2025)
Upload nächsten Monat → käfer/2025/11/   (November 2025)
```

### Ganze Monate löschen
```bash
# Über Web-Interface (empfohlen)
http://bilderrahmen.local → Monats-Verwaltung

# Über Windows
\\bilderrahmen.local\Fotos\käfer\2024\12\ → Ordner löschen

# Über SSH (für Experten)
rm -rf /home/pi/Fotos/käfer/2024/12/
```

### Speicherplatz überwachen
Die Web-Verwaltung zeigt:
- Fotos pro Monat
- Speicherverbrauch pro Gruppe  
- Empfehlungen für Archivierung

## 📄 Lizenz

Dieses Projekt steht unter der **MIT-Lizenz** - siehe [LICENSE](LICENSE) für Details.

**Das bedeutet:**
- ✅ Kostenlose Nutzung (auch kommerziell)
- ✅ Änderungen und Anpassungen erlaubt
- ✅ Weitergabe an andere Kitas erlaubt
- ✅ Keine Gewährleistung oder Haftung

---

**Entwickelt mit ❤️ für Kindergärten und die Freude am Teilen schöner Momente**

*"Jedes Foto erzählt eine Geschichte - wir helfen dabei, sie zu teilen."*
