# 📱 Android SMBSync2 Anleitung für Bilderrahmen-Kita

## Überblick

**SMBSync2** ist die empfohlene kostenlose App für die automatische Synchronisation von Kita-Fotos zum Raspberry Pi.

## Installation

1. **Google Play Store** öffnen
2. Nach **"SMBSync2"** suchen
3. App von **Sentaroh** installieren
4. App öffnen und Berechtigungen erteilen

## Konfiguration für Kita-Gruppen

### Grundkonfiguration

1. **SMBSync2** öffnen
2. **"+"** (Plus) antippen → "Sync-Profil hinzufügen"
3. **Profil-Name** eingeben (z.B. "Kita Käfer")

### Master-Ordner (Quelle) einstellen

1. **"Master-Ordner"** antippen
2. **"Interner Speicher"** auswählen
3. Navigieren zu: **DCIM → Camera**
4. **"Auswählen"** antippen

### Ziel-Ordner (Raspberry Pi) einstellen

1. **"Ziel"** antippen
2. **"SMB"** auswählen
3. **SMB-Einstellungen** konfigurieren:

#### SMB-Server Einstellungen:
```
Server-Adresse: bilderrahmen.local
(oder IP-Adresse: z.B. 192.168.1.100)

Port: 445 (Standard)

Freigabename: GRUPPENNAME
(z.B. käfer, bienen, schmetterlinge, etc.)

Benutzername: [Bei Installation erstellter Benutzername]
Passwort: [Bei Installation erstelltes Passwort]

Domäne: (leer lassen)
```

4. **"Verbindung testen"** antippen
5. Bei erfolgreichem Test: **"OK"** antippen

### Synchronisations-Einstellungen

#### Sync-Richtung:
- **"Mirror (Spiegeln)"** ODER **"Copy (Kopieren)"** auswählen
- **NICHT "Move"** verwenden (Fotos würden vom Handy gelöscht)

#### Datei-Filter:
1. **"Erweiterte Optionen"** → **"Datei-Filter"**
2. **"Nur Dateien mit Endungen:"** aktivieren
3. Eingeben: `jpg,jpeg,png,gif,webp`

#### Automatische Synchronisation:

1. **"Auto-Sync"** aktivieren
2. **Trigger konfigurieren:**
   - ✅ **"WLAN verbunden"** aktivieren
   - ✅ **"Gerät wird geladen"** aktivieren
   - ⚠️ **"Datenvolumen"** DEAKTIVIEREN (nur WLAN!)

3. **Zeitplan (optional):**
   - **"Täglich"** auswählen
   - **Uhrzeit:** z.B. 20:00 Uhr (nach Kita-Schluss)

### Erweiterte Einstellungen

#### Batterie-Optimierung:
1. **"Erweiterte Optionen"**
2. **"Sync nur bei Ladung über X%"** → 20% einstellen
3. **"Sync stoppen bei Batterie unter X%"** → 15% einstellen

#### WLAN-Einstellungen:
1. **"Nur bei bestimmten WLAN-Netzwerken"** aktivieren
2. **Kita-WLAN** auswählen (wichtig für Datenschutz!)

## Mehrere Gruppen einrichten

Für jede Kita-Gruppe ein separates Profil erstellen:

### Profil 1: Käfer-Gruppe
```
Profil-Name: Kita Käfer
Master: DCIM/Camera
Ziel: bilderrahmen.local/käfer
```

### Profil 2: Bienen-Gruppe  
```
Profil-Name: Kita Bienen
Master: DCIM/Camera
Ziel: bilderrahmen.local/bienen
```

### Profil 3: Schmetterlinge-Gruppe
```
Profil-Name: Kita Schmetterlinge  
Master: DCIM/Camera
Ziel: bilderrahmen.local/schmetterlinge
```

## Foto-Sortierung nach Gruppen

### Methode 1: Separate Kamera-Ordner (empfohlen)
1. **Kamera-App** öffnen
2. **Einstellungen** → **Speicherort**
3. **"Benutzerdefiniert"** wählen
4. Ordner erstellen: **DCIM/Käfer**, **DCIM/Bienen**, etc.
5. SMBSync2-Profile entsprechend anpassen

### Methode 2: Manuelle Foto-Auswahl
1. In SMBSync2: **"Datei-Filter"** → **"Erweitert"**
2. **"Geändert in den letzten X Tagen"** → 1 Tag
3. Vor Sync: Fotos manuell in Gruppen-Ordner verschieben

## Überwachung und Wartung

### Sync-Status prüfen:
1. **SMBSync2** öffnen
2. **Profil antippen** → **"Historie"**  
3. **Letzte Synchronisation** und **Fehler** prüfen

### Häufige Probleme:

**"Verbindung fehlgeschlagen"**
- WLAN-Verbindung prüfen
- Server-Adresse korrekt? (`bilderrahmen.local`)
- Benutzername/Passwort korrekt?

**"Keine neuen Dateien"**
- Kamera-Ordner korrekt eingestellt?
- Datei-Filter zu restriktiv?
- Zeitstempel der Fotos prüfen

**"Sync stoppt vorzeitig"**
- Batterie-Einstellungen überprüfen
- WLAN stabil?
- Speicherplatz auf Raspberry Pi?

### Log-Dateien:
- **SMBSync2** → **Einstellungen** → **Log-Dateien**
- Bei Problemen: Log exportieren und an IT-Support senden

## Datenschutz-Einstellungen

### Wichtige Sicherheitsmaßnahmen:
1. **Nur Kita-WLAN** für Sync verwenden
2. **Mobile Daten deaktivieren** für SMBSync2
3. **Automatische Backups** nur im Kita-Netzwerk
4. **Foto-Berechtigung** nur für Kita-relevante Bilder

### DSGVO-Konformität:
- ✅ Fotos bleiben lokal im Kita-Netzwerk
- ✅ Keine Cloud-Übertragung
- ✅ Nur autorisierte Geräte haben Zugriff
- ✅ Einfache Löschung ganzer Monate möglich

## Backup der SMBSync2-Konfiguration

### Konfiguration sichern:
1. **SMBSync2** → **Einstellungen**
2. **"Konfiguration exportieren"**
3. Datei speichern: `SMBSync2_Kita_Backup.json`

### Konfiguration wiederherstellen:
1. **SMBSync2** → **Einstellungen**  
2. **"Konfiguration importieren"**
3. Backup-Datei auswählen

## Empfohlene Android-Einstellungen

### App-Berechtigungen:
- ✅ **Speicher/Dateien:** Vollzugriff
- ✅ **Kamera:** Für Foto-Zugriff
- ✅ **WLAN:** Für Netzwerk-Sync
- ❌ **Standort:** Nicht erforderlich
- ❌ **Mikrofon:** Nicht erforderlich

### Batterie-Optimierung:
1. **Einstellungen** → **Apps** → **SMBSync2**
2. **Batterie** → **"Nicht optimieren"** auswählen
3. **Hintergrund-App-Aktualisierung:** Aktivieren

### Automatische Updates:
- **Google Play Store** → **SMBSync2** 
- **Auto-Update** aktivieren für Sicherheits-Updates

---

**Support:** Bei Problemen Screenshots der Fehlermeldungen erstellen und an die IT-Verwaltung senden.
