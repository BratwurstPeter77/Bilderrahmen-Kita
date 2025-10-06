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

Der **Bilderrahmen-Kita** ist ein speziell für Kindergärten entwickeltes System, das automatisch Fotos von verschiedenen Gruppen (Käfer, Bienen, Schmetterlinge, etc.) sammelt und als Slideshow anzeigt. Perfekt geeignet für Eingangsbereiche, Gruppenräume oder den Elternbereich.

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
- Automatische Sortierung nach Gruppen

### 🎨 **Flexible Gruppenverwaltung**
- 1-10 individuelle Gruppen (Käfer, Bienen, Schmetterlinge, etc.)
- Benutzerdefinierte Gruppennamen ohne Umlaute
- Separate Slideshows für jede Gruppe

### 🌐 **Web-Verwaltung**
- Moderne Browser-Oberfläche für Erzieher
- Bildvorschauen und Statistiken
- Einfache Verwaltung ohne technische Kenntnisse

### 🖥️ **Professionelle Anzeige**
- Vollbild-Slideshows mit sanften Übergängen
- Apple-Style Design
- Anpassbare Anzeigedauer pro Bild
- Automatischer Tag/Nacht-Modus

### 💾 **Windows-Integration**
- Netzlaufwerke für einfache Bilderverwaltung
- Drag & Drop von Fotos
- Zugriff vom Büro-PC der Leitung

### 🔄 **Wartungsfrei**
- Automatischer Start beim Einschalten
- Selbstheilende Updates
- Robust gegen Stromausfälle

## 📋 Voraussetzungen

### Hardware
- **Raspberry Pi**: 3B+ oder neuer (empfohlen: Pi 4 mit 4GB RAM)
- **Display**: HDMI-Monitor, TV oder Touchscreen
- **Netzwerk**: WLAN oder Ethernet im Kita-Netzwerk
- **SD-Karte**: Mindestens 16GB (Class 10)

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
2. **👥 Gruppen konfigurieren**: Eingabe der Kita-Gruppennamen (z.B. "käfer", "bienen", "schmetterlinge")
3. **📁 Ordner erstellen**: Automatische Struktur für alle Gruppen
4. **🌐 Webserver einrichten**: Management-Interface für Erzieher
5. **💾 Netzwerkfreigaben**: Windows-Zugriff vom Büro-PC
6. **🚀 Autostart**: Slideshow startet automatisch

### Manuelle Installation

Siehe [INSTALLATION.md](docs/INSTALLATION.md) für detaillierte Anweisungen.

## 🏫 Kita-spezifische Nutzung

### Typische Gruppennamen
```
käfer, bienen, schmetterlinge, marienkäfer, raupen,
frösche, mäuse, bären, löwen, elefanten, hasen, igel
```

### Foto-Workflow für Erzieher

1. **📱 Fotos aufnehmen** mit dem Handy während Aktivitäten
2. **🔄 Automatischer Upload** wenn im Kita-WLAN
3. **🖼️ Sofortige Anzeige** auf dem Bilderrahmen
4. **👪 Eltern sehen** die Fotos beim Abholen

### Datenschutz (DSGVO)

- ✅ **Lokale Speicherung**: Alle Fotos bleiben in der Kita
- ✅ **Keine Cloud**: Kein Upload zu externen Diensten
- ✅ **Zugriffskontrolle**: Nur autorisierte Geräte können uploaden
- ✅ **Löschfunktion**: Einfache Entfernung von Fotos
- ✅ **Einverständnis**: System unterstützt Foto-Freigaben der Eltern

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
http://RASPBERRY-IP/slideshows/scripts/verwaltung.html
```

### Features für Erzieher:
- 📊 **Dashboard** mit Foto-Statistiken pro Gruppe
- 🖼️ **Bildvorschau** der letzten Uploads
- ▶️ **Slideshow-Start** für jede Gruppe einzeln
- 🗑️ **Foto-Verwaltung** (Löschen, Sortieren)
- ⚙️ **Einstellungen** (Anzeigedauer, Reihenfolge)

## 💻 Zugriff vom Büro-PC (Windows)

### Netzlaufwerk einrichten:
1. **Windows Explorer** öffnen (Windows + E)
2. **Adresse eingeben**: `\\RASPBERRY-IP\GRUPPENNAME`
3. **Anmelden**: Benutzername `pi` + Passwort
4. **Fotos verwalten**: Drag & Drop wie bei normalem Ordner

### Beispiel-Pfade:
```
\\192.168.1.100\käfer      → Käfer-Gruppe
\\192.168.1.100\bienen     → Bienen-Gruppe  
\\192.168.1.100\frösche    → Frösche-Gruppe
```

## 🔧 Konfiguration

### Mehrere Bildschirme
```bash
# Verschiedene Gruppen auf verschiedenen Displays
nano ~/.config/lxsession/LXDE-pi/autostart

# Käfer-Gruppe auf Display 1:
slideshow.html?folder=käfer&delay=5000

# Bienen-Gruppe auf Display 2:  
slideshow.html?folder=bienen&delay=3000
```

### Slideshow-Parameter:
- `?folder=käfer` - Spezifische Gruppe anzeigen
- `&delay=5000` - Anzeigedauer pro Bild (5 Sekunden)
- `&shuffle=true` - Zufällige Reihenfolge
- `&controls=hide` - Bedienelemente ausblenden

## 🔄 Updates & Wartung

### Automatisches Update:
```bash
curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/scripts/update.sh | bash
```

### Wöchentliche Updates (empfohlen):
```bash
crontab -e
# Hinzufügen:
0 3 * * 0 curl -sSL https://raw.githubusercontent.com/BratwurstPeter77/Bilderrahmen-Kita/main/scripts/update.sh | bash
```

## 🛠️ Fehlerbehebung

### Häufige Probleme:

**"Keine Bilder gefunden"**
- Prüfen: Sind Fotos im richtigen Ordner?
- Prüfen: Haben Dateien die richtige Endung? (.jpg, .png)
- Lösung: Web-Verwaltung öffnen und Ordner-Status prüfen

**"Android kann nicht verbinden"**  
- Prüfen: Ist das Handy im gleichen WLAN?
- Prüfen: Ist die Raspberry Pi IP-Adresse korrekt?
- Lösung: Samba-Dienst neu starten: `sudo systemctl restart smbd`

**"Slideshow startet nicht"**
- Prüfen: Monitor angeschlossen und eingeschaltet?
- Prüfen: Raspberry Pi vollständig gebootet? (2-3 Minuten warten)
- Lösung: Neustart: `sudo reboot`

### Support-Kontakt:
Bei technischen Problemen bitte ein [Issue erstellen](https://github.com/BratwurstPeter77/Bilderrahmen-Kita/issues) mit:
- Raspberry Pi Modell
- Fehlermeldung (Screenshot)
- Verwendete Gruppennamen
- Android-App Version

## 🤝 Beitragen

Dieses Projekt lebt von der Community! Beiträge sind herzlich willkommen:

### Wie Sie helfen können:
- 🐛 **Bugs melden**: Issues mit detaillierter Beschreibung
- 💡 **Features vorschlagen**: Neue Ideen für Kita-Bedürfnisse  
- 📖 **Dokumentation**: Verbesserungen und Übersetzungen
- 💻 **Code**: Pull Requests mit neuen Features

### Entwickler-Setup:
```bash
git clone https://github.com/BratwurstPeter77/Bilderrahmen-Kita.git
cd Bilderrahmen-Kita
# Eigene Änderungen vornehmen
git checkout -b feature/neue-funktion
git commit -m "Neue Funktion hinzugefügt"
git push origin feature/neue-funktion
# Pull Request erstellen
```

## 📄 Lizenz

Dieses Projekt steht unter der **MIT-Lizenz** - siehe [LICENSE](LICENSE) für Details.

**Das bedeutet:**
- ✅ Kostenlose Nutzung (auch kommerziell)
- ✅ Änderungen und Anpassungen erlaubt
- ✅ Weitergabe an andere Kitas erlaubt
- ✅ Keine Gewährleistung oder Haftung

## 🙏 Danksagungen

- **Raspberry Pi Foundation** für die kostengünstige Hardware
- **SMBSync2 Entwickler** für die zuverlässige Android-App
- **Kita-Erzieher** für wertvolles Feedback und Testen
- **Open Source Community** für Inspiration und Code-Beiträge

## 📞 Kontakt & Community

- 🐛 **Issues**: [GitHub Issues](https://github.com/BratwurstPeter77/Bilderrahmen-Kita/issues)
- 💬 **Diskussionen**: [GitHub Discussions](https://github.com/BratwurstPeter77/Bilderrahmen-Kita/discussions)
- 📧 **E-Mail**: [Deine E-Mail einfügen]
- 🌐 **Website**: [Falls vorhanden]

---

**Entwickelt mit ❤️ für Kindergärten und die Freude am Teilen schöner Momente**

*"Jedes Foto erzählt eine Geschichte - wir helfen dabei, sie zu teilen."*
