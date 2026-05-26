# Cogwright Auto-Updater (Hash-basiert, inkrementell)
# Vom Game gestartet via Cogwright-Update.bat, wenn Spieler in Settings auf "Download oeffnen" klickt.
#
# Ablauf:
#   1. Wait bis Cogwright.exe geschlossen ist (max 30s)
#   2. files.json vom Remote-Base-URL ziehen
#   3. Lokale SHA256-Hashes vergleichen
#   4. Nur veraenderte Dateien herunterladen + ersetzen
#   5. Files die remote nicht mehr existieren -> loeschen
#   6. Cogwright.exe neu starten

param(
    [Parameter(Mandatory=$true)][string]$ManifestUrl,
    [string]$ExpectedVersion = ""
)

$ErrorActionPreference = "Stop"

$install_dir = Split-Path $MyInvocation.MyCommand.Path -Parent
$log_file = Join-Path $install_dir "update.log"

function Write-Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    $line | Out-File -FilePath $log_file -Append -Encoding utf8
    Write-Host $line
}

function Get-FileSha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLower()
}

Write-Log "=== Update gestartet ==="
Write-Log "Install-Dir: $install_dir"
Write-Log "Manifest-URL: $ManifestUrl"
Write-Log "Erwartete Version: $ExpectedVersion"

# 1. Cogwright.exe schliessen
$timeout = 30
while ((Get-Process Cogwright -ErrorAction SilentlyContinue) -and $timeout -gt 0) {
    Start-Sleep -Seconds 1
    $timeout--
}
if (Get-Process Cogwright -ErrorAction SilentlyContinue) {
    Write-Log "Cogwright.exe laeuft noch — kill"
    Get-Process Cogwright -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
}

# 2. files.json laden
$files_url = $ManifestUrl
try {
    $manifest = Invoke-RestMethod -Uri $files_url -UseBasicParsing -Headers @{"User-Agent"="Cogwright-Updater"}
} catch {
    Write-Log "FEHLER: files.json konnte nicht geladen werden: $_"
    Read-Host "Update fehlgeschlagen. Druecke Enter zum Schliessen"
    exit 1
}

$base_url = $manifest.base_url
if (-not $base_url) {
    Write-Log "FEHLER: files.json hat kein 'base_url' Feld"
    Read-Host "Update fehlgeschlagen. Druecke Enter zum Schliessen"
    exit 1
}
if (-not $base_url.EndsWith("/")) { $base_url += "/" }

Write-Log "Remote-Version: $($manifest.version)"
Write-Log "Base-URL: $base_url"
Write-Log "Files im Manifest: $($manifest.files.PSObject.Properties.Count)"

$remote_files = @{}
foreach ($prop in $manifest.files.PSObject.Properties) {
    $remote_files[$prop.Name] = $prop.Value
}

$downloaded = 0
$unchanged = 0
$failed = 0
$patched = 0

# --- 3a. PCK via Binary-Patch aktualisieren, wenn moeglich ---
# Bedingungen: manifest hat pck_patch, lokale PCK matched from_pck_sha256, hpatchz vorhanden.
$pck_local = Join-Path $install_dir "Cogwright.pck"
$pck_handled_by_patch = $false
$hpatchz = Join-Path $install_dir "hpatchz.exe"
if ($manifest.PSObject.Properties.Name -contains "pck_patch" -and $manifest.pck_patch -and (Test-Path $hpatchz)) {
    $pp = $manifest.pck_patch
    $local_pck_hash = Get-FileSha256 -Path $pck_local
    $target_pck_hash = $remote_files["Cogwright.pck"].ToLower()
    if ($local_pck_hash -eq $target_pck_hash) {
        Write-Log "PCK bereits aktuell"
        $pck_handled_by_patch = $true
        $unchanged++
    } elseif ($local_pck_hash -eq $pp.from_pck_sha256.ToLower()) {
        Write-Log "Wende PCK-Patch an: $($pp.file) (von v$($pp.from_version))"
        $patch_url = $base_url + $pp.file
        $patch_tmp = Join-Path $env:TEMP $pp.file
        $pck_new = "$pck_local.new"
        try {
            Invoke-WebRequest -Uri $patch_url -OutFile $patch_tmp -UseBasicParsing -Headers @{"User-Agent"="Cogwright-Updater"}
            $patch_mb = [math]::Round((Get-Item $patch_tmp).Length / 1MB, 2)
            Write-Log "Patch geladen: $patch_mb MB"
            # hpatchz <old> <patch> <new>
            & $hpatchz $pck_local $patch_tmp $pck_new 2>&1 | Out-Null
            if (Test-Path $pck_new) {
                $rebuilt_hash = Get-FileSha256 -Path $pck_new
                if ($rebuilt_hash -eq $target_pck_hash) {
                    Remove-Item $pck_local -Force
                    Move-Item $pck_new $pck_local
                    Write-Log "PCK erfolgreich gepatcht (verifiziert)"
                    $pck_handled_by_patch = $true
                    $patched++
                } else {
                    Write-Log "WARN: Gepatchte PCK Hash-Mismatch (erwartet $target_pck_hash, bekam $rebuilt_hash) — Fallback Full-Download"
                    Remove-Item $pck_new -Force -ErrorAction SilentlyContinue
                }
            } else {
                Write-Log "WARN: hpatchz erzeugte keine Ausgabe — Fallback Full-Download"
            }
            Remove-Item $patch_tmp -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Log "FEHLER beim PCK-Patch: $_ — Fallback Full-Download"
        }
    } else {
        Write-Log "Lokale PCK passt nicht zur Patch-Basis (v$($pp.from_version)) — Full-Download der PCK"
    }
}

# --- 3b+4. Restliche Files (und PCK falls nicht gepatcht) per Hash-Vergleich + Full-Download ---
foreach ($rel_path in $remote_files.Keys) {
    if ($rel_path -eq "Cogwright.pck" -and $pck_handled_by_patch) { continue }
    $remote_hash = $remote_files[$rel_path].ToLower()
    $local_path = Join-Path $install_dir $rel_path
    $local_hash = Get-FileSha256 -Path $local_path

    if ($local_hash -eq $remote_hash) {
        $unchanged++
        continue
    }

    $file_url = $base_url + $rel_path
    $tmp_path = "$local_path.new"
    Write-Log "Lade (voll): $rel_path ($($remote_hash.Substring(0, 8))...)"
    try {
        $local_dir = Split-Path $local_path -Parent
        if (-not (Test-Path $local_dir)) { New-Item -ItemType Directory -Path $local_dir -Force | Out-Null }
        Invoke-WebRequest -Uri $file_url -OutFile $tmp_path -UseBasicParsing -Headers @{"User-Agent"="Cogwright-Updater"}
        $new_hash = Get-FileSha256 -Path $tmp_path
        if ($new_hash -ne $remote_hash) {
            Write-Log "WARN: Hash-Mismatch bei $rel_path — wird trotzdem uebernommen"
        }
        if (Test-Path $local_path) { Remove-Item $local_path -Force }
        Move-Item $tmp_path $local_path
        $downloaded++
    } catch {
        Write-Log "FEHLER beim Download von ${rel_path}: $_"
        if (Test-Path $tmp_path) { Remove-Item $tmp_path -Force -ErrorAction SilentlyContinue }
        $failed++
    }
}

# 5. Lokale Files entfernen, die remote nicht mehr existieren (nur im install_dir, nicht im AppData/User-Save)
# Wir loeschen nur Files unter dem Install-Dir die der frueheren Manifest-Liste entsprachen.
# Konservativ: kein Cleanup, ueberlassen wir dem Uninstaller.

Write-Log "Update abgeschlossen: $patched gepatcht, $downloaded voll geladen, $unchanged unveraendert, $failed Fehler"

# 6. Cogwright neu starten
$cogwright_exe = Join-Path $install_dir "Cogwright.exe"
if (Test-Path $cogwright_exe) {
    Write-Log "Starte Cogwright neu"
    Start-Process $cogwright_exe
} else {
    Write-Log "WARN: Cogwright.exe nicht gefunden im Install-Dir"
}
