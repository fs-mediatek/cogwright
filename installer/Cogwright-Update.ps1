# Cogwright Auto-Updater
# Wird vom Game gestartet (via Cogwright-Update.bat), wenn der Spieler in den
# Einstellungen auf "Update installieren" klickt.
#
# Ablauf:
#   1. Wait bis Cogwright.exe geschlossen ist (max 30s)
#   2. Download ZIP von der uebergebenen URL
#   3. Im Install-Verzeichnis entpacken (ueberschreibt Cogwright.exe)
#   4. Cogwright.exe neu starten
#   5. Sich selbst beenden

param(
    [Parameter(Mandatory=$true)][string]$DownloadUrl,
    [string]$ExpectedVersion = ""
)

$ErrorActionPreference = "Stop"

$install_dir = Split-Path $MyInvocation.MyCommand.Path -Parent
$temp_zip = Join-Path $env:TEMP "Cogwright-Update.zip"
$temp_extract = Join-Path $env:TEMP "Cogwright-Update-Extract"
$log_file = Join-Path $install_dir "update.log"

function Write-Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    $line | Out-File -FilePath $log_file -Append -Encoding utf8
    Write-Host $line
}

Write-Log "=== Update gestartet ==="
Write-Log "Install-Dir: $install_dir"
Write-Log "Download-URL: $DownloadUrl"
Write-Log "Expected Version: $ExpectedVersion"

# 1. Cogwright.exe schliessen (warten max 30s)
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

# 2. Download
Write-Log "Lade ZIP von: $DownloadUrl"
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $temp_zip -UseBasicParsing
    $zip_mb = [math]::Round((Get-Item $temp_zip).Length / 1MB, 1)
    Write-Log "Download fertig: $zip_mb MB"
} catch {
    Write-Log "FEHLER: Download fehlgeschlagen: $_"
    Read-Host "Update fehlgeschlagen. Druecke Enter zum Schliessen"
    exit 1
}

# 3. Extract in Temp
if (Test-Path $temp_extract) { Remove-Item $temp_extract -Recurse -Force }
Write-Log "Entpacke nach: $temp_extract"
try {
    Expand-Archive -Path $temp_zip -DestinationPath $temp_extract -Force
} catch {
    Write-Log "FEHLER: Entpacken fehlgeschlagen: $_"
    Read-Host "Update fehlgeschlagen. Druecke Enter zum Schliessen"
    exit 1
}

# 4. Kopiere ueber Install-Dir (alle Dateien aus dem ZIP)
# WICHTIG: Updater-Files selbst NICHT ueberschreiben (sind nicht im ZIP, sollten aber sicher sein)
Write-Log "Kopiere Files nach: $install_dir"
try {
    Get-ChildItem -Path $temp_extract -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($temp_extract.Length).TrimStart('\')
        $dest = Join-Path $install_dir $rel
        if ($_.PSIsContainer) {
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        } else {
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }
    }
} catch {
    Write-Log "FEHLER: Kopieren fehlgeschlagen: $_"
    Read-Host "Update fehlgeschlagen. Druecke Enter zum Schliessen"
    exit 1
}

# 5. Cleanup
Remove-Item $temp_zip -Force -ErrorAction SilentlyContinue
Remove-Item $temp_extract -Recurse -Force -ErrorAction SilentlyContinue
Write-Log "Update abgeschlossen"

# 6. Cogwright neu starten
$cogwright_exe = Join-Path $install_dir "Cogwright.exe"
if (Test-Path $cogwright_exe) {
    Write-Log "Starte Cogwright neu"
    Start-Process $cogwright_exe
} else {
    Write-Log "WARN: Cogwright.exe nicht gefunden im Install-Dir"
}
