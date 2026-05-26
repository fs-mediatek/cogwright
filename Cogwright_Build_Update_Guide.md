# Cogwright — Build & Update-Distribution

## 1. Lokaler Release-Build

### Vorbereitung (einmalig)

Godot Export-Templates installieren:
- Im Godot-Editor: **Editor → Manage Export Templates → Download and Install**
- ODER per Skript: `.\build_release.ps1 -DownloadTemplates` (~700 MB Download)

### Build erzeugen

```powershell
cd c:\KI-Projekte\Godot
.\build_release.ps1
```

Output:
- `game/build/Cogwright.exe` (mit eingebettetem .pck — Single-File-Distribution)
- `release/Cogwright-<version>.zip`
- `release/manifest.json` (für Online-Update-Check)

### Version bumpen

```powershell
.\build_release.ps1 -BumpPatch    # 0.2.0 -> 0.2.1
```

Patch bumpt automatisch [AppVersion.gd:5](game/scripts/core/AppVersion.gd#L5). Für Minor/Major manuell editieren.

### Test auf anderem PC

ZIP entpacken, **Cogwright.exe** doppelklicken. Keine Godot-Installation nötig.

User-Daten (Saves, Settings) liegen auf dem Zielsystem unter:
```
%APPDATA%\Godot\app_userdata\Cogwright\
```

---

## 2. Update-Strategie ohne Steam

Drei Optionen, in Reihenfolge der Empfehlung:

### Option A — **itch.io + butler (empfohlen)**

Standard für Indie-Releases. Spieler installieren einmalig die **itch-App**, danach werden Updates automatisch gezogen.

**Setup:**

1. Account auf https://itch.io → neues Projekt anlegen
2. **butler** herunterladen: https://itch.io/docs/butler/installing.html
3. Einmaliger Login: `butler login`
4. Bei jedem Release:

```powershell
.\build_release.ps1 -BumpPatch
butler push release\Cogwright-0.2.1.zip uebersicht/cogwright:windows --userversion 0.2.1
```

**Vorteile:**
- Auto-Updates für Spieler über itch-App
- Versions-Management eingebaut
- Channels für Beta/Stable
- Kostenlos, optional Pay-What-You-Want oder Festpreis
- Spieler können auch direkt ZIP runterladen (ohne itch-App)

**Nachteil:**
- Spieler braucht itch-App für Auto-Updates (manche Indie-Spieler nutzen sie nicht)

### Option B — **GitHub Releases + In-Game-Check**

Eigene Update-Logik. Cogwright hat bereits einen [UpdateChecker.gd](game/scripts/core/UpdateChecker.gd) eingebaut.

**Setup:**

1. GitHub-Repo erstellen (auch privat ok, aber Release-Asset URL muss public sein)
2. Bei jedem Release:
   - `.\build_release.ps1 -BumpPatch -DownloadUrl "https://github.com/USER/cogwright/releases/download/v0.2.1/Cogwright-0.2.1.zip"`
   - ZIP + `manifest.json` als Release-Assets hochladen
3. `manifest.json` an einer **stabilen URL** verfügbar machen (z.B. GitHub raw):
   - `https://raw.githubusercontent.com/USER/cogwright/main/manifest.json`
4. In [AppVersion.gd:11](game/scripts/core/AppVersion.gd#L11) `UPDATE_MANIFEST_URL` eintragen
5. Game pingt diese URL beim Start, zeigt im Hauptmenü „Update verfügbar: v0.2.1" wenn eine neuere da ist

**Was der Spieler sieht:**
- Hinweis-Text im Hauptmenü mit goldener Farbe
- Klick → öffnet Browser auf die Download-URL (nicht im Spiel selbst — Self-Update einer laufenden Windows-EXE ist heikel ohne Restart)

**Vorteile:**
- Volle Kontrolle, kein Drittanbieter
- Kostenlos
- Funktioniert mit jedem statischen Webhost (Webspace, S3, …)

**Nachteile:**
- Spieler muss manuell neue Version laden + entpacken
- Kein echtes Auto-Update — nur Benachrichtigung
- Wenn du echtes Self-Update willst, brauchst du einen separaten Updater (z.B. ein kleines `Cogwright-Updater.exe` neben dem Spiel)

### Option C — **Eigener Webhost + manueller Download**

Wie B, aber ohne GitHub. ZIP + manifest.json auf eigenen Webspace.

Identisch zu B was Update-Check angeht, du sparst dir nur das GitHub-Repo. Empfehlung: GitHub Releases ist meist einfacher als eigener Hosting-Schmerz.

---

## 3. Empfehlung

Für die nächsten Test-Versionen mit Freunden / kleiner Gruppe: **Option A (itch.io)**. Du erstellst ein „private" oder „restricted" Itch-Projekt, gibst die Test-URL an Tester weiter, und Auto-Updates klappen sofort.

Für Public-Release später: A + B parallel — itch für die Convenience, GitHub für die Power-User die ZIPs direkt laden möchten.

---

## 4. Versions-Schema

| Stufe | Wann bumpen | Beispiel |
|-------|-------------|----------|
| **PATCH** | Bugfix, kleine Polish | 0.2.0 → 0.2.1 |
| **MINOR** | Neue Features, kein Spielsystem-Bruch | 0.2.0 → 0.3.0 |
| **MAJOR** | Saves inkompatibel, große Mechanik-Änderung | 0.x → 1.0.0 |

Aktuell: **v0.2.0** (Expansion-Release mit Kanonenmeister, Perks, Lokomotive, Sandbox).

---

## 5. Update-Check im Code aktivieren

Per Default ist der Check **deaktiviert** (URL leer).

**Aktivieren:**

In [AppVersion.gd:11](game/scripts/core/AppVersion.gd#L11):
```gdscript
const UPDATE_MANIFEST_URL: String = "https://raw.githubusercontent.com/USER/cogwright/main/manifest.json"
```

Beim nächsten Start prüft das Spiel automatisch.

**Manifest-Format:**
```json
{
  "version": "0.2.1",
  "download_url": "https://github.com/USER/cogwright/releases/download/v0.2.1/Cogwright-0.2.1.zip",
  "notes": "Bugfixes und Balance-Updates für Kanonenmeister."
}
```

`build_release.ps1` schreibt dieses Manifest automatisch in `release/manifest.json`.

---

## 6. Stolperfallen

- **Userdata-Migration:** `user://meta_save.cfg` bleibt zwischen Updates erhalten — gut! Aber bei Save-Format-Bruch musst du in [MetaState.gd](game/scripts/core/MetaState.gd) Migrations-Logik schreiben (z.B. Default-Werte für neue Felder bei get_value).
- **Antivirus:** Windows Defender markiert unsignierte EXE manchmal als verdächtig. Lösung: **Code-Signing-Zertifikat** (~50–100 €/Jahr, z.B. SignPath für Open-Source gratis). Optional, aber spart Support-Tickets.
- **DLLs / Abhängigkeiten:** Single-File-Build (`embed_pck=true`) hat KEINE externen Files. Wenn du später Native-Plugins addst (DLLs), müssen die mit ins ZIP.
